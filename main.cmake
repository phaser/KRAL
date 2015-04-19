# The project is licensed under GNU GPL v3. See $(PROJECT_ROOT)/docs/gpl-3.0.txt for more details.
#
# KRAL
# Copyright (C) 2015 Cristian Bidea
cmake_minimum_required (VERSION 3.0)

include (config)
include (util)

set (SOURCES_EXTENSIONS "*.c;*.cc;*.cpp;*.cxx;*.m;*.mm;*.ui;*.h")
set (INCLUDE_EXTENSIONS "*.h;*.hpp")

function (module PNAME)
    set (GLOBAL_TAB "")
    message(STATUS "Build module: ${PNAME}")
    set (value 1)
    set (BUILD_OPTION "")
    while (value LESS ${ARGC})
        if ("${ARGV${value}}" STREQUAL "DEPENDENCY")
            math (EXPR value "${value} + 1")
            set (DEP_NAME "${ARGV${value}}")	
            math (EXPR value "${value} + 1")
            set (DEP_VER "${ARGV${value}}")	
            list (APPEND ${PNAME}_DEPS "${DEP_NAME}/${DEP_VER}") 
        elseif ("${ARGV${value}}" STREQUAL "MODULE_TYPE")
            math (EXPR value "${value} + 1")
            set (BUILD_OPTION "${BUILD_OPTION} ${ARGV${value}}")	
        endif()
        math (EXPR value "${value} + 1")
    endwhile()

    list_files(${PNAME})
	add_executable (${PNAME} ${BUILD_OPTION} ${${PNAME}_F_INCLUDE} ${${PNAME}_F_SOURCES} ${${PNAME}_plaf_F_SOURCES})
    set_module_includes(${PNAME})
    build_dependencies(${PNAME})
endfunction()

function (library PNAME)
    set (value 1)
    while (value LESS ${ARGC})
        if ("${ARGV${value}}" STREQUAL "DEPENDENCY")
            math (EXPR value "${value} + 1")
            set (DEP_NAME "${ARGV${value}}")	
            math (EXPR value "${value} + 1")
            set (DEP_VER "${ARGV${value}}")	
            list (APPEND ${PNAME}_DEPS "${DEP_NAME}/${DEP_VER}") 
        elseif ("${ARGV${value}}" STREQUAL "MODULE_TYPE")
            math (EXPR value "${value} + 1")
            set (BUILD_OPTION "${BUILD_OPTION} ${ARGV${value}}")	
        endif()
        math (EXPR value "${value} + 1")
    endwhile()
    
    list_files(${PNAME})
    add_library (${PNAME} ${BUILD_OPTION} ${${PNAME}_F_INCLUDE} ${${PNAME}_F_SOURCES} ${${PNAME}_plaf_F_SOURCES})
    set_module_includes(${PNAME})
    build_dependencies(${PNAME})
endfunction()

# export a framework to be used by those who add this
# package as a dependency
macro (export_ios_framework)
    set (LIF_NAME ${ARGV0})
    message (STATUS "${GLOBAL_TAB}export_ios_framework ${LIF_NAME}")
    list (APPEND EXPORTED_IOS_FRAMEWORKS "${LIF_NAME};${ARGV1}")    
    set (EXPORTED_IOS_FRAMEWORKS "${EXPORTED_IOS_FRAMEWORKS}" PARENT_SCOPE)
endmacro()

# Used to find and link an IOS framework
macro(link_ios_framework)
    set(LIF_PROJ_NAME ${ARGV0})
    set(LIF_NAME ${ARGV1})
    find_library (FRAMEWORK_${LIF_NAME}
                  NAMES ${LIF_NAME}
                  PATHS ${CMAKE_OSX_SYSROOT}/System/Library ~/Library ${ARGV2}
                  PATH_SUFFIXES Frameworks
                  NO_DEFAULT_PATH)
    mark_as_advanced(FRAMEWORK_${LIF_NAME})
    if (${FRAMEWORK_${LIF_NAME}} STREQUAL FRAMEWORK_${LIF_NAME}-NOTFOUND)
        message (ERROR "${GLOBAL_TAB}: Framework ${LIF_NAME} not found")
    else (${FRAMEWORK_${LIF_NAME}} STREQUAL FRAMEWORK_${LIF_NAME}-NOTFOUND)
        target_link_libraries (${LIF_PROJ_NAME} ${FRAMEWORK_${LIF_NAME}})
        get_property(CURRENT_INCLUDES TARGET ${PNAME} PROPERTY INCLUDE_DIRECTORIES)
        set_property(TARGET ${PNAME} PROPERTY INCLUDE_DIRECTORIES "${CURRENT_INCLUDES};${FRAMEWORK_${LIF_NAME}}/Headers") 
        message (STATUS "${GLOBAL_TAB}Framework ${LIF_NAME} found at ${FRAMEWORK_${LIF_NAME}}")
    endif ()
endmacro(link_ios_framework)
