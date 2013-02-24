cmake_minimum_required(VERSION 2.8 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(FindPkgConfig)
include(FeatureSummary)
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckTypeSize)
include(CMakeDependentOption)
include(GNUInstallDirs)

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

project(mpv)
include(mpv/Utils)
include(mpv/Version)
include(mpv/CompilerInfo)
include(mpv/OsDep)
include(mpv/PlatformChecks)

include(mpv/deps/Input)
include(mpv/deps/Support)
include(mpv/deps/Output)
include(mpv/deps/Streams)
include(mpv/deps/Codecs)
include(mpv/deps/Filters)

feature_summary(
    DESCRIPTION "The following REQUIRED packages have been found:"
    WHAT REQUIRED_PACKAGES_FOUND FATAL_ON_MISSING_REQUIRED_PACKAGES
)
feature_summary(
    DESCRIPTION "The following REQUIRED packages have NOT been found:"
    WHAT REQUIRED_PACKAGES_NOT_FOUND FATAL_ON_MISSING_REQUIRED_PACKAGES
)
feature_summary(
    DESCRIPTION "The following RECOMMENDED packages have been found:"
    WHAT RECOMMENDED_PACKAGES_FOUND
)
feature_summary(
    DESCRIPTION "The following RECOMMENDED packages have NOT been found:"
    WHAT RECOMMENDED_PACKAGES_NOT_FOUND
)
feature_summary(
    DESCRIPTION "The following OPTIONAL packages have been found:"
    WHAT OPTIONAL_PACKAGES_FOUND
)
feature_summary(
    DESCRIPTION "The following OPTIONAL packages have NOT been found:"
    WHAT OPTIONAL_PACKAGES_NOT_FOUND
)
feature_summary(
    DESCRIPTION "Enabled features:"
    WHAT ENABLED_FEATURES
)
feature_summary(
    DESCRIPTION "Disabled features:"
    WHAT DISABLED_FEATURES
)

configure_file(config.h.in config.h)

list(APPEND mpv_INC
    ${mpv_SOURCE_DIR}
    ${mpv_BINARY_DIR}
)

list(APPEND mpv_SRC
    talloc.c
    audio/decode/ad.c
    audio/decode/ad_lavc.c
    audio/decode/ad_spdif.c
    audio/decode/dec_audio.c
    audio/filter/af.c
    audio/filter/af_center.c
    audio/filter/af_channels.c
    audio/filter/af_delay.c
    audio/filter/af_drc.c
    audio/filter/af_dummy.c
    audio/filter/af_equalizer.c
    audio/filter/af_extrastereo.c
    audio/filter/af_format.c
    audio/filter/af_hrtf.c
    audio/filter/af_karaoke.c
    audio/filter/af_lavcac3enc.c
    audio/filter/af_lavcresample.c
    audio/filter/af_pan.c
    audio/filter/af_resample.c
    audio/filter/af_scaletempo.c
    audio/filter/af_sinesuppress.c
    audio/filter/af_sub.c
    audio/filter/af_surround.c
    audio/filter/af_sweep.c
    audio/filter/af_tools.c
    audio/filter/af_volume.c
    audio/filter/filter.c
    audio/filter/window.c
    audio/format.c
    audio/mixer.c
    audio/out/ao.c
    audio/out/ao_null.c
    audio/out/ao_pcm.c
    audio/reorder_ch.c
    core/asxparser.c
    core/av_common.c
    core/av_log.c
    core/av_opts.c
    core/bstr.c
    core/codecs.c
    core/command.c
    core/cpudetect.c
    core/defaultopts.c
    core/input/input.c
    core/m_config.c
    core/m_option.c
    core/m_property.c
    core/m_struct.c
    core/mp_common.c
    core/mp_fifo.c
    core/mp_msg.c
    core/mplayer.c
    core/parser-cfg.c
    core/parser-mpcmd.c
    core/path.c
    core/playlist.c
    core/playlist_parser.c
    core/screenshot.c
    core/subopt-helper.c
    core/timeline/tl_cue.c
    core/timeline/tl_edl.c
    core/timeline/tl_matroska.c
    core/version.c
    demux/asfheader.c
    demux/aviheader.c
    demux/aviprint.c
    demux/codec_tags.c
    demux/demux.c
    demux/demux_asf.c
    demux/demux_avi.c
    demux/demux_cue.c
    demux/demux_edl.c
    demux/demux_lavf.c
    demux/demux_mf.c
    demux/demux_mkv.c
    demux/demux_mpg.c
    demux/demux_rawaudio.c
    demux/demux_rawvideo.c
    demux/demux_ts.c
    demux/ebml.c
    demux/extension.c
    demux/mf.c
    demux/mp3_hdr.c
    demux/mpeg_hdr.c
    demux/parse_es.c
    demux/video.c
    osdep/${GETCH}
    osdep/${TIMER}
    osdep/io.c
    osdep/numcores.c
    stream/stream.c
    stream/stream_avdevice.c
    stream/stream_file.c
    stream/stream_lavf.c
    stream/stream_mf.c
    stream/stream_null.c
    stream/url.c
    sub/dec_sub.c
    sub/draw_bmp.c
    sub/find_sub.c
    sub/find_subfiles.c
    sub/img_convert.c
    sub/sd_lavc.c
    sub/spudec.c
    sub/sub.c
    sub/subassconvert.c
    sub/subreader.c
    video/csputils.c
    video/decode/dec_video.c
    video/decode/lavc_dr1.c
    video/decode/vd.c
    video/decode/vd_lavc.c
    video/filter/pullup.c
    video/filter/vf.c
    video/filter/vf_crop.c
    video/filter/vf_delogo.c
    video/filter/vf_divtc.c
    video/filter/vf_dlopen.c
    video/filter/vf_down3dright.c
    video/filter/vf_dsize.c
    video/filter/vf_eq.c
    video/filter/vf_expand.c
    video/filter/vf_flip.c
    video/filter/vf_format.c
    video/filter/vf_gradfun.c
    video/filter/vf_hqdn3d.c
    video/filter/vf_ilpack.c
    video/filter/vf_mirror.c
    video/filter/vf_noformat.c
    video/filter/vf_noise.c
    video/filter/vf_phase.c
    video/filter/vf_pullup.c
    video/filter/vf_rotate.c
    video/filter/vf_scale.c
    video/filter/vf_screenshot.c
    video/filter/vf_softpulldown.c
    video/filter/vf_stereo3d.c
    video/filter/vf_sub.c
    video/filter/vf_swapuv.c
    video/filter/vf_unsharp.c
    video/filter/vf_vo.c
    video/filter/vf_yadif.c
    video/fmt-conversion.c
    video/image_writer.c
    video/img_format.c
    video/mp_image.c
    video/mp_image_pool.c
    video/out/aspect.c
    video/out/bitmap_packer.c
    video/out/filter_kernels.c
    video/out/vo.c
    video/out/vo_image.c
    video/out/vo_null.c
    video/sws_utils.c
)

if(NOT HAVE_OSD)
    add_src(1 sub/osd_dummy.c)
endif()

add_executable(mpv ${mpv_SRC})
target_link_libraries(mpv ${mpv_LIB})
set_target_properties(mpv PROPERTIES INCLUDE_DIRECTORIES "${mpv_INC}")
if(CONFIG_STATIC)
    set_target_properties(mpv PROPERTIES LINK_SEARCH_END_STATIC ON LINK_FLAGS -static)
endif()
install(TARGETS mpv RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

include(mpv/PreprocessFiles)

configure_file(
    "${mpv_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${mpv_BINARY_DIR}/cmake/cmake_uninstall.cmake"
    IMMEDIATE @ONLY
)
add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${mpv_BINARY_DIR}/cmake/cmake_uninstall.cmake
)
