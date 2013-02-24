# - Find OSS
# Find OSS headers.
#
#  OSS_INCLUDE_DIR          -  Where to find soundcard.h, etc.
#  SOUNDCARD_H_PATH         -  The path of soundcard.h, suitable for #include
#  OSS_FOUND                -  True if OSS found.

FOREACH(INCDIR "" "linux/" "sys/" "machine/")
    SET(OSS_INCLUDE_DIR NOTFOUND)

    FIND_PATH(OSS_INCLUDE_DIR "${INCDIR}soundcard.h"
        "/usr/include" "/usr/local/include/"
    )

    IF(OSS_INCLUDE_DIR)
        SET(SOUNDCARD_H_PATH "${INCDIR}soundcard.h")
        SET(OSS_FOUND 1)
        BREAK()
    ENDIF()
ENDFOREACH()

MARK_AS_ADVANCED (
    OSS_FOUND
    OSS_INCLUDE_DIR
    SOUNDCARD_H_PATH
)
