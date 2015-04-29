# The project is licensed under GNU GPL v3. See $(PROJECT_ROOT)/docs/gpl-3.0.txt for more details.
#
# KRAL
# Copyright (C) 2015 Cristian Bidea
cmake_minimum_required (VERSION 3.0)
cmake_policy(SET CMP0054 NEW)

macro(set_module_includes PNAME)
    set (${PNAME}_MODULE_INCLUDE_DIRS "")
    if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/include")
        list (APPEND ${PNAME}_MODULE_INCLUDE_DIRS "${CMAKE_CURRENT_LIST_DIR}/include")
    endif ()
    foreach (dep ${${PNAME}_DEPS})
	    foreach (package ${PACKAGES})
    	    if (EXISTS "${package}/${dep}")
                if (EXISTS "${package}/${dep}/include")
                    set (SPT ${GLOBAL_TAB})
                    set (GLOBAL_TAB "${GLOBAL_TAB}    ")
                    message (STATUS "${GLOBAL_TAB}-I ${dep}/include")
                    list (APPEND ${PNAME}_MODULE_INCLUDE_DIRS "${package}/${dep}/include")
                    set (GLOBAL_TAB "${SPT}")
                endif ()
            endif()
    	endforeach()
    endforeach ()
    get_property(CURRENT_INCLUDES TARGET ${PNAME} PROPERTY INCLUDE_DIRECTORIES)
    set_property(TARGET ${PNAME} PROPERTY INCLUDE_DIRECTORIES "${CURRENT_INCLUDES};${${PNAME}_MODULE_INCLUDE_DIRS}") 
endmacro()

macro(build_dependencies PNAME)
    foreach (dep ${${PNAME}_DEPS})
        set (PACKAGE_EXISTS False)
	    foreach (package ${PACKAGES})
            if (EXISTS "${package}/${dep}")
                set (PACKAGE_EXISTS True)
                message (STATUS "${GLOBAL_TAB}DEPENDENCY: ${dep}")
                list_contains(WAS_BUILT ${dep}-lib-name ${CONSTRUCTED_LIBS})
                if (NOT WAS_BUILT)
                    set (SPT ${GLOBAL_TAB})
                    set (GLOBAL_TAB "${GLOBAL_TAB}    ")
                    set (GLOBAL_TAB "${GLOBAL_TAB}    ")
                    set (CURRENT_DEPENDENCY "${dep}-lib-name")
                    add_subdirectory("${package}/${dep}" "${CMAKE_BINARY_DIR}/${dep}")
                    list_contains(WAS_BUILT ${dep}-lib-name ${CONSTRUCTED_LIBS})
                    if (NOT WAS_BUILT)
                        list(APPEND CONSTRUCTED_LIBS "${dep}-lib-name")
                        set (CONSTRUCTED_LIBS "${CONSTRUCTED_LIBS}" CACHE INTERNAL "CONSTRUCTED_LIBS" FORCE)
                    endif()
                endif()
                message("CD: ${CURRENT_DEPENDENCY}")
                message("DEP: ${${dep}-lib-name}")
                if (NOT "${${dep}-lib-name}" STREQUAL "")
                    message ("Linking: ${${dep}-lib-name}")
                    target_link_libraries(${PNAME} ${${dep}-lib-name})
                endif()
                if (NOT "${EXPORTED_IOS_FRAMEWORKS}" STREQUAL "")
                    foreach (framework ${EXPORTED_IOS_FRAMEWORKS})
                        string (REPLACE "###" ";" out_framework ${framework})
                        message (STATUS "${GLOBAL_TAB}link_ios_framework ${out_framework}")
                        link_ios_framework(${PNAME} ${out_framework})
                    endforeach() 
                    set (EXPORTED_IOS_FRAMEWORKS "")
                endif()
                set (GLOBAL_TAB "${SPT}")
            endif()
    	endforeach()
        if (NOT PACKAGE_EXISTS)
            message (FATAL_ERROR "Package ${dep} doesn't exists in any package location!") 
        endif()
    endforeach ()
endmacro()

# List files from include, source/common and source/${PLATFORM}
# The list is later used to create libraries and/or executables
macro(list_files PNAME)
	IF (DEBUG_MESSAGES)
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/include")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/platform_include/${PLATFORM}")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/source/common")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}")
	ENDIF (DEBUG_MESSAGES)

    set (LF_LOCATIONS "${CMAKE_CURRENT_LIST_DIR}/include;${CMAKE_CURRENT_LIST_DIR}/source/common;${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}") 
    foreach (location ${LF_LOCATIONS})
        if ( EXISTS ${location}/ )
            SET (SOURCE_LOCATIONS "${SOURCE_LOCATIONS} ${location}" CACHE INTERNAL "sources locations" FORCE)
        endif()
    endforeach()

	foreach (EXTENSION ${INCLUDE_EXTENSIONS}) 
		file (GLOB_RECURSE F_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/include/${EXTENSION}")
		list (APPEND ${PNAME}_F_INCLUDE ${F_INCLUDE})
		file (GLOB_RECURSE F_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/platform_include/${PLATFORM}/${EXTENSION}")
		list (LENGTH F_INCLUDE platfIncLength)
		list (APPEND ${PNAME}_F_INCLUDE ${F_INCLUDE})
	endforeach (EXTENSION)

    foreach (EXTENSION ${SOURCES_EXTENSIONS})
        FILE (GLOB_RECURSE F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/common/${EXTENSION}")
	    LIST (APPEND ${PNAME}_F_SOURCES ${F_SOURCES})
        FILE (GLOB_RECURSE plaf_F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/${EXTENSION}")
	    LIST (APPEND ${PNAME}_plaf_F_SOURCES ${plaf_F_SOURCES})
    endforeach (EXTENSION)
    
    IF (IOS)
        FILE (GLOB_RECURSE PNG_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/*.png")
        SET_SOURCE_FILES_PROPERTIES(${PNG_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${PNAME}_plaf_F_SOURCES "${PNG_SOURCES}")

        FILE (GLOB_RECURSE XIB_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/*.xib")
        SET_SOURCE_FILES_PROPERTIES(${XIB_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${PNAME}_plaf_F_SOURCES "${XIB_SOURCES}")

        FILE (GLOB_RECURSE ZIP_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/*.zip")
        SET_SOURCE_FILES_PROPERTIES(${ZIP_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${PNAME}_plaf_F_SOURCES "${ZIP_SOURCES}")

        FILE (GLOB_RECURSE OTHER_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/iTunesArtwork")
        SET_SOURCE_FILES_PROPERTIES(${OTHER_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${PNAME}_plaf_F_SOURCES "${OTHER_SOURCES}")
    ENDIF (IOS)

	IF (DEBUG_MESSAGES)
		MESSAGE("SOURCES: ${${PNAME}_F_SOURCES}")
		MESSAGE("PLAF SOURCES: ${${PNAME}_plaf_F_SOURCES}")
		MESSAGE("INCUDES: ${${PNAME}_F_INCLUDE}")
	ENDIF (DEBUG_MESSAGES)
endmacro(list_files)

# Returns TRUE or FALSE in var if the list
# contains the value
macro(list_contains var value)
  SET(${var})
  FOREACH (value2 ${ARGN})
    IF (${value} STREQUAL ${value2})
      SET(${var} TRUE)
    ENDIF (${value} STREQUAL ${value2})
  ENDFOREACH (value2)
endmacro()

# Records paths of runtime files to be copied to defer the copying to later
macro (append_to_runtime_files ATRF_PATH)
    if (EXISTS "${ATRF_PATH}/")
        list_contains(QRESULT ${ATRF_PATH} ${RUNTIME_TO_COPY})
    	if (NOT QRESULT)
            list (APPEND RUNTIME_TO_COPY "${ATRF_PATH}")
            set (RUNTIME_TO_COPY "${RUNTIME_TO_COPY}" CACHE INTERNAL "Runtime locations from which to copy files" FORCE)
        endif ()
    endif ()
endmacro ()

# copy_runtime_files implements the runtime folder functionality
# if you place something in runtime/common or runtime/${PLATFORM}, those files will be compied automatically
# in the runtime folder if that folder is set (${RUNTIME_DIR}${RUNTIME_SUFFIX})
# ${RUNTIME_SUFFIX} is used when you have a common runtime folder like ${CMAKE_BINARY_DIR} and you want to 
# customize it depending on the platform.
macro(COPY_RUNTIME_FILES)
    foreach (RTC_PATH ${RUNTIME_TO_COPY})
        message ("RTC_PATH: ${RTC_PATH}")
    	IF (NOT "${RUNTIME_DIR}" STREQUAL "")
    		if (EXISTS "${RTC_PATH}/")
                if (EXISTS "${RTC_PATH}/common/")
    				    EXEC_PROGRAM ("\"${CMAKE_COMMAND}\" -E copy_directory \"${RTC_PATH}/common\" \"${RUNTIME_DIR}${RUNTIME_SUFFIX}\"")
    				endif ()
                if (EXISTS "${RTC_PATH}/${PLATFORM}/")
    				    EXEC_PROGRAM ("\"${CMAKE_COMMAND}\" -E copy_directory \"${RTC_PATH}/${PLATFORM}\" \"${RUNTIME_DIR}${RUNTIME_SUFFIX}\"") 
                endif ()
                if (TESTS)
                    if (EXISTS "${RTC_PATH}/tests/")
    				    EXEC_PROGRAM ("\"${CMAKE_COMMAND}\" -E copy_directory \"${RTC_PATH}/tests\" \"${RUNTIME_DIR}${RUNTIME_SUFFIX}\"") 
    				endif ()
                endif ()
    		endif ()
        else ()
            message (STATUS "WARNING: RUNTIME_DIR isn't set, so COPY_RUNTIME_FILES will not work!")
        endif ()
    endforeach ()

    foreach (TTC_PATH ${TESTS_TO_COPY})
            message ("${TTC_PATH}")
            message ("RUNTIME: ${RUNTIME_DIR}${RUNTIME_SUFFIX}")
        if (EXISTS "${RUNTIME_DIR}${RUNTIME_SUFFIX}/")
            if (NOT "${RUNTIME_DIR}${RUNTIME_SUFFIX}" STREQUAL "${TTC_PATH}")
                message ("COPY: ${RUNTIME_DIR}${RUNTIME_SUFFIX} -> ${TTC_PATH}")
                if (NOT EXISTS "${TTC_PATH}/")
                    EXEC_PROGRAM ("\"${CMAKE_COMMAND}\" -E make_directory \"${TTC_PATH}\"")
                endif ()
                EXEC_PROGRAM ("\"${CMAKE_COMMAND}\" -E copy_directory \"${RUNTIME_DIR}${RUNTIME_SUFFIX}\" \"${TTC_PATH}\"")
            endif ()
        endif ()
    endforeach ()
endmacro(COPY_RUNTIME_FILES)

macro(init_runtime_location)
    # if RUNTIME_DIR isn't set then give it some default values
    if ("${RUNTIME_DIR}" STREQUAL "")
        if (ANDROID)
            # on android we have to give it a static value because
            # we can't use the library location because the library
            # isn't generated in the binary directory, we copy it
            # afterwards
            set (RUNTIME_DIR "${CMAKE_BINARY_DIR}")
            set (RUNTIME_SUFFIX "/android")
        else ()
            get_target_property(E_MODULE_PATH ${NAME} LOCATION_${CMAKE_BUILD_TYPE})
            message ("MODULE_PATH: ${E_MODULE_PATH}")
            string(REPLACE "$(EFFECTIVE_PLATFORM_NAME)" "" E_MODULE_PATH ${E_MODULE_PATH})
            get_filename_component(E_MODULE_PATH ${E_MODULE_PATH} PATH)
            set (RUNTIME_DIR "${E_MODULE_PATH}")
            set (RUNTIME_SUFFIX "")
        endif ()
        message (STATUS "RUNTIME_DIR was set to default value: ${RUNTIME_DIR}${RUNTIME_SUFFIX}")
    endif ()

endmacro()
