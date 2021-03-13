# Copyright (C) 2013-2020  CEA/DEN, EDF R&D, OPEN CASCADE
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

# - Find sip
# Sets the following variables:
#   SIP_VERSION           - version of SIP
#   SIP_MODULE_EXECUTABLE - path to the sip-module executable (sip >= 5)
#   SIP_EXECUTABLE        - path to the sip executable
#   SIP_INCLUDE_DIR       - path to the sip headers (sip < 5)
#   SIP_PYTHONPATH        - path to the sip Python packages
#
#  The header sip.h is looked for.
#  The binary 'sip' is looked for.
#

IF(NOT SIP_FIND_QUIETLY)
  MESSAGE(STATUS "Looking for SIP ...")
ENDIF()

# Find executable
FIND_PROGRAM(SIP_EXECUTABLE
             NAMES sip5 sip4 sip
             HINTS $ENV{SIP_ROOT_DIR}
             PATH_SUFFIXES bin)

IF(SIP_EXECUTABLE)
  # Set path to sip's Python module
  GET_FILENAME_COMPONENT(SIP_PYTHONPATH "${SIP_EXECUTABLE}" PATH) # <root>/bin/sip -> <root>/bin
  GET_FILENAME_COMPONENT(SIP_PYTHONPATH "${SIP_PYTHONPATH}" PATH) # <root>/bin -> <root>
  SET(SIP_PYTHONPATH "${SIP_PYTHONPATH}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages")

  # Detect sip version
  EXECUTE_PROCESS(COMMAND ${SIP_EXECUTABLE} "-V"
                  OUTPUT_VARIABLE SIP_VERSION
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  ERROR_QUIET)
ENDIF()

# Find sip-module executable (only for version >= 5)
IF(SIP_VERSION AND SIP_VERSION VERSION_GREATER_EQUAL "5")
  FIND_PROGRAM(SIP_MODULE_EXECUTABLE
               NAMES sip-module
               HINTS $ENV{SIP_ROOT_DIR}
               PATH_SUFFIXES bin)
ENDIF()

# Find header file (only for version < 5)
IF(NOT SIP_VERSION OR SIP_VERSION VERSION_LESS "5")
  FIND_PATH(SIP_INCLUDE_DIR
            NAMES sip.h
            HINTS $ENV{SIP_ROOT_DIR}
            PATH_SUFFIXES include python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}m)
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
IF(SIP_VERSION AND SIP_VERSION VERSION_GREATER_EQUAL "5")
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(SIP REQUIRED_VARS SIP_EXECUTABLE SIP_MODULE_EXECUTABLE SIP_PYTHONPATH)
ELSE()
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(SIP REQUIRED_VARS SIP_INCLUDE_DIR SIP_EXECUTABLE SIP_PYTHONPATH)
ENDIF()
