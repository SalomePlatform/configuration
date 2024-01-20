############################################################################
#
# Detect MEDFile (med-fichier)
# --
# Defines the following variables
#   MEDFILE_INCLUDE_DIRS    - include directories
#   MEDFILE_LIBRARIES       - libraries to link against (C and Fortran)
#   MEDFILE_C_LIBRARIES     - C libraries only
#   MEDFILE_EXTRA_LIBRARIES - additional libraries
# --
#  The CMake (or environment) variable MEDFILE_ROOT_DIR can be set to
#  guide the detection and indicate a root directory to look into.
#
############################################################################
# Copyright (C) 2007-2024  CEA, EDF, OPEN CASCADE
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

MESSAGE(STATUS "Check for medfile ...")
# --

SET(MEDFILE_ROOT_DIR $ENV{MEDFILE_ROOT_DIR} CACHE PATH "Path to the MEDFile.")
IF(MEDFILE_ROOT_DIR)
  LIST(APPEND CMAKE_PREFIX_PATH "${MEDFILE_ROOT_DIR}")
ENDIF(MEDFILE_ROOT_DIR)
# --

# Detect headers directory
FIND_PATH(MEDFILE_INCLUDE_DIRS med.h)
# --

# Detect libraries
SET(MEDFILE_LIBRARIES)
SET(MEDFILE_C_LIBRARIES)
SET(MEDFILE_EXTRA_LIBRARIES)

FIND_LIBRARY(MEDFILE_LIBRARY_medC NAMES medC)
IF(MEDFILE_LIBRARY_medC)
  LIST(APPEND MEDFILE_C_LIBRARIES "${MEDFILE_LIBRARY_medC}")
  LIST(APPEND MEDFILE_LIBRARIES "${MEDFILE_LIBRARY_medC}")
ENDIF()
FIND_LIBRARY(MEDFILE_LIBRARY_medfwrap NAMES medfwrap)
IF(MEDFILE_LIBRARY_medfwrap)
  LIST(APPEND MEDFILE_C_LIBRARIES "${MEDFILE_LIBRARY_medfwrap}")
  LIST(APPEND MEDFILE_LIBRARIES "${MEDFILE_LIBRARY_medfwrap}")
ENDIF()
FIND_LIBRARY(MEDFILE_LIBRARY_med NAMES med)
IF(MEDFILE_LIBRARY_med)
  LIST(APPEND MEDFILE_LIBRARIES "${MEDFILE_LIBRARY_med}")
ENDIF()
FIND_LIBRARY(MEDFILE_LIBRARY_medimport NAMES medimport)
IF(MEDFILE_LIBRARY_medimport)
  LIST(APPEND MEDFILE_EXTRA_LIBRARIES "${MEDFILE_LIBRARY_medimport}")
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(MEDFile REQUIRED_VARS MEDFILE_INCLUDE_DIRS MEDFILE_LIBRARIES)
