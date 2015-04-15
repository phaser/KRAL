# The project is licensed under GNU GPL v3. See $(PROJECT_ROOT)/docs/gpl-3.0.txt for more details.
#
# KRAL
# Copyright (C) 2015 Cristian Bidea

cmake_minimum_required (VERSION 3.0)
cmake_policy(SET CMP0054 NEW)

# Constants
set (TARGET_NAME    0)
set (KRAL_PATH_INT  1)
set (PACKAGE_DIRS   2)
set (PROJECTS_ROOT  3)
set (PLATFORM       4)
set (PROJECT_DIR    5)
set (BUILD_DIR      6)
set (PROJECT_TYPE   7)
set (BUILD_TYPE     8)
set (CUSTOM_ARGS    9)
set (CUSTOM_ARGS_PD 10)
set (NUM_PROPS          11)
set (NUM_PROPS_MINUS_1  10)
set (NUM_PROPS_MINUS_2  8)
set (LIST_NAMES "TARGET_NAME;KRAL_PATH;PACKAGE_DIRS;PROJECTS_ROOT;PLATFORM;PROJECT_DIR;BUILD_DIR;PROJECT_TYPE;BUILD_TYPE;CUSTOM_ARGS;CUSTOM_ARGS_PD")

# Called once to initialize the list for the target
function(create_target LST)
    # Add the target to the TARGETS list
    list (APPEND TARGETS "${LST}")
    set (TARGETS "${TARGETS}" CACHE INTERNAL "TARGETS" FORCE)
    # Initialize the list with targets properties
    foreach (idx RANGE ${NUM_PROPS})
        list(APPEND ${LST} "_N_")
    endforeach()
    set (${LST} "${${LST}}" CACHE INTERNAL "${LST}" FORCE)
    set_target_value(${LST} ${TARGET_NAME} ${LST})
    set (${LST} "${${LST}}" CACHE INTERNAL "${LST}" FORCE)
endfunction()

# Used to set a specific value in the list
function(set_target_value LST IDX VALUE)
    if ("${VALUE}" STREQUAL "")
        message(FATAL_ERROR "Empty value!")
    endif()
    list(REMOVE_AT ${LST} ${IDX})
    list(INSERT ${LST} ${IDX} ${VALUE}) 
    set (${LST} "${${LST}}" CACHE INTERNAL "${LST}" FORCE)
endfunction()

# Get a value for a property of the target
# This would not be needed normally but we have greater
# flexibility. For example to store lists in a list we
# have to change the separator from ; to _&_ and then
# when we get the value back we must do the reverse
# operation.
macro(get_target_value LST IDX OVAL)
    list(GET ${LST} ${IDX} __TEMP)
    string(REPLACE "_&_" ";" ___TEMP "${__TEMP}")
    set(${OVAL} ${___TEMP})
endmacro()

# Utility macro
macro(transform_to_list PLIST ML)
    string(REPLACE "_&_" ";" ML "${PLIST}")
endmacro()

# Print all the properties of a target
function(print_target LST)
    list(GET ${LST} 0 OUTVAR)
    message ("Listing ${OUTVAR}...") 
    foreach(idx RANGE 1 ${NUM_PROPS_MINUS_1})
        list(GET LIST_NAMES ${idx} NVAR)
        list(GET ${LST} ${idx} OUTVAR)
        transform_to_list(${OUTVAR} ML)
        if ("${ML}" STREQUAL "_N_")
            set (ML "")
        endif()
        message("\t${NVAR}:\t${ML}")
    endforeach()
endfunction()

# Used by the INHERIT attribute to copy a target to another one
function(copy_target FROM TO)
    foreach (idx RANGE 1 ${NUM_PROPS_MINUS_1})
        list (GET ${FROM} ${idx} value)
        set_target_value(${TO} ${idx} ${value})
    endforeach()
endfunction()

macro (set_internal_check_vars VAL)
    set (processing_custom_args    ${VAL})
    set (processing_custom_args_pd ${VAL})
endmacro()

# function called from config.cmake to configure targets
function(add_target TNAME)
    create_target(${TNAME})
    set (value 0)
    set_internal_check_vars(False)
    set (acc_custom_args "")
    while (value LESS ${ARGC})
        # Treat all the props the same but CUSTOM_ARGS different
        # because it will contain multiple args
        foreach (idx RANGE ${NUM_PROPS_MINUS_2})
            list (GET LIST_NAMES ${idx} PROP_NAME)
            if ("${ARGV${value}}" STREQUAL "${PROP_NAME}")    
                math (EXPR value "${value} + 1")
                if ("${PROP_NAME}" STREQUAL "PACKAGE_DIRS")
                    string (REPLACE ";" "_&_" OUTVAL "${ARGV${value}}")
                    set_target_value(${TNAME} ${idx} ${OUTVAL})
                else()
                    set_target_value(${TNAME} ${idx} ${ARGV${value}})
                endif()
                set_internal_check_vars(False)
            endif()
        endforeach()
        
        if ("${ARGV${value}}" STREQUAL "INHERIT")
                math (EXPR value "${value} + 1")
                set_internal_check_vars(False)
                copy_target("${ARGV${value}}" "${TNAME}")                
        endif()
        # we have to do this to allow CUSTOM_ARGS to span multiple ARGS
        if ("${ARGV${value}}" STREQUAL "CUSTOM_ARGS")    
            set_internal_check_vars(False)
        elseif ("${ARGV${value}}" STREQUAL "CUSTOM_ARGS_PD") 
            set_internal_check_vars(False)
        endif()

        if (processing_custom_args)
            set (acc_custom_args "${acc_custom_args}${ARGV${value}}")
        elseif (processing_custom_args_pd)
            set (acc_custom_args_pd "${acc_custom_args_pd}${ARGV${value}}")
        endif()

        if ("${ARGV${value}}" STREQUAL "CUSTOM_ARGS")    
            set (processing_custom_args True)
        elseif ("${ARGV${value}}" STREQUAL "CUSTOM_ARGS_PD") 
            set (processing_custom_args_pd True)
        endif()
        math (EXPR value "${value} + 1")
    endwhile()

    if (NOT "${acc_custom_args}" STREQUAL "")
        set_target_value(${TNAME} ${CUSTOM_ARGS} "${acc_custom_args}")
    endif()
    if (NOT "${acc_custom_args_pd}" STREQUAL "")
        set_target_value(${TNAME} ${CUSTOM_ARGS_PD} "${acc_custom_args_pd}")
    endif()
    get_target_value(${TNAME} ${KRAL_PATH_INT} TMP)
    if (NOT "${TMP}" STREQUAL "_N_")
        set(KRAL_PATH "${TMP}" CACHE INTERNAL "KRAL_PATH" FORCE)
    endif()
endfunction()

# Reading the config file
include (${CMAKE_SOURCE_DIR}/config_new.cmake)

# outputs a pretty printed list with the available targets
macro (list_targets OUTVAR)
    set (${OUTVAR} "")
    set (counter "0")
    foreach (target ${TARGETS})
        if (NOT "${target}" STREQUAL "__DEFAULT")
            list (GET ${target} ${PLATFORM} PLATFORM_NAME)
            math (EXPR counter "${counter} + 1")
            string (LENGTH "${PLATFORM_NAME}" PTLEN)
            math (EXPR PTSIZE "12 - ${PTLEN}")
            set (TMPTARGET "[${PLATFORM_NAME}]")
            foreach (num RANGE ${PTSIZE})
                set (TMPTARGET "${TMPTARGET} ")
            endforeach()
            set (TINFO "${counter}. ${TMPTARGET}${target}")
            set (${OUTVAR} "${${OUTVAR}}
        ${TINFO}")
        endif()
    endforeach()
endmacro()

function (output_help)
    set (MSG "USAGE: cmake -D[BUILD_OPTION]=1 -P build.cmake

    BUILD_OPTION = GENERATE | COMPILE | UPDATE | BUILD | LIST
    BUILD_OPTION = You can also use just the first letter [GCUBL]
    -DT=target   = Select a target by name.
    -DN=         = Select a target by number.

    Available targets:")
    list_targets(OUTVAR)
    message("${MSG}${OUTVAR}")
endfunction()

# Parses custom args options and compiler flags to file to a special file
macro (parse_custom_args LT)
    get_target_value(${LT} ${CUSTOM_ARGS} OVAL) 
    set (CUSTOM_ARGS_${LT} "${OVAL}") 
    string (REPLACE "-D" " CACHE INTERNAL \"\" FORCE)\nset (\"" NEWSTR ${CUSTOM_ARGS_${LT}})
    string (REPLACE "=" "\" " NEWSTR ${NEWSTR})
    string (FIND ${NEWSTR} " CACHE INTERNAL" POS)
    string (SUBSTRING ${CUSTOM_ARGS_${LT}} 0 ${POS} CSTR)
    if (NOT "${POS}" STREQUAL "-1")
    	set (CUSTOM_ARGS_${LT} ${CSTR})
    	math (EXPR POS "${POS} + 26")
    	string (SUBSTRING ${NEWSTR} ${POS} -1 NEWSTR)
    	set (NEWSTR "${NEWSTR} )")
    else ()
	set (NEWSTR "")
    endif()
endmacro()

# Prints custom args options and compiler flags to file to a special file
macro (print_lenghty_options_to_file LT)
    file (WRITE ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}/build_config.cmake "cmake_minimum_required (VERSION 2.8)\n")
    file (APPEND ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}/build_config.cmake "${NEWSTR}\n")
    file (APPEND ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}/build_config.cmake "set (CUSTOM_COMPILER_OPTS \"${COMPILER_CUSTOM_${LT}}\" CACHE INTERNAL \"Custom compiler options\" FORCE)\n")
endmacro ()

# ============================================================================
# Main script
# ============================================================================
if ("${T}" STREQUAL "" AND "${N}" STREQUAL "")
    output_help()
    return()
endif()

## Verify if target is specified by number
if (NOT "${N}" STREQUAL "")
    # Target 0 is the __DEFAULT
    # Not interesting
    if (${N} EQUAL 0)
        output_help()
        return()
    endif()

    list(LENGTH TARGETS LL)
    if ((${N} LESS ${LL}))
        list (GET TARGETS ${N} T)
    else()
        output_help()
        return()
    endif()
endif()

# Verify if target actually exists
list (FIND TARGETS "${T}" TARGET_EXISTS)
if (${TARGET_EXISTS} EQUAL -1)
    output_help()
    return()
endif()

parse_custom_args(${T})

get_target_value(${T} ${PLATFORM} PLATFORM_${T})
get_target_value(${T} ${PROJECT_TYPE} PROJECT_TYPE_${T})
get_target_value(${T} ${PROJECT_DIR} PROJECT_DIR_${T})
get_target_value(${T} ${PACKAGE_DIRS} PACKAGE_DIRS_STR)
get_target_value(${T} ${PROJECTS_ROOT} PROJECTS_ROOT_DIR)
get_target_value(${T} ${CUSTOM_ARGS_PD} CAPDV) 
set (CUSTOM_ARGS_PD_${T} "${CAPDV}") 
get_target_value(${T} ${BUILD_DIR} CURRENT_BUILD_DIR)

# Initialize the generated command
set (CMAKE_GENERATED_COMMAND "\"${CMAKE_COMMAND}\" ${CUSTOM_ARGS_${T}} ${CUSTOM_ARGS_PD_${T}} ")

# Find ANDROID_TARGET
if ("${PLATFORM_${T}}" STREQUAL "android")
    # Determine android target number
    set (ANDROID_BINARY "android")
    exec_program("${ANDROID_BINARY} list targets" OUTPUT_VARIABLE ALT_OUTPUT RETURN_VALUE ALTRV)
    if (NOT "${ALTRV}" STREQUAL "0")
        message(STATUS "${ALT_OUTPUT}")
        message(FATAL "android list targets returned error code ${ALTRV}")
    endif()
    string(REGEX MATCH "id: ([0-9]+) or \"${API_LEVEL_${T}}\"" ALT_MATCH ${ALT_OUTPUT})
    set(ANDROID_TARGET "${CMAKE_MATCH_1}")
    set (CMAKE_GENERATED_COMMAND "${CMAKE_GENERATED_COMMAND} -DANDROID_TARGET=${ANDROID_TARGET} -DCMAKE_TOOLCHAIN_FILE=${KRAL_PATH}/android-cmake/toolchain/android.toolchain.cmake -DANDROID_NDK=$ENV{NDK} -DANDROID_API_LEVEL=${API_LEVEL_${T}}")
endif()

set (CMAKE_GENERATED_COMMAND "${CMAKE_GENERATED_COMMAND} -DNEW_CMAKE=1 -DPACKAGES=\"${PACKAGE_DIRS_STR}\" -DCMAKE_BUILD_TYPE=${BUILD_TYPE_${T}} -DKRAL_PATH=\"${KRAL_PATH}\" -DPLATFORM=\"${PLATFORM_${T}}\" -G \"${PROJECT_TYPE_${T}}\" \"${PROJECT_DIR_${T}}\"")

if (GENERATE OR G)
    exec_program("\"${CMAKE_COMMAND}\" -E remove_directory ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}" RETURN_VALUE GCRV)

    if (NOT "${GCRV}" STREQUAL "0")
        message(FATAL_ERROR "Couldn't remove directory ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}")
    endif ()

    file(MAKE_DIRECTORY "${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}")
    
    # Because some operating systems are dump (*cough* Windows *cough*) and can't handle a lot of arguments
    # we have to put the arguments into a file that gets included later by the build system.
    # NOTE: The good thing in this situation is that it is OK to help the elders! ;)
    print_lenghty_options_to_file(${T})

    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR} "${CMAKE_GENERATED_COMMAND}")
    if (GENERATE_CMAKELISTS_${T})
        set (CMLFILE "CMakeLists.txt")
        file (WRITE ${CMLFILE} "cmake_minimum_required(VERSION 2.8)\n")
        file (APPEND ${CMLFILE} "set (ANDROID_NDK $ENV{NDK} CACHE INTERNAL ANDROID_NDK FORCE)\n")
        file (APPEND ${CMLFILE} "set (KRAL_PATH ${KRAL_PATH} CACHE INTERNAL KRAL_PATH FORCE)\n")
        file (APPEND ${CMLFILE} "set (PLATFORM ${PLATFORM_${T}} CACHE INTERNAL PLATFORM FORCE)\n")
        file (APPEND ${CMLFILE} "set (CMAKE_BUILD_TYPE ${BUILD_TYPE_${T}} CACHE INTERNAL BUILD_TYPE FORCE)\n")
        file (APPEND ${CMLFILE} "set (PACKAGES ${PACKAGE_DIRS_STR} CACHE INTERNAL PACKAGE_DIRS FORCE)\n")
        file (APPEND ${CMLFILE} "set (NEW_CMAKE True)\n")
        file (APPEND ${CMLFILE} "${NEWSTR}\n")
        file (APPEND ${CMLFILE} "add_subdirectory (${PROJECT_DIR_${T}})")
    endif ()
elseif (UPDATE OR U)
    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR} "${CMAKE_GENERATED_COMMAND}")
elseif (COMPILE OR C)
    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR} 
            \"${CMAKE_COMMAND}\" --build .)
elseif (LIST OR L)
    print_target(${T})
elseif (BUILD OR B)
    file(REMOVE_RECURSE "${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}")
    file(MAKE_DIRECTORY "${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR}")
 
    print_lenghty_options_to_file(${T})

    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR} "${CMAKE_GENERATED_COMMAND}")
    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${CURRENT_BUILD_DIR} 
            \"${CMAKE_COMMAND}\" --build .)
endif()
