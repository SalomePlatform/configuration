# Copyright (C) 2013-2016  CEA/DEN, EDF R&D, OPEN CASCADE
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
# Author: Adrien Bruneton
#

# Python libraries detection for SALOME
#
#  !! Please read the generic detection procedure in SalomeMacros.cmake !!
#

# Use the PYTHON_ROOT_DIR if PYTHONLIBS_ROOT_DIR is not defined:
SET(PYTHON_ROOT_DIR "$ENV{PYTHON_ROOT_DIR}" CACHE PATH "Path to the Python installation (libs+interpreter)")
IF(EXISTS "${PYTHON_ROOT_DIR}" AND (NOT PYTHONLIBS_ROOT_DIR))
  MESSAGE(STATUS "Setting PYTHONLIBS_ROOT_DIR to: ${PYTHON_ROOT_DIR}")
  SET(PYTHONLIBS_ROOT_DIR "${PYTHON_ROOT_DIR}" CACHE PATH "Path to PythonLibs directory")
ENDIF()
IF (SALOMEPYTHONINTERP_FOUND AND NOT "${PYTHON_VERSION_STRING}" STREQUAL "") 
   # Trying to search libraries with same version as an interpreter version
   SET(PythonLibs_FIND_VERSION ${PYTHON_VERSION_STRING})
   SET(PythonLibs_FIND_VERSION_MAJOR ${PYTHON_VERSION_MAJOR})
ENDIF()
IF(WIN32)
  set(CMAKE_LIBRARY_PATH "${PYTHON_ROOT_DIR}/libs")
ENDIF()
IF(APPLE)
  FIND_PROGRAM(PYTHON_CONFIG_EXECUTABLE python-config)
  IF(NOT PYTHON_CONFIG_EXECUTABLE)
    MESSAGE(SEND_ERROR "python-config executable not found, but python is required.")
  ENDIF()
  EXECUTE_PROCESS(COMMAND ${PYTHON_CONFIG_EXECUTABLE} --prefix OUTPUT_VARIABLE python_prefix OUTPUT_STRIP_TRAILING_WHITESPACE)
  SET(PYTHON_INCLUDE_DIR ${python_prefix}/include/python2.7)
  SET(PYTHON_LIBRARY ${python_prefix}/lib/libpython2.7${CMAKE_SHARED_LIBRARY_SUFFIX})
  SET(PYTHON_MAJOR_VERSION 2)
  SET(PYTHON_MINOR_VERSION 7)
  MESSAGE(STATUS "Python libraries: ${PYTHON_LIBRARY}")
  MESSAGE(STATUS "Python include dir: ${PYTHON_INCLUDE_DIR}")
ENDIF()

SALOME_FIND_PACKAGE_AND_DETECT_CONFLICTS(PythonLibs PYTHON_INCLUDE_DIR 2)

IF(SALOMEPYTHONLIBS_FOUND) 
  SALOME_ACCUMULATE_HEADERS(PYTHON_INCLUDE_DIR)
  SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${PYTHON_LIBRARIES})
ENDIF()

## Specifics -- check matching version with Interpreter if already detected:
IF (SALOMEPYTHONLIBS_FOUND AND SALOMEPYTHONINTERP_FOUND)
  # Now ensure versions are matching
  SALOME_EXTRACT_VERSION(${PYTHONLIBS_VERSION_STRING} maj_lib min_lib patch_lib)
  SALOME_EXTRACT_VERSION(${PYTHON_VERSION_STRING} maj_inter min_inter patch_inter)
  IF("${maj_lib}.${min_lib}.${patch_lib}" STREQUAL "${maj_inter}.${min_inter}.${patch_inter}")
    MESSAGE(STATUS "Python libs and interpreter versions are matching: ${PYTHONLIBS_VERSION_STRING}")
  ELSE()
    MESSAGE(FATAL_ERROR "Python libs and interpreter versions are NOT matching: ${PYTHONLIBS_VERSION_STRING} vs ${PYTHON_VERSION_STRING}")
  ENDIF()
ENDIF()
