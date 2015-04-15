# The project is licensed under GNU GPL v3. See $(PROJECT_ROOT)/docs/gpl-3.0.txt for more details.
#
# KRAL
# Copyright (C) 2011 Cristian Bidea

cmake_minimum_required (VERSION 2.8)

set (SOURCES_EXTENSIONS "*.c;*.cc;*.cpp;*.cxx;*.m;*.mm;*.ui;*.h")
set (INCLUDE_EXTENSIONS "*.h;*.hpp")

INCLUDE (KRALConfig)
if (NOT TARGET KRAL_END_OF_BUILD_TARGET)
    ADD_CUSTOM_TARGET (KRAL_END_OF_BUILD_TARGET ALL)
endif ()
# ============================================================================
# KRALMain private interface
# ============================================================================
# Evaluate expression
# Suggestion from the Wiki: http://cmake.org/Wiki/CMake/Language_Syntax
# Unfortunately, no built-in stuff for this: http://public.kitware.com/Bug/view.php?id=4034
macro(eval expr)
  set (_fname "${CMAKE_BINARY_DIR}/.eval.cmake")
  file(WRITE ${_fname} "${expr}")
  include(${_fname} OPTIONAL)
  #file(REMOVE ${_fname})
endmacro(eval)

# android generate project doesn't do everything necessary for ndk-gdb to work
# we have to do this manually. This macro should do everything in this regard
# it is in the private interface because it is automatically called from within KRALMain.txt
# the user shouldn't have the need to call it.
macro (generate_ndkgdb_config TARGET)    
    MESSAGE(STATUS "Generating ndk-gdb config...")
    MESSAGE(STATUS "ANDROID_ABI: ${ANDROID_ABI}")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/obj")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/obj/local")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/obj/local/${ANDROID_ABI}")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/libs")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/libs/${ANDROID_ABI}")
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/jni")
    FILE (WRITE "${CMAKE_BINARY_DIR}/android/jni/Android.mk" "")

    SET (GDBSETUPFILE "${CMAKE_BINARY_DIR}/android/libs/armeabi/gdb.setup")
    FILE (WRITE "${GDBSETUPFILE}" "set solib-search-path $ENV{NDK}/platforms/${ANDROID_API_LEVEL}/arch-arm/usr/lib ${CMAKE_BINARY_DIR}/android/obj/local/${ANDROID_ABI}\n")
    FILE (APPEND "${GDBSETUPFILE}" "directory $ENV{NDK}/platforms/${ANDROID_API_LEVEL}/arch-arm/usr/include ${SOURCE_LOCATIONS}\n")

    if (NOT EXISTS ${CMAKE_BINARY_DIR}/android/libs/armeabi/ )
        EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/libs/armeabi")
    endif()
    EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E copy $ENV{NDK}/prebuilt/android-arm/gdbserver/gdbserver ${CMAKE_BINARY_DIR}/android/libs/armeabi")
    if (NOT "${ANDROID_ABI}" STREQUAL "armeabi")
        if (NOT EXISTS ${CMAKE_BINARY_DIR}/android/libs/${ANDROID_ABI}/ )
            EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_BINARY_DIR}/android/libs/${ANDROID_ABI}")
        endif()
        EXEC_PROGRAM("\"${CMAKE_COMMAND}\" -E copy $ENV{NDK}/prebuilt/android-arm/gdbserver/gdbserver ${CMAKE_BINARY_DIR}/android/libs/${ANDROID_ABI}")
    endif ()
    ADD_CUSTOM_COMMAND(TARGET ${TARGET}
                       POST_BUILD
                       COMMAND "${CMAKE_COMMAND}" ARGS "-E" "copy_directory" "${CMAKE_CURRENT_LIST_DIR}/libs" "${CMAKE_BINARY_DIR}/android/obj/local"
                       COMMAND "${CMAKE_COMMAND}" ARGS "-E" "copy_directory" "${CMAKE_BINARY_DIR}/android/libs" "${CMAKE_BINARY_DIR}/android/obj/local")
endmacro (generate_ndkgdb_config)

# Returns TRUE or FALSE in var if the list
# contains the value
macro(LIST_CONTAINS var value)
  SET(${var})
  FOREACH (value2 ${ARGN})
    IF (${value} STREQUAL ${value2})
      SET(${var} TRUE)
    ENDIF (${value} STREQUAL ${value2})
  ENDFOREACH (value2)
endmacro(LIST_CONTAINS)

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

# append_to_test_paths
macro (append_to_test_paths ATTP_PATH)
    list_contains(QRESULT ${ATTP_PATH} ${TESTS_TO_COPY})
    if (NOT QRESULT)
        list (APPEND TESTS_TO_COPY "${ATTP_PATH}")
        set (TESTS_TO_COPY "${TESTS_TO_COPY}" CACHE INTERNAL "Runtime locations from which to copy files" FORCE)
    endif ()
endmacro ()

# Register a macro to be executed by the top level process
macro (run_command_as_top_level_project COMMAND_NAME)
    list_contains(QRESULT ${COMMAND_NAME} ${RCATLP_LIST})
    if (NOT QRESULT)
        list (APPEND RCATLP_LIST "${COMMAND_NAME}")
        set (RCATLP_LIST "${RCATLP_LIST}" CACHE INTERNAL "macros to be executed by the parent" FORCE)
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

# A lot of variables are saved internally. In order for the update functionality of cmake to work
# those variables need to be cleaned up.
macro(CLEAR_CACHE)
    SET (SOURCE_LOCATIONS "" CACHE INTERNAL "sources locations" FORCE)
    foreach (module ${KRAL_MODULES_ADDED})
        set (EXPORTED_INCLUDES_${module} "")
        set (EXPORTED_MODULE_DEPS_${module} "" CACHE INTERNAL "Exported Modules" FORCE)
        set (PROJECT_TESTS_ADDED_${module} "" CACHE INTERNAL "" FORCE)
        set (EXPORTED_IOS_FRAMEWORKS_${module} "" CACHE INTERNAL "Exported IOS frameworks" FORCE)
    endforeach ()
    set (KRAL_MODULES_ADDED "" CACHE INTERNAL "Modules used by this project" FORCE)
    set (GLOBAL_TARGET_PROPERTY "" CACHE INTERNAL "Global target properties" FORCE)
    set (RUNTIME_TO_COPY "" CACHE INTERNAL "Runtime locations from which to copy files" FORCE)
    set (TESTS_TO_COPY "" CACHE INTERNAL "Runtime locations from which to copy files" FORCE)
    set (RCATLP_LIST "" CACHE INTERNAL "macros to be executed by the parent" FORCE)
endmacro(CLEAR_CACHE)

# List files from include, source/common and source/${PLATFORM}
# The list is later used to create libraries and/or executables
macro(list_files NAME)
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
		list (APPEND ${NAME}_F_INCLUDE ${F_INCLUDE})
		file (GLOB_RECURSE F_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/platform_include/${PLATFORM}/${EXTENSION}")
		list (LENGTH F_INCLUDE platfIncLength)
		list (APPEND ${NAME}_F_INCLUDE ${F_INCLUDE})
	endforeach (EXTENSION)

    foreach (EXTENSION ${SOURCES_EXTENSIONS})
        FILE (GLOB_RECURSE F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/common/${EXTENSION}")
	    LIST (APPEND ${NAME}_F_SOURCES ${F_SOURCES})
        FILE (GLOB_RECURSE plaf_F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/${EXTENSION}")
	    LIST (APPEND ${NAME}_plaf_F_SOURCES ${plaf_F_SOURCES})
    endforeach (EXTENSION)
    
    IF (IOS)
        FILE (GLOB_RECURSE PNG_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/*.png")
        SET_SOURCE_FILES_PROPERTIES(${PNG_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${NAME}_plaf_F_SOURCES "${PNG_SOURCES}")

        FILE (GLOB_RECURSE XIB_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/*.xib")
        SET_SOURCE_FILES_PROPERTIES(${XIB_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${NAME}_plaf_F_SOURCES "${XIB_SOURCES}")

        FILE (GLOB_RECURSE ZIP_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/*.zip")
        SET_SOURCE_FILES_PROPERTIES(${ZIP_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${NAME}_plaf_F_SOURCES "${ZIP_SOURCES}")

        FILE (GLOB_RECURSE OTHER_SOURCES "${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}/iTunesArtwork")
        SET_SOURCE_FILES_PROPERTIES(${OTHER_SOURCES}
                                      PROPERTIES
                                      MACOSX_PACKAGE_LOCATION Resources
        )
        LIST (APPEND ${NAME}_plaf_F_SOURCES "${OTHER_SOURCES}")
    ENDIF (IOS)

	IF (DEBUG_MESSAGES)
		MESSAGE("SOURCES: ${${NAME}_F_SOURCES}")
		MESSAGE("PLAF SOURCES: ${${NAME}_plaf_F_SOURCES}")
		MESSAGE("INCUDES: ${${NAME}_F_INCLUDE}")
	ENDIF (DEBUG_MESSAGES)
endmacro(list_files)

# ============================================================================
# KRALMain public interface
# ============================================================================

# marks a certain library for reuse. That means it will be copied back in the
# project after being compiled to be exported without being compiled next 
# time the project is regenerated
macro (mark_lib_for_reuse MLFR_NAME)
    if (ENABLE_REUSE_LIBS)
        set(${MLFR_NAME}_COPY_BACK True)
    endif()
endmacro()

macro (set_global_target_property property value)
    SET(GLOBAL_TARGET_PROPERTY "${GLOBAL_TARGET_PROPERTY};${property}[]${value}" CACHE INTERNAL "Global target properties" FORCE)
endmacro (set_global_target_property)

macro (apply_global_target_properties target)
    foreach (property ${GLOBAL_TARGET_PROPERTY}) 
        if (NOT "${property}" STREQUAL "") 
            string(REPLACE "[]" ";" pvpair "${property}")
            list(GET pvpair 0 property_name)
            list(GET pvpair 1 property_value)
            set_target_properties(${target} PROPERTIES ${property_name} ${property_value}) 
        endif (NOT "${property}" STREQUAL "")
    endforeach (property)
endmacro (apply_global_target_properties)

# Runs the android create project command
macro(generate_android_project)
    SET (ANDROID_APP_NAME ${ARGV0})
    SET (ANDROID_APP_PACKAGE ${ARGV1})
    SET (ANDROID_BINARY ${ARGV2})
	EXEC_PROGRAM ("\"${CMAKE_COMMAND}\" -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/../${PLATFORM}")
    EXEC_PROGRAM ("${ANDROID_BINARY} create project --target ${ANDROID_TARGET} --name ${ANDROID_APP_NAME} --path ${CMAKE_BINARY_DIR}/${PLATFORM} --activity ${ANDROID_APP_NAME}Activity --package ${ANDROID_APP_PACKAGE}")
endmacro(generate_android_project)

# This function is used by packages that don't have sources, only precompiled libs.
macro(export_library NAME)
	MESSAGE (STATUS "Exporting libraries for ${NAME}")
	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include")
    IF (NOT "${ARGV1}" STREQUAL "")
	    export_all_libraries (${NAME} ${ARGV1})
    ELSE (NOT "${ARGV1}" STREQUAL "")
	    export_all_libraries (${NAME})
    ENDIF (NOT "${ARGV1}" STREQUAL "")
	SET(EXPORTED_${NAME}_LIB ${${NAME}_LIBS} CACHE INTERNAL ${NAME} FORCE)
    append_to_runtime_files(${CMAKE_CURRENT_LIST_DIR}/runtime)	
endmacro(export_library)

# make_library is used in packaged modules to add a library
# the macro assumes a standard directory layout with include files
# placed in include and source files placed in source/common for
# independent source files and source/${PLATFORM} for platform
# dependent files.
macro(make_library NAME)
	message (STATUS "Creating library ${NAME}")
    if (${NAME}_COPY_BACK)
        if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/${PLATFORM}/")
            message (STATUS "Skip building ${NAME} because it was already built.")
            set (${NAME}_DONT_BUILD True CACHE INTERNAL "Don't build ${NAME}" FORCE)
        endif()
    endif()

    if (${NAME}_DONT_BUILD)
        export_library(${NAME})
    else ()
    	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include")
    	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include/${PLATFORM}")
    	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/platform_include/${PLATFORM}")
    	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/source/common")
    	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/source/${PLATFORM}")
    	
    	list_files (${NAME})
    
    	add_library (${NAME} ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
        add_dependencies(KRAL_END_OF_BUILD_TARGET ${NAME})
        append_to_runtime_files(${CMAKE_CURRENT_LIST_DIR}/runtime)	
        add_tests(${NAME} ${NAME})
    
    	SET(EXPORTED_${NAME}_LIB ${NAME} CACHE INTERNAL ${NAME} FORCE)
        apply_global_target_properties(${NAME})
        get_property(CURRENT_INCLUDES TARGET ${NAME} PROPERTY INCLUDE_DIRECTORIES)
        set_property(TARGET ${NAME} PROPERTY INCLUDE_DIRECTORIES "${CURRENT_INCLUDES};${MODULE_INCLUDE_DIRS};${CHILDREN_INCLUDE}") 
        if (${NAME}_COPY_BACK)
            get_target_property(LIB_PATH ${NAME} LOCATION_${CMAKE_BUILD_TYPE})
            string(REPLACE "$(EFFECTIVE_PLATFORM_NAME)" "" LIB_PATH ${LIB_PATH})
            message ("  ++ Will copy back ${LIB_PATH}")
            ADD_CUSTOM_COMMAND(TARGET ${NAME}
                POST_BUILD
                COMMAND "${CMAKE_COMMAND}" ARGS "-E" "make_directory" "${CMAKE_CURRENT_LIST_DIR}/lib/${PLATFORM}"
                COMMAND "${CMAKE_COMMAND}" ARGS "-E" "copy" "${LIB_PATH}" "${CMAKE_CURRENT_LIST_DIR}/lib/${PLATFORM}")
        endif()
    endif ()
endmacro(make_library)

# declare_target -> used only to expose the include files for a
# package
macro(declare_target NAME)
    declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include")
endmacro(declare_target)

#make_shared_library
macro(make_shared_library NAME)
	MESSAGE (STATUS "Creating shared library ${NAME}")
    set (EXPORTED_INCLUDES_${NAME} "")
	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include")
	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include/${PLATFORM}")
	
	list_files (${NAME})

	IF (IOS)
    	add_library (${NAME} MACOSX_BUNDLE SHARED ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
	ELSE (IOS)
    	add_library (${NAME} SHARED ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
    ENDIF (IOS)

    append_to_runtime_files(${CMAKE_CURRENT_LIST_DIR}/runtime)	
    add_tests(${NAME} ${NAME})
	SET(EXPORTED_${NAME}_LIB ${NAME} CACHE INTERNAL ${NAME} FORCE)
    apply_global_target_properties(${NAME})
endmacro(make_shared_library)

# This function is used to export all libraries contained in the libs folder
# of the package.
macro(export_all_libraries NAME)
	#todo find a way to abstract the extension of the library
	file (GLOB_RECURSE ${NAME}_LIBS "${CMAKE_CURRENT_LIST_DIR}/lib/${PLATFORM}${ARGV1}/*")

	STRING(REPLACE ";" " " ${NAME}_LIBS "${${NAME}_LIBS}")
	IF (DEFINED ${DEBUG_MESSAGES})
		MESSAGE("EXPORT LIB: ${${NAME}_LIBS}")
	ENDIF (DEFINED ${DEBUG_MESSAGES})
	SET(EXPORTED_${NAME}_LIB ${${NAME}_LIBS} CACHE INTERNAL ${NAME} FORCE)
endmacro(export_all_libraries)

macro(android_build_project_post_build NAME)
	if (ANDROID)
       IF (CMAKE_BUILD_TYPE STREQUAL "release")
            # for the release version we also sign the application
            ADD_CUSTOM_COMMAND (TARGET ${NAME}
                    POST_BUILD
                    COMMAND rm ARGS -rf ${CMAKE_BINARY_DIR}/${PLATFORM}/bin/*
                    COMMAND ${CMAKE_COMMAND} ARGS -E copy_directory ${LIB_DIR} ${CMAKE_BINARY_DIR}/${PLATFORM}/libs
                    COMMAND ${CMAKE_COMMAND} ARGS -E chdir ${CMAKE_BINARY_DIR}/${PLATFORM} ant${CMDEXT} ${CMAKE_BUILD_TYPE}
                ) 
       ELSE (CMAKE_BUILD_TYPE STREQUAL "release")
            ADD_CUSTOM_COMMAND (TARGET ${NAME}
                    POST_BUILD
                    COMMAND rm ARGS -rf ${CMAKE_BINARY_DIR}/${PLATFORM}/bin/*
                    COMMAND ${CMAKE_COMMAND} ARGS -E copy_directory ${LIB_DIR} ${CMAKE_BINARY_DIR}/${PLATFORM}/libs
                    COMMAND ${CMAKE_COMMAND} ARGS -E chdir ${CMAKE_BINARY_DIR}/${PLATFORM} ant${CMDEXT} ${CMAKE_BUILD_TYPE}
                )
        ENDIF (CMAKE_BUILD_TYPE STREQUAL "release")
	endif (ANDROID)
endmacro(android_build_project_post_build)

# build_module builds an entry point module, a module ment to be run. The directory
# layout is the same as in make_library.
# For win32 apps give as the second argument WIN32
# For iPhone MACOSX_BUNDLE
macro(build_module)
    declare_include_directory()
    SET (KRAL_MODULES_ADDED "" CACHE INTERNAL "Modules used by this project" FORCE)
    SET (NAME ${ARGV0})
    if (NOT "${ARGV1}" STREQUAL "" AND "${BUILD_OPTION}" STREQUAL "")
        set (BUILD_OPTION "${ARGV1}")
    endif ()
	MESSAGE (STATUS "Creating module ${NAME}")

    # Execute other macros
    foreach (RCATLP_COMMAND "${RCATLP_LIST}")
        string (LENGTH "${RCATLP_COMMAND}" LEN)
        if (NOT ${LEN} EQUAL 0)
            eval ("if (COMMAND ${RCATLP_COMMAND})
                        ${RCATLP_COMMAND}()
                        endif()")
        endif ()
    endforeach ()

	list_files (${NAME})
	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/include")

	if (ANDROID)
		add_library(${NAME} SHARED ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
        add_tests(${NAME} ${NAME})
	else (ANDROID)
		IF (DEFINED TESTS)
            if ("${DUMMY_CPP_FILE}" STREQUAL "")
			    #Create a dummy cpp file so the project can compile we will link this project against the lib so the game runs
			    set (DUMMY_CPP_FILE ${CMAKE_BINARY_DIR}/${NAME}Dummy.cpp)
			    FILE (WRITE  ${DUMMY_CPP_FILE} "// Dummy file to build this project, please check LIB for sources\n")
                FILE (APPEND ${DUMMY_CPP_FILE} "#ifdef _WIN32\n") # on iOS this fails under some configurations so disable it. MMGR works only on win anyways?
			    FILE (APPEND ${DUMMY_CPP_FILE} "#include <array>\n") #This is a mini hack to redefine delete due to mmgr.lib link compiler problems (see FF-465)
			    FILE (APPEND ${DUMMY_CPP_FILE} "#endif\n")
			    FILE (APPEND ${DUMMY_CPP_FILE} "#include <core/FFApplication.h>\n")
			    FILE (APPEND ${DUMMY_CPP_FILE} "void dummyFun() {\n")
			    FILE (APPEND ${DUMMY_CPP_FILE} "IApp::Create(NULL);\n")
			    FILE (APPEND ${DUMMY_CPP_FILE} "IApp::Release(NULL);\n}\n")
            endif ()

			add_executable (${NAME} ${BUILD_OPTION} ${DUMMY_CPP_FILE})
			add_library(${NAME}_LIB ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
            add_dependencies(KRAL_END_OF_BUILD_TARGET ${NAME} ${NAME}_LIB)
	        TARGET_LINK_LIBRARIES(${NAME} ${NAME}_LIB)
			add_tests(${NAME} ${NAME}_LIB)
			add_tests(${NAME} ${NAME}_LIB "integration_tests")
		ELSE (DEFINED TESTS)
			add_executable (${NAME} ${BUILD_OPTION} ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
		ENDIF (DEFINED TESTS)
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
	endif (ANDROID)
    append_to_runtime_files(${CMAKE_CURRENT_LIST_DIR}/runtime)	
    apply_global_target_properties(${NAME})
    set_property(TARGET ${NAME} PROPERTY INCLUDE_DIRECTORIES "${MODULE_INCLUDE_DIRS};${CHILDREN_INCLUDE}") 
    if (ANDROID)
    	string (TOLOWER ${CMAKE_BUILD_TYPE} CBT)
    	if ("${CBT}" STREQUAL "debug")
		generate_ndkgdb_config(${NAME})
	endif() 
    endif()    
    copy_runtime_files()
endmacro(build_module)

# export_module_dependency can export a module to be used by the module dependent on it
# this is for cases when you want to encapsulate dependencies and know that if for
# example someone uses you, for sure they will also need let's say the OpenGL package
# this is especially usefull for proxy packages that aim to reduce complexity in setting
# opengl, openal etc
macro(export_module_dependency PNAME NAME VERSION)
    message (STATUS "export_module_dependency(${PNAME} ${NAME} ${VERSION})")
    list (APPEND EXPORTED_MODULE_DEPS_${PNAME} "${NAME} ${VERSION})")    
    set (EXPORTED_MODULE_DEPS_${PNAME} "${EXPORTED_MODULE_DEPS_${PNAME}}" CACHE INTERNAL "Exported Modules" FORCE)
endmacro()

# add_module_dependency adds a directory and links the target module with the PNAME module.
macro(add_module_includes PNAME NAME VERSION)
	MESSAGE (STATUS "${PNAME}: Adding module includes ${NAME} [${VERSION}]")
	SET (PACKAGE_EXISTS False)
	FOREACH (package ${PACKAGES})
    	IF(EXISTS "${package}/${NAME}/${VERSION}")
    	    SET (PACKAGE_EXISTS True)
			declare_include_directory("${package}/${NAME}/${VERSION}/include")
			declare_include_directory("${package}/${NAME}/${VERSION}/include/${PLATFORM}")
	    ENDIF()
	ENDFOREACH (package)
	
	IF (NOT PACKAGE_EXISTS)
        MESSAGE(FATAL_ERROR "PACKAGES: ${PACKAGES}\n: Package ${NAME} doesn't exist in any package location!!!")
	ENDIF (NOT PACKAGE_EXISTS)
endmacro(add_module_includes)

# add_module_dependency adds a directory and links the target module with the PNAME module.
macro(add_module_dependency PNAME NAME VERSION)
	MESSAGE (STATUS "${PNAME}: Adding module dependency ${NAME} [${VERSION}]")
	SET (PACKAGE_EXISTS False)
	FOREACH (package ${PACKAGES})
    	IF(EXISTS "${package}/${NAME}/${VERSION}")
    	    SET (PACKAGE_EXISTS True)
	    	IF (DEFINED ${DEBUG_MESSAGES})
		    	MESSAGE ("MOD_ADDED_NAME: ${MOD_ADDED_${NAME}}")
		    ENDIF (DEFINED ${DEBUG_MESSAGES})

            LIST_CONTAINS(QRESULT ${NAME} ${KRAL_MODULES_ADDED})
    		IF (NOT QRESULT)
		    	LIST (APPEND KRAL_MODULES_ADDED ${NAME})
		    	SET (KRAL_MODULES_ADDED "${KRAL_MODULES_ADDED}" CACHE INTERNAL "Modules used by this project" FORCE)
	    		add_subdirectory(${package}/${NAME}/${VERSION} ${CMAKE_BINARY_DIR}/${NAME})
    		ENDIF (NOT QRESULT)
			
			declare_include_directory("${package}/${NAME}/${VERSION}/include")
			declare_include_directory("${package}/${NAME}/${VERSION}/include/${PLATFORM}")
            foreach (include_dir ${EXPORTED_INCLUDES_${NAME}})
                declare_include_directory(${include_dir})
            endforeach ()

            foreach (exported_framework ${EXPORTED_IOS_FRAMEWORKS_${NAME}})
                LIST (APPEND IOS_FRAMEWORKS_TO_LINK_${PNAME} ${exported_framework})
            endforeach ()
            foreach (exported_module ${EXPORTED_MODULE_DEPS_${NAME}})
                set (ECOMMAND "add_module_dependency(${PNAME} ${exported_module}")
                eval(${ECOMMAND})
            endforeach()
            
			IF (ANDROID)
				IF(EXISTS "${package}/${NAME}/${VERSION}/${JNI_SYMBOL_FILE_NAME}")
					INCLUDE("${package}/${NAME}/${VERSION}/${JNI_SYMBOL_FILE_NAME}")
				ENDIF(EXISTS "${package}/${NAME}/${VERSION}/${JNI_SYMBOL_FILE_NAME}")
			ENDIF (ANDROID)

            SET(LIBS_${PNAME} "${LIBS_${PNAME}} ${EXPORTED_${NAME}_LIB}" CACHE INTERNAL LIBS_${PNAME} FORCE)
	    ENDIF(EXISTS "${package}/${NAME}/${VERSION}")
	ENDFOREACH (package)
	
	IF (NOT PACKAGE_EXISTS)
        MESSAGE(FATAL_ERROR "PACKAGES: ${PACKAGES}\n: Package ${NAME} doesn't exist in any package location!!!")
	ENDIF (NOT PACKAGE_EXISTS)
endmacro(add_module_dependency)

macro(use_module_includes PNAME NAME VERSION)
	MESSAGE (STATUS "${PNAME}: Adding module includes ${NAME} [${VERSION}]")
	SET (PACKAGE_EXISTS False)
	FOREACH (package ${PACKAGES})
    	IF(EXISTS "${package}/${NAME}/${VERSION}")
    	    SET (PACKAGE_EXISTS True)			
			declare_include_directory("${package}/${NAME}/${VERSION}/include")
			declare_include_directory("${package}/${NAME}/${VERSION}/include/${PLATFORM}")
	    ENDIF(EXISTS "${package}/${NAME}/${VERSION}")
	ENDFOREACH (package)
	
	IF (NOT PACKAGE_EXISTS)
        MESSAGE(FATAL_ERROR ": Package ${PNAME} doesn't exist in any package location!!!")
	ENDIF (NOT PACKAGE_EXISTS)
endmacro(use_module_includes)

# link_module_dependencies is called after one adds some dependencies with
# add_module_dependency macro. The add_module_dependency macro configures the
# dependency and then to tell CMake to link the module with all its dependencies
# you call this macro.
macro(link_module_dependencies PNAME)
    if (NOT ("${LIBS_${PNAME}}" STREQUAL ""))
    STRING(STRIP ${LIBS_${PNAME}} LIBS_${PNAME})
    STRING(REPLACE " " ";" LIBLIST "${LIBS_${PNAME}}")
    foreach(library ${LIBLIST})
        if ("${ARGV1}" STREQUAL "")
            message (STATUS "  ~-> Linking ${PNAME} with library ${library}.")
            TARGET_LINK_LIBRARIES(${PNAME} ${library})
        else ()
            message (STATUS "  ~-> Linking ${ARGV1} with library ${library}.")
            TARGET_LINK_LIBRARIES("${ARGV1}" ${library})
        endif ()
    endforeach(library)
    

    foreach (exported_framework ${IOS_FRAMEWORKS_TO_LINK_${PNAME}})
        if ("${ARGV1}" STREQUAL "")
            eval ("link_ios_framework(${PNAME} ${exported_framework}")
        else ()
            eval ("link_ios_framework(${ARGV1} ${exported_framework}")
        endif ()
    endforeach ()
    if (TESTS)
        foreach (test ${PROJECT_TESTS_ADDED_${PNAME}})
            link_module_dependencies(${PNAME}Tests ${test})
        endforeach()
    endif ()
        SET(LIBS_${PNAME} "" CACHE INTERNAL "" FORCE)
    endif ()
endmacro ()

# macro to add tests for a particular project
macro(add_tests)
IF(DEFINED TESTS)
SET (AD_NAME ${ARGV0})
SET (LIB ${ARGV1})
IF (NOT "${ARGV2}" STREQUAL "")
	SET (TESTS_FOLDER ${ARGV2})
ELSE()
	SET (TESTS_FOLDER "tests")
ENDIF()

SET (TESTS_PROJECT "${AD_NAME}_${TESTS_FOLDER}")
IF(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}")
    MESSAGE(STATUS " Adding tests to ${TESTS_PROJECT}.")
	IF (DEBUG_MESSAGES)
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/include")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/source/common")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/source/${PLATFORM}")
	ENDIF (DEBUG_MESSAGES)

	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/include")

    SET (${AD_NAME}_F_INCLUDE "")
    SET (${AD_NAME}_F_SOURCES "")
    SET (${AD_NAME}_plaf_F_SOURCES "")
   
    foreach (EXTENSION ${INCLUDE_EXTENSIONS}) 
        file (GLOB_RECURSE F_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/include/${EXTENSION}")
	    list (APPEND ${AD_NAME}_F_INCLUDE ${F_INCLUDE})
    endforeach (EXTENSION)

    foreach (EXTENSION ${SOURCES_EXTENSIONS})
        FILE (GLOB_RECURSE F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/source/common/${EXTENSION}")
	    LIST (APPEND ${AD_NAME}_F_SOURCES ${F_SOURCES})
        FILE (GLOB_RECURSE plaf_F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/source/${PLATFORM}/${EXTENSION}")
	    LIST (APPEND ${AD_NAME}_plaf_F_SOURCES ${plaf_F_SOURCES})
    endforeach (EXTENSION)
    
	IF (DEBUG_MESSAGES)
		MESSAGE("SOURCES: ${${AD_NAME}_F_SOURCES}")
		MESSAGE("PLAF SOURCES: ${${AD_NAME}_plaf_F_SOURCES}")
	ENDIF (DEBUG_MESSAGES)

    if (WIN32)
        set (BUILD_OPTION "")
    endif ()
	
    ADD_MSVC_PRECOMPILED_HEADER("${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/include/${AD_NAME}TestsPrecompile.h" "${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}/source/common/${AD_NAME}TestsPrecompile.cpp" ${AD_NAME}_F_SOURCES)

 	add_executable (${TESTS_PROJECT} ${BUILD_OPTION} ${${AD_NAME}_F_INCLUDE} ${${AD_NAME}_F_SOURCES} ${${AD_NAME}_plaf_F_SOURCES})
    add_dependencies(KRAL_END_OF_BUILD_TARGET ${TESTS_PROJECT})
    if (ANDROID)
        get_target_property(TEST_PATH ${TESTS_PROJECT} LOCATION_${CMAKE_BUILD_TYPE})
        get_filename_component(FILENAME ${TEST_PATH} NAME_WE)
        message ("  #> Will copy tests for ${TESTS_PROJECT} from ${TEST_PATH} to ${CMAKE_BINARY_DIR}/android/libs/${ANDROID_ABI}/lib${FILENAME}.so.") 
        ADD_CUSTOM_COMMAND(TARGET ${TESTS_PROJECT}
            POST_BUILD
            COMMAND "${CMAKE_COMMAND}" ARGS "-E" "copy" "${TEST_PATH}" "${CMAKE_BINARY_DIR}/android/libs/${ANDROID_ABI}/lib${FILENAME}.so")
    endif ()

    if (LINUX OR WIN32 OR OSX)
        get_target_property(TEST_PATH ${TESTS_PROJECT} LOCATION_${CMAKE_BUILD_TYPE})
        string(REPLACE "$(EFFECTIVE_PLATFORM_NAME)" "" TEST_PATH ${TEST_PATH})
        list (APPEND ALL_TESTS "${TEST_PATH}")
        SET (ALL_TESTS "${ALL_TESTS}" CACHE INTERNAL "all running tests" FORCE)
        add_test(${TESTS_PROJECT} ${TEST_PATH})
        get_filename_component(THE_ACTUAL_TEST_PATH ${TEST_PATH} PATH)
        append_to_test_paths (${THE_ACTUAL_TEST_PATH})
    endif ()

    list (APPEND PROJECT_TESTS_ADDED_${AD_NAME} ${TESTS_PROJECT})    
    set (PROJECT_TESTS_ADDED_${AD_NAME} "${PROJECT_TESTS_ADDED_${AD_NAME}}" CACHE INTERNAL "Tests for ${AD_NAME}" FORCE)
    
    # TODO: fix this new testing stuff (added as separate task)
    #add_test(TEST_${AD_NAME} "${CMAKE_CURRENT_BINARY_DIR}/${TESTS_PROJECT}")
    TARGET_LINK_LIBRARIES (${TESTS_PROJECT} ${LIB}) 
ENDIF (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${TESTS_FOLDER}")
ENDIF (DEFINED TESTS)
endmacro(add_tests)

# macro to add tests for a particular project
macro(add_integration_tests)
SET (NAME ${ARGV0})
SET (LIB ${ARGV1})
IF(DEFINED INTEGRATION_TESTS)
IF(EXISTS "${CMAKE_CURRENT_LIST_DIR}/integration_tests")
    MESSAGE(STATUS " Adding integration tests to ${LIB}.")
	IF (DEBUG_MESSAGES)
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/integration_tests/include")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/integration_tests/source/common")
		MESSAGE("PATH: ${CMAKE_CURRENT_LIST_DIR}/integration_tests/source/${PLATFORM}")
	ENDIF (DEBUG_MESSAGES)

	declare_include_directory("${CMAKE_CURRENT_LIST_DIR}/integration_tests/include")

    SET (${NAME}_F_INCLUDE "")
    SET (${NAME}_F_SOURCES "")
	SET (${NAME}_plaf_F_SOURCES "")
	
	foreach (EXTENSION ${INCLUDE_EXTENSIONS}) 
        file (GLOB_RECURSE F_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/integration_tests/include/${EXTENSION}")
	    list (APPEND ${NAME}_F_INCLUDE ${F_INCLUDE})
    endforeach (EXTENSION)

    foreach (EXTENSION ${SOURCES_EXTENSIONS})
        FILE (GLOB_RECURSE F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/integration_tests/source/common/${EXTENSION}")
	    LIST (APPEND ${NAME}_F_SOURCES ${F_SOURCES})
        FILE (GLOB_RECURSE plaf_F_SOURCES "${CMAKE_CURRENT_LIST_DIR}/integration_tests/source/${PLATFORM}/${EXTENSION}")
	    LIST (APPEND ${NAME}_plaf_F_SOURCES ${plaf_F_SOURCES})
    endforeach (EXTENSION)
    
    FILE (GLOB_RECURSE XIB_SOURCES "${CMAKE_CURRENT_LIST_DIR}/integration_tests/source/${PLATFORM}/*.xib")
    SET_SOURCE_FILES_PROPERTIES(${XIB_SOURCES}
                                  PROPERTIES
                                  MACOSX_PACKAGE_LOCATION MacOSX
    )
    LIST (APPEND ${NAME}_plaf_F_SOURCES "${XIB_SOURCES}")

	IF (DEBUG_MESSAGES)
		MESSAGE("SOURCES: ${${NAME}_F_SOURCES}")
		MESSAGE("PLAF SOURCES: ${${NAME}_plaf_F_SOURCES}")
	ENDIF (DEBUG_MESSAGES)

	add_executable (${NAME}IntegrationTests ${BUILD_OPTION} ${${NAME}_F_INCLUDE} ${${NAME}_F_SOURCES} ${${NAME}_plaf_F_SOURCES})
    TARGET_LINK_LIBRARIES (${NAME}IntegrationTests ${LIB})
ENDIF(EXISTS "${CMAKE_CURRENT_LIST_DIR}/integration_tests")
ENDIF(DEFINED INTEGRATION_TESTS)
endmacro(add_integration_tests)

# export a non-standard include location to be used by the packages who
# depend on you
macro (export_includes EI_PROJ_NAME EI_INCLUDE_DIR)
    declare_include_directory(${EI_INCLUDE_DIR})
    list (APPEND EXPORTED_INCLUDES_${EI_PROJ_NAME} "${EI_INCLUDE_DIR}")
    set (EXPORTED_INCLUDES_${EI_PROJ_NAME} "${EXPORTED_INCLUDES_${EI_PROJ_NAME}}" CACHE INTERNAL "${EI_PROJ_NAME} exported includes" FORCE)
endmacro ()

# export a framework to be used by those who add this
# package as a dependency
macro (export_ios_framework)
    set (LIF_PROJ_NAME ${ARGV0})
    set (LIF_NAME ${ARGV1})
    message (STATUS "export_ios_framework ${LIF_PROJ_NAME} ${LIF_NAME}")
    list (APPEND EXPORTED_IOS_FRAMEWORKS_${LIF_PROJ_NAME} "${LIF_NAME} ${ARGV2})")    
    set (EXPORTED_IOS_FRAMEWORKS_${LIF_PROJ_NAME} "${EXPORTED_IOS_FRAMEWORKS_${LIF_PROJ_NAME}}" CACHE INTERNAL "Exported IOS Frameworks" FORCE)
endmacro()

# Used to find and link an IOS framework
macro(link_ios_framework)
    SET(LIF_PROJ_NAME ${ARGV0})
    SET(LIF_NAME ${ARGV1})
    FIND_LIBRARY (FRAMEWORK_${LIF_NAME}
                  NAMES ${LIF_NAME}
                  PATHS ${CMAKE_OSX_SYSROOT}/System/Library ~/Library ${ARGV2}
                  PATH_SUFFIXES Frameworks
                  NO_DEFAULT_PATH)
    MARK_AS_ADVANCED(FRAMEWORK_${LIF_NAME})
    IF (${FRAMEWORK_${LIF_NAME}} STREQUAL FRAMEWORK_${LIF_NAME}-NOTFOUND)
        MESSAGE (ERROR ": Framework ${LIF_NAME} not found")
    ELSE (${FRAMEWORK_${LIF_NAME}} STREQUAL FRAMEWORK_${LIF_NAME}-NOTFOUND)
        TARGET_LINK_LIBRARIES (${LIF_PROJ_NAME} ${FRAMEWORK_${LIF_NAME}})
        MESSAGE (STATUS "Framework ${LIF_NAME} found at ${FRAMEWORK_${LIF_NAME}}")
    ENDIF (${FRAMEWORK_${LIF_NAME}} STREQUAL FRAMEWORK_${LIF_NAME}-NOTFOUND)
endmacro(link_ios_framework)

macro(include_ios_framework)
    SET(NAME ${ARGV0})
    FIND_LIBRARY (FRAMEWORK_${NAME}
                  NAMES ${NAME}
                  PATHS ${CMAKE_OSX_SYSROOT}/System/Library ${ARGV1}
                  PATH_SUFFIXES Frameworks
                  NO_DEFAULT_PATH)
    MARK_AS_ADVANCED(FRAMEWORK_${NAME})
    IF (${FRAMEWORK_${NAME}} STREQUAL FRAMEWORK_${NAME}-NOTFOUND)
        MESSAGE (ERROR ": Framework ${NAME} not found")
    ELSE (${FRAMEWORK_${NAME}} STREQUAL FRAMEWORK_${NAME}-NOTFOUND)
	declare_include_directory("${FRAMEWORK_${NAME}}/Headers")
        MESSAGE (STATUS "Framework ${NAME} found at ${FRAMEWORK_${NAME}} and included.")
    ENDIF (${FRAMEWORK_${NAME}} STREQUAL FRAMEWORK_${NAME}-NOTFOUND)
endmacro(include_ios_framework)

# this macro declares includes localized per module
macro(declare_include_directory)
    set (DIR_NAME ${ARGV0})
    if (EXISTS "${DIR_NAME}")
        list(APPEND MODULE_INCLUDE_DIRS "${DIR_NAME}") 
        get_directory_property(hasParent PARENT_DIRECTORY)
        if (hasParent)
            set (CHILDREN_INCLUDE "${MODULE_INCLUDE_DIRS}" PARENT_SCOPE)
        endif()
    endif()
endmacro()
