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

## KRAL_PATH

This sets the path to KRAL. In the future this will not be necessary. I can modify
build.cmake to set this automatically to be the path of build.cmake. Usually this
is set once per config.cmake, so you can set it in the __DEFAULT target.

## PACKAGE_DIRS

TBD

## PROJECTS_ROOT

TBD

## PLATFORM

TBD

## PROJECT_DIR 

## BUILD_DIR

## PROJECT_TYPE

## BUILD_TYPE

## INHERIT

## CUSTOM_ARGS

## CUSTOM_ARGS_PD

## GEN_CMAKELISTS
