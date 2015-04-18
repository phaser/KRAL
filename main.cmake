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
    set(value 1)
    while (value LESS ${ARGC})
        message("ARG ${value}: ${ARGV${value}}")
        math (EXPR value "${value} + 1")
    endwhile()
endfunction()

function (library LNAME)
endfunction()
