if(EXISTS "${mpv_SOURCE_DIR}/VERSION")
    file(STRINGS "${mpv_SOURCE_DIR}/VERSION" mpv_VERSION)
else()
    if(EXISTS ${mpv_SOURCE_DIR}/snapshot_version)
        file(STRINGS ${mpv_SOURCE_DIR}/snapshot_version git_rev)
    else()
        find_program(GIT NAMES git)
        if(GIT)
            execute_process(
                COMMAND ${GIT} rev-parse --short HEAD
                WORKING_DIRECTORY ${mpv_SOURCE_DIR}
                OUTPUT_VARIABLE git_rev
            )
        else()
            message(WARNING "Git is not installed and there is no snapshot_version file in the source tree; unable to determine mpv version!")
            set(git_rev UNKNOWN)
        endif()
    endif()

    string(STRIP ${git_rev} git_rev)
    set(mpv_VERSION "#define VERSION \"git-${git_rev}\"")
endif()


if(EXISTS ${mpv_BINARY_DIR}/version.h)
    file(READ ${mpv_BINARY_DIR}/version.h old_ver)
    if(${mpv_VERSION} STREQUAL ${old_ver})
        unset(mpv_VERSION)
    endif()
endif()

if(mpv_VERSION)
    file(WRITE ${mpv_BINARY_DIR}/version.h ${mpv_VERSION})
endif()
