# Copyright (C) 2017-2021  CEA/DEN, EDF R&D, OPEN CASCADE
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

MESSAGE(STATUS "Check for PTscotch ...")

SET(PTSCOTCH_ROOT_DIR $ENV{PTSCOTCH_ROOT_DIR} CACHE PATH "Path to the PTSCOTCH.")
IF(PTSCOTCH_ROOT_DIR)
  LIST(APPEND CMAKE_PREFIX_PATH "${PTSCOTCH_ROOT_DIR}")
ENDIF(PTSCOTCH_ROOT_DIR)

FIND_LIBRARY(PTSCOTCH_LIBRARIES ptscotch)
FIND_LIBRARY(PTSCOTCH_ERR_LIBRARIES ptscotcherr)
set(PTSCOTCH_LIBRARIES ${PTSCOTCH_LIBRARIES} ${PTSCOTCH_ERR_LIBRARIES})
set(SCOTCH_HEADER scotch.h)
FIND_PATH(PTSCOTCH_INCLUDE_DIRS ${SCOTCH_HEADER} PATH_SUFFIXES "/scotch")

# Detect version of scotch/ptscotch

file(TO_NATIVE_PATH "${PTSCOTCH_INCLUDE_DIRS}/${SCOTCH_HEADER}" SCOTCH_HEADER_FILE)
file(READ ${SCOTCH_HEADER_FILE} SCOTCH_HEADER_FILE_CONTENT)

set(ITER VERSION_MAJOR RELEASE_MINOR PATCHLEVEL_PATCH)
foreach(mmp ${ITER})
  string(REPLACE "_" ";" mmp_list ${mmp})
  list(GET mmp_list 0 mmp_search)
  list(GET mmp_list 1 mmp_client)
  string( REGEX MATCH "#define[\t ]+SCOTCH_${mmp_search}[\t ]+([0-9]+)" SCOTCH_MAJOR_VERSION_LINE "${SCOTCH_HEADER_FILE_CONTENT}" )
  string( REGEX MATCH "([0-9]+)" SCOTCH_VERSION_${mmp_client} "${SCOTCH_MAJOR_VERSION_LINE}" )
endforeach()

# End of detection of scotch/ptscotch

if("${SCOTCH_VERSION_MAJOR}.${SCOTCH_VERSION_MINOR}.${SCOTCH_VERSION_PATCH}" VERSION_GREATER_EQUAL "6.0.0")
  # for ptscotch client of version >= 6.0.0 scotch.a library needs to be added
  find_library(SCOTCH_LIBRARY scotch)
  list(APPEND PTSCOTCH_LIBRARIES ${SCOTCH_LIBRARY})
endif()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PTScotch REQUIRED_VARS PTSCOTCH_INCLUDE_DIRS PTSCOTCH_LIBRARIES)
