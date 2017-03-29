# - Find NETGEN
# Sets the following variables:
#   NETGEN_INCLUDE_DIRS - path to the NETGEN include directories
#   NETGEN_LIBRARIES    - path to the NETGEN libraries to be linked against
#

#########################################################################
# Copyright (C) 2007-2016  CEA/DEN, EDF R&D, OPEN CASCADE
#
# Copyright (C) 2003-2007  OPEN CASCADE, EADS/CCR, LIP6, CEA/DEN,
# CEDRAT, EDF R&D, LEG, PRINCIPIA R&D, BUREAU VERITAS
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

# ------

IF(NOT Netgen_FIND_QUIETLY)
  MESSAGE(STATUS "Check for Netgen ...")
ENDIF()

# ------

SET(NETGEN_ROOT_DIR $ENV{NETGEN_ROOT_DIR})

IF(NETGEN_ROOT_DIR)
  LIST(APPEND CMAKE_PREFIX_PATH "${NETGEN_ROOT_DIR}")
ENDIF(NETGEN_ROOT_DIR)

# Windows specific stuff:
# Since netgen-5.3.1 uses zlib, try to detect it
IF(WIN32)
  IF(EXISTS ${NETGEN_ROOT_DIR}/cmake/FindZlib.cmake)
    FILE(TO_CMAKE_PATH ${NETGEN_ROOT_DIR}/cmake NETGEN_CMAKE_FILES)
    LIST(APPEND CMAKE_MODULE_PATH ${NETGEN_CMAKE_FILES})
    SET(ZLIB_ROOT_DIR $ENV{ZLIB_ROOT_DIR})
    INCLUDE(FindZlib)
  ENDIF()
ENDIF()

FIND_PATH(_netgen_base_inc_dir nglib.h)
SET(NETGEN_INCLUDE_DIRS ${_netgen_base_inc_dir} ${ZLIB_INCLUDE_DIRS})
FIND_PATH(_netgen_add_inc_dir occgeom.hpp HINTS ${_netgen_base_inc_dir} PATH_SUFFIXES share/netgen/include)
LIST(APPEND NETGEN_INCLUDE_DIRS ${_netgen_add_inc_dir})
LIST(REMOVE_DUPLICATES NETGEN_INCLUDE_DIRS)

FOREACH(_lib nglib csg gen geom2d gprim interface la mesh occ stl)

  FIND_LIBRARY(NETGEN_${_lib} NAMES ${_lib})
  IF(NETGEN_${_lib})
    LIST(APPEND NETGEN_LIBRARIES ${NETGEN_${_lib}})
  ENDIF()

ENDFOREACH()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(NETGEN REQUIRED_VARS NETGEN_INCLUDE_DIRS NETGEN_LIBRARIES)

INCLUDE(CheckCXXSourceCompiles)

IF(NETGEN_FOUND)

  # Detect NETGEN V5
  SET(CMAKE_REQUIRED_INCLUDES "${CMAKE_REQUIRED_INCLUDES} ${NETGEN_INCLUDE_DIRS}")
  SET(CMAKE_REQUIRED_LIBRARIES "${NETGEN_LIBRARIES}")
  CHECK_CXX_SOURCE_COMPILES("
    #include <meshing.hpp>
    int main()
    {
      netgen::Mesh* ngMesh = 0;
      ngMesh->CalcLocalH(1.0);
    }
" NETGEN_V5
    )

  IF(NOT Netgen_FIND_QUIETLY)
    MESSAGE(STATUS "Netgen library: ${NETGEN_LIBRARIES}")
  ENDIF()
  SET(NETGEN_DEFINITIONS "-DOCCGEOMETRY")

  IF(NETGEN_V5)
    MESSAGE(STATUS "NETGEN V5 or later found")
    SET(NETGEN_DEFINITIONS "${NETGEN_DEFINITIONS} -DNETGEN_V5")
  ENDIF(NETGEN_V5)

  #RNV:  currently on windows use netgen without thread support.
  #TODO: check support of the multithreading on windows
  IF(WIN32)
   SET(NETGEN_DEFINITIONS "${NETGEN_DEFINITIONS} -DNO_PARALLEL_THREADS")
  ENDIF(WIN32)
ENDIF()
