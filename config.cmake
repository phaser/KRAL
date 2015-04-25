# The project is licensed under GNU GPL v3. See $(PROJECT_ROOT)/docs/gpl-3.0.txt for more details.
#
# KRAL
# Copyright (C) 2011 Cristian Bidea

if (EXISTS ${CMAKE_BINARY_DIR}/build_config.cmake)
    include(${CMAKE_BINARY_DIR}/build_config.cmake)
endif()
if (TESTS)
    ENABLE_TESTING()
endif (TESTS)

# macro taken from this StackOverflow answer 
# http://stackoverflow.com/questions/10113017/setting-the-msvc-runtime-in-cmake
macro(configure_msvc_runtime)
  if(MSVC)
    # Default to statically-linked runtime.
    if("${MSVC_RUNTIME}" STREQUAL "")
      set(MSVC_RUNTIME "static")
    endif()
    # set compiler options.
    set(variables
      CMAKE_C_FLAGS_DEBUG
      CMAKE_C_FLAGS_MINSIZEREL
      CMAKE_C_FLAGS_RELEASE
      CMAKE_C_FLAGS_RELWITHDEBINFO
      CMAKE_CXX_FLAGS_DEBUG
      CMAKE_CXX_FLAGS_MINSIZEREL
      CMAKE_CXX_FLAGS_RELEASE
      CMAKE_CXX_FLAGS_RELWITHDEBINFO
    )
    if(${MSVC_RUNTIME} STREQUAL "static")
      message(STATUS
        "MSVC -> forcing use of statically-linked runtime."
      )
      foreach(variable ${variables})
        if(${variable} MATCHES "/MD")
          string(REGEX REPLACE "/MD" "/MT" ${variable} "${${variable}}")
        endif()
      endforeach()
    else()
      message(STATUS
        "MSVC -> forcing use of dynamically-linked runtime."
      )
      foreach(variable ${variables})
        if(${variable} MATCHES "/MT")
          string(REGEX REPLACE "/MT" "/MD" ${variable} "${${variable}}")
        endif()
      endforeach()
    endif()
  endif()
endmacro()

if (IOS)
 	set (STOP_ON_ERRORS "")
endif (IOS)

#set(BUILD_SHARED_LIBS ON)

set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos;-iphonesimulator")

#Build configuration
if (NOT DEFINED CMAKE_BUILD_TYPE)
    message (STATUS "CMAKE_BUILD_TYPE is not defined, defaulting to debug.")
    set(CMAKE_BUILD_TYPE "debug")
    set(CMAKE_CONFIGURATION_TYPES Debug)
else (NOT DEFINED CMAKE_BUILD_TYPE)
    if ("${CMAKE_BUILD_TYPE}" STREQUAL "release")
        set(CMAKE_CONFIGURATION_TYPES Release)
    else ("${CMAKE_BUILD_TYPE}" STREQUAL "release")
        set(CMAKE_CONFIGURATION_TYPES Debug)
    endif ("${CMAKE_BUILD_TYPE}" STREQUAL "release")
endif (NOT DEFINED CMAKE_BUILD_TYPE)

if (NOT NEW_CMAKE)
#packages
if (NOT DEFINED PACKAGES)
    FILE(TO_CMAKE_PATH "${KRAL_PATH}/../packages" TMP)
    set (PACKAGES ${TMP})
else (NOT DEFINED PACKAGES)
    LIST (LENGTH TMP LN)
    if (${LN} EQUAL 0)
        foreach(package ${PACKAGES})
            FILE(TO_CMAKE_PATH "${KRAL_PATH}/${package}" package)
            LIST(APPEND TMP ${package})
        endforeach(package)
        set(PACKAGES ${TMP})
        message(STATUS "PACKAGES: ${PACKAGES}")
    endif (${LN} EQUAL 0)
endif (NOT DEFINED PACKAGES)
endif()

message (STATUS "PLATFORM ${PLATFORM}")
if (DEFINED PLATFORM AND NOT PLATFORM STREQUAL "")
    string (TOUPPER ${PLATFORM} TMPPLATFORM)
    set (${TMPPLATFORM} "ON" CACHE INTERNAL "We are compiling for ${TMPPLATFORM}." FORCE)
    message ("We are compiling for platform -> ${TMPPLATFORM}")
endif ()

IF (CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX OR CMAKE_HOST_APPLE) #CMAKE_HOST_APPLE for OSX (llvm) build..
	SET (DC "-D")
ELSEIF (MSVC)
	SET (DC "/D")
ENDIF (CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX OR CMAKE_HOST_APPLE)

set (GNU_GPROF_FLAGS "")
if (DEFINED ENABLE_GPROF_PROFILING)
    message (STATUS "Profiling enabled. ENABLE_GPROF_PROFILING=${ENABLE_GPROF_PROFILING}")
    set (GNU_GPROF_FLAGS "-pg")
endif (DEFINED ENABLE_GPROF_PROFILING)

if (EXISTS "${CMAKE_BINARY_DIR}/compiler_config.cmake")
    include("${CMAKE_BINARY_DIR}/compiler_config.cmake")
endif()

if (ANDROID)
elseif (QT5)
    # hack for osx only
	SET (CMAKE_OSX_SYSROOT=${OSX_SDK_PATH}${TARGETSDK})
	SET (CMAKE_OSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET})
	SET (CMAKE_OSX_ARCHITECTURES_DEBUG ${ARCHS_STANDARD_32_BIT})
	SET (CMAKE_OSX_ARCHITECTURES_RELEASE ${ARCHS_STANDARD_32_BIT})
elseif (WIN32)
	configure_msvc_runtime()
    set (CMAKE_CXX_FLAGS "/EHsc /W4 /MP /D_CRT_SECURE_NO_WARNINGS /wd4201 /wd4512 /DWIN32 /D_WINDOWS /DPLATFORM_WIN32 ${CUSTOM_COMPILER_OPTS}")
    set (CMAKE_C_FLAGS "/EHsc /W3 /MP /D_CRT_SECURE_NO_WARNINGS /DPLATFORM_WIN32 ${CUSTOM_COMPILER_OPTS}")
elseif (IOS)
    set (CMAKE_OSX_SYSROOT "${IOS_SDK_PATH}/${TARGETSDK}")
    set (CMAKE_OSX_ARCHITECTURES_DEBUG "${ARCHS_STANDARD_32_BIT}")
    set (CMAKE_OSX_ARCHITECTURES_RELEASE "${ARCHS_STANDARD_32_BIT}")
elseif (OSX)
	SET (CMAKE_OSX_SYSROOT=${OSX_SDK_PATH}${TARGETSDK})
	SET (CMAKE_OSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET})
	SET (CMAKE_OSX_ARCHITECTURES_DEBUG ${ARCHS_STANDARD_32_BIT})
	SET (CMAKE_OSX_ARCHITECTURES_RELEASE ${ARCHS_STANDARD_32_BIT})
endif ()

set (DEBUG_MESSAGES "OFF" CACHE INTERNAL "Enable or disable debug messages" FORCE)
