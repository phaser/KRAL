# Config.cmake file description

config.cmake is the file used by build.cmake to configure compile targets. You may have
a project with multiple configurations: for example in a game you build the same codebase
for Android, iOS and Mac OS X, so you build almost the same codebase but with different
toolchains, or working with different IDEs.

The syntax of config.cmake is really simple. You have a function that you can invoke to
configure a target and you can pass various arguments to that function to configure
different aspects of the build. The function is called add_target.

One thing to keep in mind is that there is a special target called __DEFAULT that you 
can define to store common configuration for all target. Common options are KRAL_PATH,
PACKAGE_DIRS and PROJECTS_ROOT. You can inherit later from this target by using the
INHERIT parameter.

    add_target (__DEFAULT
        KRAL_PATH       "${CMAKE_CURRENT_LIST_DIR}/KRAL/" 
        PACKAGE_DIRS    "${CMAKE_CURRENT_LIST_DIR}/packages;${CMAKE_CURRENT_LIST_DIR}/thirdparty"  
        PROJECTS_ROOT   "${CMAKE_CURRENT_LIST_DIR}/projects"
        PLATFORM        osx
        PROJECT_DIR     ${CMAKE_CURRENT_LIST_DIR}/SDLDemo
        BUILD_DIR       SDLDemo
        PROJECT_TYPE    "Unix Makefiles"
        BUILD_TYPE      debug
    )
    
    add_target (SDLDemo-qt
        INHERIT         __DEFAULT
        PLATFORM        qt5
        PROJECT_TYPE    "Unix Makefiles"
        CUSTOM_ARGS     -Wdev
    )

I'm defining first the __DEFAULT target and set the path to KRAL. I'm setting PACKAGE_DIRS
to specify to KRAL where to look for other modules and I'm specifying the PROJECTS_ROOT
folder where all the folders for builds will be created. You can read about the other
parameters in the next section.

After I'm adding the target SDLDemo-qt who inherits from __DEFAULT and then defines
some new properties.

# add_target parameters explained

#### KRAL_PATH

This sets the path to KRAL. In the future this will not be necessary. I can modify
build.cmake to set this automatically to be the path of build.cmake. Usually this
is set once per config.cmake, so you can set it in the __DEFAULT target.

#### PACKAGE_DIRS

With package dirs you can configure multiple paths where KRAL will look for modules
when they are declared as dependencies in calls to *module* or *library* function.

#### PROJECTS_ROOT

When you generate the projects, all are placed in a single location that is defined
by PROJECTS_ROOT.

#### PLATFORM

The platform you build for. This may be misleading, because it isn't refering to the
operating system. Essentially PLATFORM will define what directory from sources will
be compiled. There is a sources/common and then sources/${PLATFORM} that is added to
the compilation. So this can be anything. It is just a convention.

#### PROJECT_DIR 

The folder of the top level module that will be compiled. You specify the top level 
module and that module will declare various dependencies that will be discovered
automatically insidet ${PACKAGE_DIRS} paths.

#### BUILD_DIR

The name of the folder that will be created in PROJECTS_ROOT and where this project
will be compiled.

#### PROJECT_TYPE

This is an alias for CMake generator. You can pass here anything that is acceptable
as CMake generator. To find out what generators are supported on your system invoke
CMakes help and at the end there is the section "Generators".

    cmake --help

#### BUILD_TYPE

Is your build "debug" or "release"?

#### INHERIT

Used to INHERIT all the properties of another target. This imediatly invokes a copy
of all the inherited target properties so it should be specified first if you don't
want other target properties to be overriden.

#### CUSTOM_ARGS

Arguments that are passed to CMake when it gets invoked. All the defines (-D) are
parsed and placed in a file. Sometimes you want properties to be passed directly
and if this is the case please use CUSTOM_ARGS_PD. This behaviour is needed because
the command line parameters can get too long and on Windows you have a limit for
the length of the command.

#### CUSTOM_ARGS_PD

See CUSTOM_ARGS.

#### GEN_CMAKELISTS

There are some IDEs, like CLion or QTCreator, that support CMake directly. For
these a master CMakeLists.txt is generated that can be loaded into those IDEs
as a project. This option can be set to True and will trigger the generation
of the CMakeLists.txt file.

#### COMPILER_ARGS

Project wide compiler arguments.
