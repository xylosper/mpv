# - Try to find libmng
# Once done this will define
#
#  MNG_FOUND - system has libmng
#  MNG_INCLUDE_DIR - the libmng include directory
#  MNG_LIBRARIES - The libmng library

if(MNG_INCLUDE_DIR AND MNG_LIBRARIES)
    set(MNG_FOUND true)
else()
    find_path(MNG_INCLUDE_DIR libmng.h)
    find_library(MNG_LIBRARIES NAMES mng)

    if(MNG_INCLUDE_DIR AND MNG_LIBRARIES)
            set(MNG_FOUND true)
            message(STATUS "Found MNG: ${MNG_LIBRARIES}")
    else()
            set(MNG_FOUND false)
            message(STATUS "Could not find MNG")
    endif()

    mark_as_advanced(MNG_INCLUDE_DIR MNG_LIBRARIES)
endif()
