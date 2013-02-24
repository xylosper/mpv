pkg_check(FFmpeg/libav FFMPEG
    libavutil>=51.23.0
    libavcodec>=53.35.0
    libavformat>=53.21.0
    libswscale>=2.0.0
)
set_package_properties(FFmpeg/libav PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Cross-platform libraries for handling multimedia data"
    URL " http://www.ffmpeg.org / http://libav.org "
    PURPOSE "Required to handle most multimedia formats"
)
add_pkg(FFMPEG 1)

set(CMAKE_EXTRA_INCLUDE_FILES libavcodec/avcodec.h)
set(CMAKE_REQUIRED_LIBRARIES ${FFMPEG_LIBRARIES})
check_library_exists(avcodec avcodec_descriptor_get_by_name "" HAVE_AVCODEC_DESC_API)
check_library_exists(avcodec av_codec_is_decoder "" HAVE_AVCODEC_IS_DECODER_API)
set(CMAKE_REQUIRED_LIBRARIES)
set(CMAKE_EXTRA_INCLUDE_FILES)

find_package(JPEG)
add_option(CONFIG_JPEG "JPEG support" JPEG_FOUND)
add_dep(JPEG CONFIG_JPEG)

find_package(MNG)
add_option(CONFIG_MNG "MNG support" MNG_FOUND)
add_dep(MNG CONFIG_MNG)
add_src(CONFIG_MNG demux/demux_mng.c)

pkg_check(libmpg123 MPG123 libmpg123>=1.2.0)
add_option(CONFIG_MPG123 "libmpg123 MP3 decoding support" MPG123_FOUND)
add_pkg(MPG123 CONFIG_MPG123)
add_src(CONFIG_MPG123 audio/decode/ad_mpg123.c)
