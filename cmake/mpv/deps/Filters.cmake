pkg_check(libbs2b LIBBS2B libbs2b)
add_option(CONFIG_LIBBS2B "libbs2b filter support" LIBBS2B_FOUND)
add_pkg(LIBBS2B CONFIG_LIBBS2B)
add_src(CONFIG_LIBBS2B audio/filter/af_bs2b.c)

pkg_check(libpostproc LIBPOSTPROC libpostproc>=52.0.0)
add_option(CONFIG_LIBPOSTPROC "libpostproc support" LIBPOSTPROC_FOUND)
add_pkg(LIBPOSTPROC CONFIG_LIBPOSTPROC)
add_src(CONFIG_LIBPOSTPROC video/filter/vf_pp.c)

find_package(LADSPA)
add_option(CONFIG_LADSPA "LADSPA filter support" LADSPA_FOUND)
add_dep(LADSPA CONFIG_LADSPA)
add_src(CONFIG_LADSPA audio/filter/af_ladspa.c)
