# KRAL

Build system based on CMake that adds modules and support for mobile platforms

## How KRAL works?

KRAL uses a special config.cmake file to configure targets and based on that it
generates and runs a long CMake command that generates the project. It is
entirely possible to do the same thing without the builder but it is considerably
more cumbersome.

The format of config.cmake is described in config.cmake.md file.

To see all the targets from a config.cmake file you can run the builder script
from the directory that contains the config.cmake file (usually the top-level
directory of the project).

    $ cmake -P KRAL/build.cmake
        USAGE: cmake -D[BUILD_OPTION]=1 -P build.cmake

        BUILD_OPTION = GENERATE | COMPILE | UPDATE | BUILD | LIST
        BUILD_OPTION = You can also use just the first letter [GCUBL]
        -DT=target   = Select a target by name.
        -DN=         = Select a target by number.

        Available targets:
          1. [qt5]          SDLDemo-qt
          2. [osx]          SDLDemo-osx
          3. [web]          SDLDemo-web
          4. [osx]          SDLDemo-osx-lib
          5. [osx]          editor-osx
          6. [ios]          SDLDemo-iossim 

Then I can generate the project for any target in the list:

    $ cmake -DN=1 -DG=1 -P KRAL/build.cmake

And build it by using the IDE or command for the generated project or using the
builders build command for that.

    $ cmake -DN=1 -DB=1 -P KRAL/build.cmake

