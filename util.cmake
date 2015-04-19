# The project is licensed under GNU GPL v3. See $(PROJECT_ROOT)/docs/gpl-3.0.txt for more details.
#
# KRAL
# Copyright (C) 2015 Cristian Bidea
cmake_minimum_required (VERSION 3.0)

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
	    foreach (package ${PACKAGES})
            if (EXISTS "${package}/${dep}")
                message (STATUS "${GLOBAL_TAB}DEPENDENCY: ${dep}")
                if (NOT EXISTS "${CMAKE_BINARY_DIR}/${dep}")
                    set (SPT ${GLOBAL_TAB})
                    set (GLOBAL_TAB "${GLOBAL_TAB}    ")
                    set (GLOBAL_TAB "${GLOBAL_TAB}    ")
                    add_subdirectory("${package}/${dep}" "${CMAKE_BINARY_DIR}/${dep}")
                endif()
                if (NOT "${EXPORTED_IOS_FRAMEWORKS}" STREQUAL "")
                    foreach (framework "${EXPORTED_IOS_FRAMEWORKS}")
                        message (STATUS "${GLOBAL_TAB}link_ios_framework ${framework}")
                        link_ios_framework(${PNAME} ${framework})
                    endforeach() 
                    set (EXPORTED_IOS_FRAMEWORKS "")
                endif()
                set (GLOBAL_TAB "${SPT}")
            endif()
    	endforeach()
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

