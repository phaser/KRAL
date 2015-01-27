cmake_minimum_required (VERSION 2.8)
include (${CMAKE_SOURCE_DIR}/config.cmake)

# ============================================================================
# Local used macros
# ============================================================================

# Prints the settings of the target to console
macro (print_target THE_TARGET)
    message ("
== ${TARGET_NAME_${THE_TARGET}}
    Platform:\t\t\t${PLATFORM_${THE_TARGET}}
    Project generator:\t${PROJECT_TYPE_${THE_TARGET}}
    Project directory:\t${PROJECT_DIR_${THE_TARGET}}
    Build directory:\t\t${BUILD_DIR_${THE_TARGET}}
    Custom args:\t\t${CUSTOM_ARGS_${THE_TARGET}}")
endmacro ()

# Parses custom args options and compiler flags to file to a special file
macro (parse_custom_args LT)
    string (REPLACE "-D" " CACHE INTERNAL \"\" FORCE)\nset (\"" NEWSTR ${CUSTOM_ARGS_${LT}})
    string (REPLACE "=" "\" " NEWSTR ${NEWSTR})
    string (FIND ${NEWSTR} " CACHE INTERNAL" POS)
    string (SUBSTRING ${CUSTOM_ARGS_${LT}} 0 ${POS} CSTR)
    if (NOT "${POS}" STREQUAL "-1")
    	set (CUSTOM_ARGS_${LT} ${CSTR})
    	math (EXPR POS "${POS} + 26")
    	string (SUBSTRING ${NEWSTR} ${POS} -1 NEWSTR)
    	set (NEWSTR "${NEWSTR} )")
    	#MESSAGE ("NEWSTR: ${NEWSTR}")
    	#MESSAGE ("NEWSTR: ${CUSTOM_ARGS_${LT}}")
    else ()
	set (NEWSTR "")
    endif()
endmacro()

# Prints custom args options and compiler flags to file to a special file
macro (print_lenghty_options_to_file LT)
    file (WRITE ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}/build_config.cmake "cmake_minimum_required (VERSION 2.8)\n")
    file (APPEND ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}/build_config.cmake "${NEWSTR}\n")
    file (APPEND ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}/build_config.cmake "set (CUSTOM_COMPILER_OPTS \"${COMPILER_CUSTOM_${LT}}\" CACHE INTERNAL \"Custom compiler options\" FORCE)\n")
endmacro ()

# ============================================================================
# Main script
# ============================================================================
if ("${T}" STREQUAL "" AND "${N}" STREQUAL "")
    set (counter "0")
    set (MSG "USAGE: cmake -DT=[target] -D[BUILD_OPTION]=1 -P build.cmake
BUILD_OPTION = GENERATE | COMPILE | UPDATE | BUILD | LIST
target = one of the target listed below
Available targets:")

    foreach (target ${TARGETS})
        math (EXPR counter "${counter} + 1")
        string (LENGTH "${PLATFORM_${target}}" PTLEN)
        math (EXPR PTSIZE "12 - ${PTLEN}")
        set (TMPTARGET "[${PLATFORM_${target}}]")
        foreach (num RANGE ${PTSIZE})
            set (TMPTARGET "${TMPTARGET} ")
        endforeach()
        set (TARGET_INFO_${target} "${counter}. ${TMPTARGET}${TARGET_NAME_${target}}")
        set (MSG "${MSG}
    ${TARGET_INFO_${target}}")
    endforeach ()     
    message (FATAL_ERROR ${MSG})
endif ()

# Find the target
if (NOT "${N}" STREQUAL "")
    math (EXPR N "${N} - 1")
    list (GET TARGETS ${N} T)
    message ("Start building ${T}...")
endif ()

if ("${TARGET_NAME_${T}}" STREQUAL "")
    message (FATAL_ERROR "Target ${T} is not defined. Are you sure you spelled the name right?")
endif ()

parse_custom_args(${T})

set (CMAKE_GENERATED_COMMAND "\"${CMAKE_COMMAND}\" ${CUSTOM_ARGS_${T}} ${CUSTOM_ARGS_PD_${T}} ")
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
set (CMAKE_GENERATED_COMMAND "${CMAKE_GENERATED_COMMAND} -DNEW_CMAKE=1 -DPACKAGES=\"${PACKAGE_DIRS}\" -DCMAKE_BUILD_TYPE=${BUILD_TYPE_${T}} -DKRAL_PATH=\"${KRAL_PATH}\" -DPLATFORM=\"${PLATFORM_${T}}\" -G \"${PROJECT_TYPE_${T}}\" \"${PROJECT_DIR_${T}}\"")

if (GENERATE OR G)
    exec_program("\"${CMAKE_COMMAND}\" -E remove_directory ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}" RETURN_VALUE GCRV)

    if (NOT "${GCRV}" STREQUAL "0")
        message(FATAL_ERROR "Couldn't remove directory ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}")
    endif ()

    file(MAKE_DIRECTORY "${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}")
    
    # Because some operating systems are dump (*cough* Windows *cough*) and can handle a lot of arguments
    # we have to put the arguments into a file that gets included later by the build system.
    # NOTE: The good thing in this situation is that it is OK to help the elders! ;)
    print_lenghty_options_to_file(${T})

    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}} "${CMAKE_GENERATED_COMMAND}")
    if (GENERATE_CMAKELISTS_${T})
        set (CMLFILE "CMakeLists.txt")
        file (WRITE ${CMLFILE} "cmake_minimum_required(VERSION 2.8)\n")
        file (APPEND ${CMLFILE} "set (ANDROID_NDK $ENV{NDK} CACHE INTERNAL ANDROID_NDK FORCE)\n")
        file (APPEND ${CMLFILE} "set (KRAL_PATH ${KRAL_PATH} CACHE INTERNAL KRAL_PATH FORCE)\n")
        file (APPEND ${CMLFILE} "set (PLATFORM ${PLATFORM_${T}} CACHE INTERNAL PLATFORM FORCE)\n")
        file (APPEND ${CMLFILE} "set (CMAKE_BUILD_TYPE ${BUILD_TYPE_${T}} CACHE INTERNAL BUILD_TYPE FORCE)\n")
        file (APPEND ${CMLFILE} "set (PACKAGES ${PACKAGE_DIRS} CACHE INTERNAL PACKAGE_DIRS FORCE)\n")
        file (APPEND ${CMLFILE} "set (NEW_CMAKE True)\n")
        file (APPEND ${CMLFILE} "${NEWSTR}\n")
        file (APPEND ${CMLFILE} "add_subdirectory (${PROJECT_DIR_${T}})")
    endif ()
elseif (UPDATE OR U)
    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}} "${CMAKE_GENERATED_COMMAND}")
elseif (COMPILE OR C)
    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}} 
            \"${CMAKE_COMMAND}\" --build .)
elseif (LIST OR L)
    print_target(${T})
elseif (BUILD OR B)
    file(REMOVE_RECURSE "${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}")
    file(MAKE_DIRECTORY "${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}}")
 
    print_lenghty_options_to_file(${T})

    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}} "${CMAKE_GENERATED_COMMAND}")
    exec_program ("${CMAKE_COMMAND}" ARGS -E chdir ${PROJECTS_ROOT_DIR}/${BUILD_DIR_${T}} 
            \"${CMAKE_COMMAND}\" --build .)
endif()


