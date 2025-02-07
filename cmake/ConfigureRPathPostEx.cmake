# Copyright (C) 2025  CEA, EDF
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

# The only goal of this file is to run RPATH configuration on post install step.

# Define the path to the Python script (relative path)
set(PYTHON_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/configure_rpath_relative.py")

# Macro to add post install RPATH configuration
function(configure_rpath_post_install directories)
    # Ensure that the required variables are defined
    if(NOT DEFINED MAX_RPATH_LENGTH)
        message(FATAL_ERROR "MAX_RPATH_LENGTH is not defined")
    endif()

    # Convert the list of directories to absolute paths
    set(absolute_directories)
    foreach(directory IN LISTS directories)
        get_filename_component(absolute_directory "${directory}" ABSOLUTE BASE_DIR "${CMAKE_INSTALL_PREFIX}")
        list(APPEND absolute_directories "${absolute_directory}")
    endforeach()
    message(STATUS "Absolute directories: ${absolute_directories}")

    # Convert the list of directories to a space-separated string
    string(REPLACE ";" " " directories_str "${absolute_directories}")

    install(CODE "
        execute_process(
            COMMAND ${PYTHON_EXECUTABLE} ${PYTHON_SCRIPT} ${MAX_RPATH_LENGTH} \"${directories_str}\"
            RESULT_VARIABLE result
            OUTPUT_VARIABLE output
            ERROR_VARIABLE error
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(result)
            message(FATAL_ERROR \"Error configuring RPATH: \${error}\")
        else()
            message(STATUS \"RPATH configured successfully: \${output}\")
        endif()
    ")
endfunction()

set(OMNI_PATH_PYTHON_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/patch_omniidl_gen_py_package.py")

function(patch_omniidl_gen_py_package prefix subPackageName)
  install(CODE "

execute_process(
COMMAND ${PYTHON_EXECUTABLE} ${OMNI_PATH_PYTHON_SCRIPT} \"${prefix}\" \"${subPackageName}\"
RESULT_VARIABLE result
OUTPUT_VARIABLE output
ERROR_VARIABLE error
OUTPUT_STRIP_TRAILING_WHITESPACE )

if(result)
    message(FATAL_ERROR \"Error in patching omniorbpy: \${error}\")
else()
    message(STATUS \"omniorbpy packages sucessfully patched : \${output}\")
endif()
")
endfunction()

set(OMNI_PATH_PYTHON_SCRIPT_CLT "${CMAKE_CURRENT_LIST_DIR}/patch_omniidl_gen_py_package_clt.py")

function(patch_omniidl_gen_py_package_clt prefix)
  install(CODE "

execute_process(
COMMAND ${PYTHON_EXECUTABLE} ${OMNI_PATH_PYTHON_SCRIPT_CLT} \"${prefix}\"
RESULT_VARIABLE result
OUTPUT_VARIABLE output
ERROR_VARIABLE error
OUTPUT_STRIP_TRAILING_WHITESPACE )

if(result)
    message(FATAL_ERROR \"Error in patching omniorbpy: \${error}\")
else()
    message(STATUS \"omniorbpy packages sucessfully patched : \${output}\")
endif()
")
endfunction()

set(OMNI_PATH_PYTHON_SCRIPT_SERV_CLT "${CMAKE_CURRENT_LIST_DIR}/patch_omniidl_gen_py_package_serv_clt.py")

function(patch_omniidl_gen_py_package_serv_clt prefix subPackageName)
  install(CODE "

execute_process(
COMMAND ${PYTHON_EXECUTABLE} ${OMNI_PATH_PYTHON_SCRIPT_SERV_CLT} \"${prefix}\" \"${subPackageName}\"
RESULT_VARIABLE result
OUTPUT_VARIABLE output
ERROR_VARIABLE error
OUTPUT_STRIP_TRAILING_WHITESPACE )

if(result)
    message(FATAL_ERROR \"Error in patching omniorbpy: \${error}\")
else()
    message(STATUS \"omniorbpy packages sucessfully patched : \${output}\")
endif()
")
endfunction()