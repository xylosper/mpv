add_option(CONFIG_NETWORKING "Networking" HAVE_NETWORKING)
add_src(CONFIG_NETWORKING   stream/asf_mmst_streaming.c
                            stream/asf_streaming.c
                            stream/cookies.c
                            stream/http.c
                            stream/network.c
                            stream/udp.c
                            stream/tcp.c
                            stream/stream_udp.c)

pkg_check(libbluray LIBBLURAY libbluray>=0.2.1)
# libbluray’s .pc file lacks a Libs.private section
# It needs at least libxml2; try to make sure this works with static linking
if(CONFIG_STATIC)
    pkg_check(libxml2 LIBXML2 libxml-2.0)
    if(NOT LIBXML2_FOUND)
        set(LIBBLURAY_FOUND NO)
    endif()
endif()
add_option(CONFIG_LIBBLURAY "Blu-ray support" LIBBLURAY_FOUND)
add_pkg(LIBBLURAY CONFIG_LIBBLURAY)
if(CONFIG_STATIC)
    add_pkg(LIBXML2 CONFIG_LIBBLURAY)
endif()
add_src(CONFIG_LIBBLURAY stream/stream_bluray.c)

pkg_check(libcdio CDIO libcdio_paranoia)
add_option(CONFIG_CDDA "libcdio support" CDIO_FOUND)
add_pkg(CDIO CONFIG_CDDA)
add_src(CONFIG_CDDA stream/stream_cdda.c
                    stream/cdinfo.c)
add_dependent_option(CONFIG_CDDB "CDDB support" CONFIG_CDDA "CONFIG_NETWORKING")
add_src(CONFIG_CDDB stream/stream_cddb.c)

pkg_check(libdvdread DVDREAD libdvdread>=4.2.0)
add_option(CONFIG_DVDREAD "libdvdread support" DVDREAD_FOUND)
add_pkg(DVDREAD CONFIG_DVDREAD)
add_src(CONFIG_DVDREAD  stream/stream_dvd.c
                        stream/stream_dvd_common.c)

pkg_check(libquvi LIBQUVI libquvi>=0.4.1)
# libquvi’s .pc file lacks a Libs.private section
# It needs cURL and Lua; try to make sure this works with static linking
if(CONFIG_STATIC)
    pkg_check(cURL LIBCURL libcurl)
    find_package(Lua51)
    if(NOT LIBCURL_FOUND OR NOT LUA51_FOUND)
        set(LIBQUVI_FOUND NO)
    endif()
endif()
add_dependent_option(CONFIG_LIBQUVI "libquvi support" LIBQUVI_FOUND "CONFIG_NETWORKING")
add_pkg(LIBQUVI CONFIG_LIBQUVI)
if(CONFIG_STATIC)
    add_pkg(LIBCURL CONFIG_LIBQUVI)
    add_dep(LUA CONFIG_LIBQUVI)
endif()
add_src(CONFIG_LIBQUVI core/quvi.c)

pkg_check(libavdevice LIBAVDEVICE libavdevice>=54.0.0)
add_option(CONFIG_LIBAVDEVICE "libavdevice support" LIBAVDEVICE_FOUND)
add_pkg(LIBAVDEVICE CONFIG_LIBAVDEVICE)

if(UNIX AND NOT APPLE)
    add_option(CONFIG_TV "TV interface" ON)
    add_src(CONFIG_TV   stream/stream_tv.c
                        stream/tv.c
                        stream/frequencies.c
                        stream/tvi_dummy.c)

    add_option(CONFIG_RADIO "Radio interface" ON)
    add_src(CONFIG_RADIO stream/stream_radio.c)

    if(CONFIG_ALSA OR CONFIG_OSS_AUDIO)
        set(RADIO_CANCAPTURE 1)
    endif()

    add_dependent_option(
        CONFIG_RADIO_CAPTURE "Capture for Radio interface"
        RADIO_CANCAPTURE "CONFIG_RADIO"
    )

    pkg_check(V4L2 V4L2 libv4l2)
    add_dependent_option(CONFIG_V4L2 "V4L2 support" V4L2_FOUND "CONFIG_PTHREADS")
    check_include_files(linux/videodev2.h HAVE_VIDEODEV2_H)
    check_include_files(sys/videoio.h HAVE_SYS_VIDEOIO_H)
    add_pkg(V4L2 CONFIG_V4L2)

    add_dependent_option(
        CONFIG_TV_V4L2 "V4L2 TV interface"
        HAVE_VIDEODEV2_H "CONFIG_V4L2;CONFIG_TV"
    )
    add_src(CONFIG_TV_V4L2 stream/tvi_v4l2.c)

    add_dependent_option(
        CONFIG_RADIO_V4L2 "V4L2 Radio interface"
        HAVE_VIDEODEV2_H "CONFIG_V4L2;CONFIG_RADIO"
    )

    if(CONFIG_RADIO_CAPTURE OR CONFIG_TV_V4L2)
        add_src(CONFIG_ALSA         stream/ai_alsa1x.c)
        add_src(CONFIG_OSS_AUDIO    stream/ai_oss.c)
        add_src(1                   stream/audio_in.c)
    endif()

    set(CMAKE_EXTRA_INCLUDE_FILES sys/time.h linux/videodev2.h)
    check_type_size("struct v4l2_ext_controls" V4L2_EXT_CONTROLS)
    add_dependent_option(
        CONFIG_PVR "V4L2 MPEG PVR interface"
        HAVE_V4L2_EXT_CONTROLS "CONFIG_V4L2"
    )
    add_src(CONFIG_PVR stream/stream_pvr.c)

    set(CMAKE_EXTRA_INCLUDE_FILES)
endif()

if(HAVE_LINUX)
    check_include_files(
        "linux/dvb/dmx.h;linux/dvb/frontend.h;linux/dvb/video.h;linux/dvb/audio.h"
        DVB_FOUND
    )
    add_option(CONFIG_DVB "Linux DVB support" DVB_FOUND)
    if(CONFIG_DVB)
        set(CONFIG_DVBIN 1)
    endif()
    add_src(CONFIG_DVBIN    stream/dvb_tune.c
                            stream/stream_dvb.c)
endif()

if(WIN32)
    check_include_files(ddk/ntddcdrm.h HAVE_VCD)
else()
    set(HAVE_VCD YES)
endif()
add_option(CONFIG_VCD "VCD support" HAVE_VCD)
add_src(CONFIG_VCD stream/stream_vcd.c)

add_dependent_option(CONFIG_FTP "FTP support" ON "CONFIG_NETWORKING")
add_src(CONFIG_FTP stream/stream_ftp.c)

set(CMAKE_REQUIRED_LIBRARIES ${mpv_LIB})
set(CMAKE_EXTRA_INCLUDE_FILES libsmbclient.h)
check_library_exists(smbclient smbc_opendir "" HAVE_SMBCLIENT)
set(CMAKE_EXTRA_INCLUDE_FILES)
set(CMAKE_REQUIRED_LIBRARIES)
add_found(libsmbclient HAVE_SMBCLIENT)
set_package_properties(libsmbclient PROPERTIES
    TYPE OPTIONAL
    DESCRIPTION "CIFS/SMB client library"
    PURPOSE "Required for smb:// URL support"
)
add_dependent_option(
    CONFIG_LIBSMBCLIENT "CIFS/SMB support"
    HAVE_SMBCLIENT "CONFIG_NETWORKING"
)
if(CONFIG_LIBSMBCLIENT)
    list(APPEND mpv_LIB smbclient)
endif()
add_src(CONFIG_LIBSMBCLIENT stream/stream_smb.c)

set(CMAKE_EXTRA_INCLUDE_FILES vstream-client.h)
check_library_exists(vstream-client vstream_start "" HAVE_VSTREAM)
set(CMAKE_EXTRA_INCLUDE_FILES)
add_found(vstream-client HAVE_VSTREAM)
add_dependent_option(
    CONFIG_VSTREAM
    "Tivo VServer Streaming Client support"
    HAVE_VSTREAM
    "CONFIG_NETWORKING"
)
if(CONFIG_VSTREAM)
    list(APPEND mpv_LIB vstream-client)
endif()
add_src(CONFIG_VSTREAM stream/stream_vstream.c)
