find_package(Perl 5.8 REQUIRED)
find_package(Iconv REQUIRED)
if(ICONV_FOUND)
    set(CONFIG_ICONV 1)
    add_dep(ICONV CONFIG_ICONV)
endif()

find_program(RST2MAN NAMES rst2man rst2man.py)
add_found(rst2man RST2MAN)
set_package_properties(rst2man PROPERTIES
    TYPE RECOMMENDED
    DESCRIPTION "Generate UNIX manpages from reStructuredText"
    URL " http://docutils.sourceforge.net "
    PURPOSE "Used to generate manpages"
)
add_option(CONFIG_MAN "Manpage" RST2MAN)

find_package(Gettext)
set_package_properties(Gettext PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Internationalization and localization system"
    URL " http://www.gnu.org/software/gettext/ "
    PURPOSE "Required for i18n support"
)
add_option(CONFIG_GETTEXT "i18n support" Gettext_FOUND)
add_dep(Gettext CONFIG_GETTEXT)

set(CMAKE_THREAD_PREFER_PTHREAD yes)
find_package(Threads QUIET)
add_found("POSIX Threads" CMAKE_HAVE_THREADS_LIBRARY)
add_option(CONFIG_PTHREADS "POSIX Threads" CMAKE_HAVE_THREADS_LIBRARY)
if(CONFIG_PTHREADS)
    set(HAVE_PTHREADS 1)
    set(HAVE_THREADS 1)
    list(APPEND mpv_LIB ${CMAKE_THREAD_LIBS_INIT})
endif()

set(CONFIG_STREAM_CACHE 1)
if(CYGWIN AND NOT CONFIG_PTHREADS)
    unset(CONFIG_STREAM_CACHE)
endif()
add_src(CONFIG_STREAM_CACHE stream/cache2.c)

find_package(ZLIB)
add_option(CONFIG_ZLIB "zlib support" ZLIB_FOUND)
add_dep(ZLIB CONFIG_ZLIB)

pkg_check(libass ASS libass>=0.10.0)
set_package_properties(libass PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Portable subtitle renderer"
    URL "http://code.google.com/p/libass/"
    PURPOSE "Used for subtitle and OSD rendering"
)
set(CONFIG_ASS 1)
add_src(CONFIG_ASS      sub/ass_mp.c sub/sd_ass.c)
add_pkg(ASS CONFIG_ASS)

add_option(CONFIG_ASS_OSD "libass OSD support" ON)
add_src(CONFIG_ASS_OSD  sub/osd_libass.c)
if(CONFIG_ASS_OSD)
    set(HAVE_OSD 1)
endif()

pkg_check(Enca ENCA enca)
add_option(CONFIG_ENCA "Enca support" ENCA_FOUND)
add_pkg(ENCA CONFIG_ENCA)
