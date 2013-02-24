if (CONFIG_MAN)
    file(MAKE_DIRECTORY ${mpv_BINARY_DIR}/DOCS/man/en)
    add_custom_command(
        OUTPUT ${mpv_BINARY_DIR}/DOCS/man/en/mpv.1
        COMMAND ${RST2MAN}
        ARGS ${mpv_SOURCE_DIR}/DOCS/man/en/mpv.rst ${mpv_BINARY_DIR}/DOCS/man/en/mpv.1
    )

    add_custom_target(Manpage ALL echo DEPENDS ${mpv_BINARY_DIR}/DOCS/man/en/mpv.1)
    install(FILES ${mpv_BINARY_DIR}/DOCS/man/en/mpv.1 DESTINATION ${CMAKE_INSTALL_FULL_MANDIR}/man1)
endif()

file(MAKE_DIRECTORY ${mpv_BINARY_DIR}/core/input)
add_custom_command(
    OUTPUT ${mpv_BINARY_DIR}/core/input/input_conf.h
    COMMAND ${PERL_EXECUTABLE} ${mpv_SOURCE_DIR}/TOOLS/file2string.pl ${mpv_SOURCE_DIR}/etc/input.conf > ${mpv_BINARY_DIR}/core/input/input_conf.h
)
add_custom_target(input_conf ALL echo DEPENDS ${mpv_BINARY_DIR}/core/input/input_conf.h)

file(MAKE_DIRECTORY ${mpv_BINARY_DIR}/video/out)
add_custom_command(
    OUTPUT ${mpv_BINARY_DIR}/video/out/vdpau_template.c
    COMMAND ${PERL_EXECUTABLE} ${mpv_SOURCE_DIR}/TOOLS/vdpau_functions.pl > ${mpv_BINARY_DIR}/video/out/vdpau_template.c
)
add_custom_target(vdpau_template ALL echo DEPENDS ${mpv_BINARY_DIR}/video/out/vdpau_template.c)
add_custom_command(
    OUTPUT ${mpv_BINARY_DIR}/video/out/vo_opengl_shaders.h
    COMMAND ${PERL_EXECUTABLE} ${mpv_SOURCE_DIR}/TOOLS/file2string.pl ${mpv_SOURCE_DIR}/video/out/vo_opengl_shaders.glsl > ${mpv_BINARY_DIR}/video/out/vo_opengl_shaders.h
)
add_custom_target(vo_opengl_shaders ALL echo DEPENDS ${mpv_BINARY_DIR}/video/out/vo_opengl_shaders.h)

file(MAKE_DIRECTORY ${mpv_BINARY_DIR}/demux)
add_custom_command(
    OUTPUT ${mpv_BINARY_DIR}/demux/ebml_types.h
    COMMAND ${PERL_EXECUTABLE} ${mpv_SOURCE_DIR}/TOOLS/matroska.pl --generate-header > ${mpv_BINARY_DIR}/demux/ebml_types.h
)
add_custom_command(
    OUTPUT ${mpv_BINARY_DIR}/demux/ebml_defs.c
    COMMAND ${PERL_EXECUTABLE} ${mpv_SOURCE_DIR}/TOOLS/matroska.pl --generate-definitions > ${mpv_BINARY_DIR}/demux/ebml_defs.c
)
add_custom_target(ebml ALL echo DEPENDS ${mpv_BINARY_DIR}/demux/ebml_types.h ${mpv_BINARY_DIR}/demux/ebml_defs.c)

file(MAKE_DIRECTORY ${mpv_BINARY_DIR}/sub)
add_custom_command(
    OUTPUT ${mpv_BINARY_DIR}/sub/osd_font.h
    COMMAND ${PERL_EXECUTABLE} ${mpv_SOURCE_DIR}/TOOLS/file2string.pl ${mpv_SOURCE_DIR}/sub/osd_font.pfb > ${mpv_BINARY_DIR}/sub/osd_font.h
)
add_custom_target(osd_font ALL echo DEPENDS ${mpv_BINARY_DIR}/sub/osd_font.h)

add_dependencies(mpv input.conf vo_opengl_shaders vdpau_template ebml osd_font)
