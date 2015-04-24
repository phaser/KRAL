# KRAL Module Structure

Every module has a strict structure. This makes it easy for KRAL functions to
find things and compile them.

    +- Module
        |
        +- Version
            |
            +- CMakeLists.txt
            +- include
            +- source
                |
                +- common
                +- ios
                +- android
                +- win32

Every module can have a version folder. This makes it easy to have multiple
versions of the same library. However you can have only one version and keep
things inside the Module directory.

In the source directory, there is a common directory that holds platform
independent files and then one directory per platform (ios, android, win32 etc).

# KRAL CMakeLists.txt file

#### Top level CMakeLists.txt file

The top level CMakeLists.txt file has some rules you have to follow.

    cmake_minimum_required (VERSION 2.8)
    set (PROJ_NAME "SDLDemo")
    set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${KRAL_PATH})
    project (${PROJ_NAME})
    include (main)

    module(${PROJ_NAME}
            MODULE_TYPE MACOSX_BUNDLE
            DEPENDENCY  SDL2                2.0.0
            DEPENDENCY  glm                 0.9.6.3
    )

First you have to set the CMAKE_MODULE_PATH variable to include the KRAL
directory. This makes it easy to include other CMake files from there.
Then you have to include main.cmake to have access to KRAL functions and
macros. You only need to include this once in your top level CMakeLists.txt
file. All the other files are included by KRAL, so they'll have access to
this as well.

In order to create a new executable you can invoke the module function.
On the ${PROJ_NAME} target you can invoke all other CMake functions lile
[set_target_properties](http://www.cmake.org/cmake/help/v3.0/command/set_target_properties.html).

#### module function parameters

#### library function parameters
