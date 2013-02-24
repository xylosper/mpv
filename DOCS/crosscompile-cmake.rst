Cross compiling with CMake
==========================

Cross compiling mpv with CMake is relatively straightforward.
All you need to do is set a few variables that tell CMake about your cross
toolchain. The recommended way to do this is by using a toolchain file.
This toolchain file looks like a regular CMake script and usually only sets
these variables.

It could look like this:

::

    SET(CMAKE_SYSTEM_NAME Windows)
    SET(CMAKE_SYSTEM_PROCESSOR x86_64)

    SET(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
    SET(CMAKE_RC_COMPILER_INIT x86_64-w64-mingw32-windres)

    SET(CMAKE_SYSTEM_PROGRAM_PATH /home/example/mingw-prefix-64/bin)
    SET(CMAKE_FIND_ROOT_PATH /home/example/mingw-prefix-64/mingw)

    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

And here’s a quick explanation of what these variables do:

``CMAKE_SYSTEM_NAME``
    Sets the target system name, e.g. “Windows”, “Linux”, “Darwin”, …

``CMAKE_SYSTEM_PROCESSOR``
    Sets the target processor architecture, e.g. “i386”, “x86_64”, “ia64”, …

``CMAKE_C_COMPILER``, ``CMAKE_RC_COMPILER_INIT``
    Sets the C and resource compiler executables, respectively.
    You can also use the ``CC`` environment variable for this.

``CMAKE_SYSTEM_PROGRAM_PATH``
    Specifies a path which CMake will use for finding programs.

``CMAKE_FIND_ROOT_PATH``
    Specifies the root path of your target environment, i.e. where to look for
    build-time dependencies such as libraries.

``CMAKE_FIND_ROOT_PATH_MODE_PROGRAM``, ``CMAKE_FIND_ROOT_PATH_MODE_LIBRARY``, ``CMAKE_FIND_ROOT_PATH_MODE_INCLUDE``
    Sets CMake’s behavior when finding programs, libraries and include paths,
    respectively.

    ``NEVER`` means it will not look in ``CMAKE_FIND_ROOT_PATH``, ``ONLY`` means
    it will not look anywhere else, ``BOTH`` means it will will first look there
    and then elsewhere.

Once you have your toolchain file (let’s call it ``toolchain.cmake``), you can
use it by calling cmake with ``-DCMAKE_TOOLCHAIN_FILE=toolchain.cmake``.

Depending on your target environment, you might also want to add
``-DCONFIG_STATIC=1`` to your CMake command line to enable static linking.
