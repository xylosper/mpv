if(APPLE)
    # TODO Apple Remote
    add_src(CONFIG_APPLE_REMOTE core/input/ar.c)
endif()

if(HAVE_LINUX)
    set(CMAKE_EXTRA_INCLUDE_FILES linux/input.h)
    check_type_size("struct input_event" STRUCT_INPUT_EVENT)
    check_type_size("struct input_id" STRUCT_INPUT_ID)
    set(CMAKE_EXTRA_INCLUDE_FILES)

    if(STRUCT_INPUT_EVENT_FOUND AND STRUCT_INPUT_ID_FOUND)
        set(HAVE_APPLE_IR)
    endif()

    add_option(CONFIG_APPLE_IR "Apple IR support" HAVE_APPLE_IR)
    add_src(CONFIG_APPLE_IR core/input/appleir.c)
endif()

if(HAVE_LINUX OR HAVE_FREEBSD)
    add_option(CONFIG_JOYSTICK "Joystick support" ON)
    add_src(CONFIG_JOYSTICK core/input/joystick.c)
endif()

find_package(LircClient)
add_option(CONFIG_LIRC "LIRC support" LircClient_FOUND)
add_dep(LircClient CONFIG_LIRC)
add_src(CONFIG_LIRC core/input/lirc.c)
