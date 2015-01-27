cmake_minimum_required (VERSION 2.8)

macro (copy_target ${FROM} ${TO})
    set (PLATFORM_${TO}         "${PLATFORM_${FROM}}")
    set (PROJECT_TYPE_${TO}     "${PROJECT_TYPE_${FROM}}") 
    set (PROJECT_DIR_${TO}      "${PROJECT_DIR_${FROM}}")
    set (BUILD_DIR_${TO}        "${BUILD_DIR_${FROM}}}")
    set (CUSTOM_ARGS_${TO}      "${CUSTOM_ARGS_${FROM}}")
endmacro ()

