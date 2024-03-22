# - Find GMSH
# Sets the following variables:
#   GMSH_INCLUDE_DIRS - path to the GMSH include directory
#   GMSH_LIBRARIES    - path to the GMSH libraries to be linked against
#

#########################################################################
# Copyright (C) 2012-2024  CEA, EDF, OPEN CASCADE
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
# See http://www.alneos.com/ or email : contact@alneos.fr
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

# ------

MESSAGE(STATUS "Check for GMSH ...")

# ------

SET(GMSH_ROOT_DIR $ENV{GMSH_ROOT_DIR} CACHE PATH "Path to the GMSH.")

IF(GMSH_ROOT_DIR)
 LIST(APPEND CMAKE_PREFIX_PATH "${GMSH_ROOT_DIR}")
ENDIF(GMSH_ROOT_DIR)

FIND_PATH(GMSH_INCLUDE_DIRS NAMES GmshVersion.h PATH_SUFFIXES gmsh)
IF(GMSH_INCLUDE_DIRS)
  GET_FILENAME_COMPONENT(GMSH_INCLUDE_DIRS_UP ${GMSH_INCLUDE_DIRS} DIRECTORY)
  LIST(APPEND GMSH_INCLUDE_DIRS "${GMSH_INCLUDE_DIRS_UP}")
ENDIF()

IF(WIN32 AND CMAKE_BUILD_TYPE STREQUAL Debug)
  FIND_LIBRARY(GMSH_LIBRARIES NAMES gmshd)
ELSE()
  FIND_LIBRARY(GMSH_LIBRARIES NAMES Gmsh gmsh gmshd)
ENDIF()
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(GMSH REQUIRED_VARS GMSH_INCLUDE_DIRS GMSH_LIBRARIES)
