use strict;
use warnings;
use Time::HiRes;
use IPC::Open3;

sub CPUINFO { `cat /proc/cpuinfo`; }
my $CPUINFO_ATTEMPTS = 4;
my $CPUINFO_WAIT = 30;
my $OUT_FILE = "bench.tsv";
my $CMDLINE = "../mpv -no-audio -no-vsync -untimed -end 10 bench.mp4";
my $CMDLINE_ERROR_PATTERN = qr/Video: no video/;
my $RUNS = 5;
my $RETRIES = 5;
my @COMBINATIONS = (
    [Fullscreen =>
        "--no-fs",
        (`xdpyinfo` =~ /^  dimensions:\s+(\d+x\d+)/m
            ? "--fs --geometry=$1" : "--fs"),
    ],
    [VO =>
        "--vo=direct3d_shaders",
        "--vo=direct3d",
        "--vo=corevideo",
        "--vo=vdpau",
        "--vo=vdpau:fps=-1",
        "--vo=xv",
        "--vo=opengl:sw",
        "--vo=opengl-old:sw:yuv=0:swapinterval=0",
        "--vo=opengl-old:sw:yuv=2:swapinterval=0",
        ["--vo=sdl",
            {SDL_RENDER_DRIVER => "opengl", SDL_RENDER_OPENGL_SHADERS => 1}],
        ["--vo=sdl",
            {SDL_RENDER_DRIVER => "opengl", SDL_RENDER_OPENGL_SHADERS => 0}],
        ["--vo=sdl", {SDL_RENDER_DRIVER => "software"}],
        "--vo=x11",
        "--vo=caca",
        "--vo=opengl-hq:sw",
        "--vo=null",
    ],
    [OSD =>
        "--osd-level=0",
        "--osd-level=3",
        "--osd-level=3 --osd-font-size=320",
    ],
#   [ass2rgba =>
#       "--no-force-rgba-osd-rendering",
#       "--force-rgba-osd-rendering",
#   ],
);

open my $outfh, ">", $OUT_FILE
    or die "open $OUT_FILE: $!";

my $cpuinfo_str = undef;
sub wait_cpuinfo() {
    my $cpuinfo = CPUINFO();
    if (!defined $cpuinfo_str) {
        print STDERR "Got cpuinfo:\n$cpuinfo\n";
        # first run - just take what we get
        $cpuinfo_str = $cpuinfo;
        return 1;
    }
    return 1
        if $cpuinfo eq $cpuinfo_str;
    for (2..$CPUINFO_ATTEMPTS) {
        print STDERR "Got cpuinfo:\n$cpuinfo\n";
        print STDERR "Waiting for CPU to calm down...\n";
        sleep $CPUINFO_WAIT;
        my $cpuinfo = CPUINFO();
        return 0
            if $cpuinfo eq $cpuinfo_str;
    }
}

sub run($$) {
    my ($cmdline, $env) = @_;
    for (keys %$env) {
        $ENV{$_} = $env->{$_};
    }
    # wait for CPU to have the right state
    wait_cpuinfo();
    print STDERR "Running $cmdline... ";
    my $t0 = Time::HiRes::time();
    my $pid = IPC::Open3::open3 \*STDIN, my $cmdfh, undef, $cmdline;
    my $str = do {
        undef local $/;
        <$cmdfh>;
    };
    close $cmdfh;
    waitpid $pid, 0;
    my $ret = $?;
    my $t1 = Time::HiRes::time();
    for (keys %$env) {
        delete $ENV{$_};
    }
    if (($ret & 127) == 2) {
        print STDERR "failed due to SIGINT, bailing out\n";
        exit;
    }
    if (!wait_cpuinfo()) {
        print STDERR "failed due to CPU frequency change\n";
        return undef;
    }
    if ($ret != 0 || $str =~ $CMDLINE_ERROR_PATTERN) {
        print STDERR "failed due to non-zero exit code\n";
        return undef;
    }
    my $dt = $t1 - $t0;
    print STDERR "$dt\n";
    return $t1 - $t0;
}

my %choices_working = ();
my %choice_results = ();
my @totals = ();

sub decode_choice($) {
    my ($x) = @_;
    if (ref $x) {
        my $c = $x->[0];
        my $e = $x->[1];
        my $str = $c . " " .
                  join " ", map { "$_=$e->{$_}" } sort keys %$e;
        return $str, $c, $e;
    } else {
        return $x, $x, {};
    }
}

my $is_first = 1;
sub output($$) {
    my ($choices, $time) = @_;

    # TSV header
    if ($is_first) {
        $is_first = 0;
        for (@$choices) {
            print $outfh "$_->[0]\t";
        }
        print $outfh "Time\n";
    }

    # TSV line
    for (@$choices) {
        print $outfh "$_->[1]\t";
    }
    if (defined $time) {
        print $outfh "$time\n";
    } else {
        print $outfh "FAILED\n";
    }

    # record results
    my $start = \%choice_results;
    my $ptr = \$start;
    for (@$choices) {
        my $key = $_->[0];
        my ($str, undef) = decode_choice $_->[1];
        $choices_working{$key}{$str} = 1
            if defined $time;
        $$ptr ||= {};
        $ptr = \($$ptr->{$str});
    }
    push @$$ptr, $time;
}

sub collect_total($$$$);
sub collect_total($$$$) {
    my ($item, $ptr, $searchkey, $searchvalue) = @_;
    my $list = $COMBINATIONS[$item];
    if ($list) {
        my ($key, @values) = @$list;
        my @found = ();
        for (@values) {
            my ($str, undef) = decode_choice $_;
            if (defined $searchkey and $searchkey eq $key) {
                if ($str ne $searchvalue) {
                    next;
                }
            }
            next
                unless $choices_working{$key}{$str};
            push @found, collect_total($item + 1,
                $ptr->{$str}, $searchkey, $searchvalue);
        }
        return @found;
    } else {
        return @$ptr;
    }
}

sub get_total(@) {
    return undef
        unless @_;
    my $sum = 0;
    for(@_) {
        return undef
            if not defined $_;
        $sum += $_;
    }
    return $sum / @_;
}

sub output_totals() {
    for my $key(sort keys %choices_working) {
        for my $value(sort keys %{$choices_working{$key}}) {
            my @l = collect_total 0, \%choice_results, $key, $value;
            my $avg = get_total @l;
            my $avg_str = defined($avg) ? sprintf("%.6f", $avg) : "FAILED";
            printf "%10s: %10s for %s\n", $key, $avg_str, $value;
        }
    }
    my @totals = collect_total 0, \%choice_results, undef, undef;
    my $avg = get_total @totals;
    my $avg_str = defined($avg) ? sprintf("%.6f", $avg) : "FAILED";
    printf "%10s: %10s\n", "AVERAGE", $avg_str;
}

sub recurse($$$$);
sub recurse($$$$) {
    my ($item, $choices, $cmdline, $env) = @_;
    my $list = $COMBINATIONS[$item];
    if ($list) {
        my ($key, @values) = @$list;
        for (@values) {
            my ($str, $c, $e) = decode_choice $_;
            recurse $item + 1,
                [@$choices, [$key => $str]],
                "$cmdline $c",
                {%$env, %$e};
        }
    } else {
        # do a run!
        my @times = ();
        my $retries = 0;
        for (1..$RUNS) {
            my $dt = run $cmdline, $env;
            if (!defined $dt) {
                redo
                    if $retries++ <= $RETRIES;
                output $choices, undef;
                return;
            }
            push @times, $dt;
        }
        output $choices, [sort @times]->[int((@times - 1) / 2)];
        return;
    }
}

recurse(0, [], $CMDLINE, {});
output_totals();
