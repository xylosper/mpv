# AO/VO ------------------------------------------------------------------------
pkg_check("SDL 2.0" SDL2 sdl2)
set_package_properties("SDL 2.0" PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Simple DirectMedia Layer (cross-platform multimedia library)"
    URL " http://www.libsdl.org "
    PURPOSE "Required for SDL 2.0+ audio/video output support (ao_sdl/vo_sdl)"
)
add_option(CONFIG_SDL2 "SDL 2.0+ video output (vo_sdl)" SDL2_FOUND)
add_pkg(SDL2 CONFIG_SDL2)
add_src(CONFIG_SDL2 video/out/vo_sdl.c)

# AO ---------------------------------------------------------------------------
add_option(HAVE_AUDIO_SELECT "Use select() on the audio device" HAVE_POSIX_SELECT)
mark_as_advanced(HAVE_AUDIO_SELECT)

if(UNIX)
    if(HAVE_LINUX)
        find_package(ALSA)
        set_package_properties(ALSA PROPERTIES
            TYPE RECOMMENDED
            DESCRIPTION "Advanced Linux Sound Architecture"
            URL " http://www.alsa-project.org "
            PURPOSE "Required for ALSA audio output support (ao_alsa)"
        )
        add_option(CONFIG_ALSA "ALSA audio output (ao_alsa)" ALSA_FOUND)
        add_dep(ALSA CONFIG_ALSA)
        add_src(CONFIG_ALSA audio/out/ao_alsa.c)
    endif()

    find_package(OSS)
    set_package_properties(OSS PROPERTIES
        TYPE OPTIONAL
        DESCRIPTION "Open Sound System"
        URL " http://www.opensound.com "
        PURPOSE "Required for OSS audio output support (ao_oss)"
    )
    add_option(CONFIG_OSS_AUDIO "OSS audio output (ao_oss)" OSS_FOUND)
    add_dep(OSS CONFIG_OSS_AUDIO)
    add_src(CONFIG_OSS_AUDIO audio/out/ao_oss.c)

    if(CONFIG_OSS_AUDIO)
        set(CMAKE_REQUIRED_INCLUDES ${OSS_INCLUDE_DIR})
        check_symbol_exists(OPEN_SOUND_SYSTEM soundcard.h REAL_OSS)
        set(CMAKE_REQUIRED_INCLUDES)

        set(PATH_DEV_DSP "/dev/dsp")
        if(NOT REAL_OSS AND (HAVE_NETBSD OR HAVE_OPENBSD))
            set(PATH_DEV_DSP "/dev/sound")
        endif()

        set(PATH_DEV_MIXER "/dev/mixer")
    endif()
endif()

find_package(OpenAL)
set_package_properties(OpenAL PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Cross-platform positional audio API"
    PURPOSE "Required for OpenAL audio output support (ao_openal)"
)
add_option(CONFIG_OPENAL "OpenAL audio output (ao_openal)" OPENAL_FOUND)
add_dep(OpenAL CONFIG_OPENAL)
add_src(CONFIG_OPENAL audio/out/ao_openal.c)

pkg_check(JACK JACK jack)
set_package_properties(JACK PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "System for handling real-time, low latency audio"
    URL " http://jackaudio.org "
    PURPOSE "Required for JACK audio output support (ao_jack)"
)
add_option(CONFIG_JACK "JACK audio output (ao_jack)" JACK_FOUND)
add_pkg(JACK CONFIG_JACK)
add_src(CONFIG_JACK audio/out/ao_jack.c)

pkg_check(PortAudio PORTAUDIO portaudio-2.0>=19)
if(NOT CONFIG_PTHREADS)
    set(PORTAUDIO_FOUND NO)
endif()
set_package_properties(PortAudio PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Cross-platform audio API"
    URL " http://www.portaudio.com "
    PURPOSE "Required for PortAudio audio output support (ao_portaudio)"
)
add_option(CONFIG_PORTAUDIO "PortAudio audio output (ao_portaudio)" PORTAUDIO_FOUND)
add_pkg(PORTAUDIO CONFIG_PORTAUDIO)
add_src(CONFIG_PORTAUDIO audio/out/ao_portaudio.c)

pkg_check(PulseAudio PULSE libpulse>=0.9)
set_package_properties(PulseAudio PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Cross-platform sound server"
    URL " http://pulseaudio.org "
    PURPOSE "Required for PulseAudio audio output support (ao_pulse)"
)
add_option(CONFIG_PULSE "PulseAudio audio output (ao_pulse)" PULSE_FOUND)
add_pkg(PULSE CONFIG_PULSE)
add_src(CONFIG_PULSE audio/out/ao_pulse.c)

pkg_check(RSound RSOUND rsound)
set_package_properties(RSound PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Simple PCM audio server/client"
    URL " https://github.com/Themaister/rsound "
    PURPOSE "Required for RSound audio output support (ao_rsound)"
)
add_option(CONFIG_RSOUND "RSound audio output (ao_rsound)" RSOUND_FOUND)
add_pkg(RSOUND CONFIG_RSOUND)
add_src(CONFIG_RSOUND audio/out/ao_rsound.c)

if(NOT SDL2_FOUND)
    find_package(SDL)
    set_package_properties(SDL PROPERTIES
        TYPE OPTIONAL
        DESCRIPTION "Simple DirectMedia Layer"
        URL " http://www.libsdl.org "
        PURPOSE "Required for SDL 1.2+ audio output support (ao_sdl)"
    )
endif()
if(SDL2_FOUND OR SDL_FOUND)
    set(HAVE_SDL yes)
endif()

add_option(CONFIG_SDL "SDL 1.2+ audio output (ao_sdl)" HAVE_SDL)
if(NOT SDL2_FOUND)
    add_dep(SDL CONFIG_SDL)
endif()
add_src(CONFIG_SDL audio/out/ao_sdl.c)

if(WIN32)
    check_include_files(dsound.h HAVE_DSOUND)
    add_found(DirectSound HAVE_DSOUND)
    set_package_properties(DirectSound PROPERTIES
        TYPE RECOMMENDED
    )
    add_option(CONFIG_DSOUND "DirectSound audio output (ao_dsound)" HAVE_DSOUND)
    add_src(CONFIG_DSOUND audio/out/ao_dsound.c)
endif()

# TODO CoreAudio
add_src(CONFIG_COREAUDIO audio/out/ao_coreaudio.c)

# VO ---------------------------------------------------------------------------
if(UNIX)
    find_package(X11 QUIET)
    add_found(X11 X11_FOUND)
    if(X11_FOUND)
        set(CONFIG_XF86XK 1)
    endif()

    set_package_properties(X11 PROPERTIES
        TYPE RECOMMENDED
    )
    add_option(CONFIG_X11 "X11 video output (vo_x11)" X11_FOUND)
    add_dep(X11 CONFIG_X11)
    add_src(CONFIG_X11 video/out/vo_x11.c)

    add_found(Xv X11_Xv_FOUND)
    set_package_properties(Xv PROPERTIES
        TYPE RECOMMENDED
        DESCRIPTION "X video extension"
        PURPOSE "Required for Xv video output support (vo_xv)"
    )
    add_option(CONFIG_XV "Xv video output (vo_xv)" X11_Xv_FOUND)
    if(CONFIG_XV)
        list(APPEND mpv_LIB ${X11_Xv_LIB})
    endif()
    add_src(CONFIG_XV video/out/vo_xv.c)

    add_found(Xinerama X11_Xinerama_FOUND)
    set_package_properties(Xinerama PROPERTIES
        TYPE RECOMMENDED
        DESCRIPTION "X Xinerama extension"
        PURPOSE "Required for support for multiple viewports"
    )
    add_option(CONFIG_XINERAMA "Xinerama support" X11_Xinerama_FOUND)
    if(CONFIG_XINERAMA)
        list(APPEND mpv_LIB ${X11_Xinerama_LIB})
    endif()

    add_found(XF86VidMode X11_xf86vmode_FOUND)
    set_package_properties(XF86VidMode PROPERTIES
        TYPE RECOMMENDED
        DESCRIPTION "X XF86VidMode extension"
    )
    add_option(CONFIG_XF86VM "XF86VidMode support" X11_xf86vmode_FOUND)
    if(CONFIG_XF86VM)
        list(APPEND mpv_LIB ${X11_Xxf86vm_LIB})
    endif()

    add_found(Xss X11_Xscreensaver_FOUND)
    set_package_properties(Xss PROPERTIES
        TYPE RECOMMENDED
        DESCRIPTION "X Xss screensaver extension"
    )
    add_option(CONFIG_XSS "Screensaver support via Xss" X11_Xscreensaver_FOUND)
    if(CONFIG_XSS)
        list(APPEND mpv_LIB ${X11_Xscreensaver_LIB})
    endif()

    add_found(Xdpms X11_dpms_FOUND)
    set_package_properties(Xdpms PROPERTIES
        TYPE RECOMMENDED
        DESCRIPTION "X Xdpms extension"
    )
    add_option(CONFIG_XDPMS "DPMS support via Xdpms" X11_dpms_FOUND)

    pkg_check(VDPAU VDPAU vdpau>=0.2)
    set_package_properties(VDPAU PROPERTIES
        TYPE RECOMMENDED
        DESCRIPTION "Video Decode and Presentation API for UNIX"
        PURPOSE "Required for VDPAU video output support (vo_vdpau)"
    )
    add_option(CONFIG_VDPAU "VDPAU video output (vo_vdpau)" VDPAU_FOUND)
    add_pkg(VDPAU CONFIG_VDPAU)
    add_src(CONFIG_VDPAU video/out/vo_vdpau.c)
endif()

if(APPLE)
    find_package(CoreVideo)
    add_option(CONFIG_COREVIDEO "CoreVideo video output (vo_corevideo)" COREVIDEO_FOUND)
    add_dep(COREVIDEO CONFIG_COREVIDEO)
    add_src(CONFIG_COREVIDEO video/out/vo_corevideo.c)
endif()

if(WIN32)
    check_include_files(d3d9.h HAVE_D3D9)
    add_found(Direct3D HAVE_D3D9)
    add_option(CONFIG_D3D9 "Direct3D 9 video output (vo_direct3d)" HAVE_D3D9)
    add_src(CONFIG_D3D9 video/out/vo_direct3d.c)
endif()

find_package(OpenGL)
set_package_properties(OpenGL PROPERTIES
    TYPE RECOMMENDED
    DESCRIPTION "Cross-platform graphics API"
    PURPOSE "Required for OpenGL video output support (vo_opengl)"
)
add_option(CONFIG_GL "OpenGL video output (vo_opengl)" OPENGL_FOUND)
add_dep(OPENGL CONFIG_GL)
add_src(CONFIG_GL   video/out/gl_common.c
                    video/out/gl_osd.c
                    video/out/vo_opengl.c
                    video/out/vo_opengl_old.c
                    video/out/pnm_loader.c)

if(APPLE)
    find_package(Cocoa)
    add_dependent_option(CONFIG_GL_COCOA "Cocoa OpenGL backend" COCOA_FOUND "CONFIG_GL")
    add_src(CONFIG_GL_COCOA video/out/osd_common.m video/out/cocoa_common.m)
elseif(WIN32)
    add_dependent_option(CONFIG_GL_WIN32 "Win32 OpenGL backend" ON "CONFIG_GL")
else()
    add_dependent_option(CONFIG_GL_X11 "X11 OpenGL backend" X11_FOUND "CONFIG_GL")
endif()

if(CONFIG_D3D9 OR CONFIG_GL_WIN32)
    add_src(1 video/out/w32_common.c)
endif()
if(CONFIG_X11 OR CONFIG_GL_X11)
    add_src(1 video/out/x11_common.c)
endif()

pkg_check("Little CMS" LCMS2 lcms2)
set_package_properties("Little CMS" PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Color management engine"
    URL " http://www.littlecms.com "
    PURPOSE "Required for color management support in vo_opengl"
)
add_dependent_option(CONFIG_LCMS2
    "vo_opengl color management support"
    LCMS2_FOUND
    "CONFIG_GL"
)
add_pkg(LCMS2 CONFIG_LCMS2)

pkg_check(libcaca CACA caca>=0.99.beta18)
set_package_properties(libcaca PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "Color ASCII-art library"
    URL " http://caca.zoy.org/wiki/libcaca "
    PURPOSE "Required for libcaca video output support (vo_caca)"
)
add_option(CONFIG_CACA "libcaca video output (vo_caca)" CACA_FOUND)
add_pkg(CACA CONFIG_CACA)
add_src(CONFIG_CACA video/out/vo_caca.c)

add_option(CONFIG_ENCODING "Encoding functionality" ON)
add_src(CONFIG_ENCODING video/out/vo_lavc.c
                        audio/out/ao_lavc.c
                        core/encode_lavc.c)
