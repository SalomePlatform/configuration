# Copyright (C) 2017-2023  CEA, EDF, OPEN CASCADE
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

FIND_LIBRARY(PTSCOTCH_LIBRARIES ptscotch PATH_SUFFIXES openmpi/lib)
FIND_LIBRARY(PTSCOTCH_ERR_LIBRARIES ptscotcherr PATH_SUFFIXES openmpi/lib)
SET(PTSCOTCH_LIBRARIES ${PTSCOTCH_LIBRARIES} ${PTSCOTCH_ERR_LIBRARIES})
SET(SCOTCH_HEADER scotch.h)
IF(PTSCOTCH_USE_LONG)
  SET(PTSCOTCH_SUFFIXES scotch-long)
ELSEIF(PTSCOTCH_USE_INT64)
  SET(PTSCOTCH_SUFFIXES scotch-int64)
ELSEIF(PTSCOTCH_USE_INT32)
  SET(PTSCOTCH_SUFFIXES scotch-int32)
ENDIF()
FIND_PATH(PTSCOTCH_INCLUDE_DIRS ${SCOTCH_HEADER} PATH_SUFFIXES ${PTSCOTCH_SUFFIXES} scotch)

# Detect version of scotch/ptscotch

FILE(TO_NATIVE_PATH "${PTSCOTCH_INCLUDE_DIRS}/${SCOTCH_HEADER}" SCOTCH_HEADER_FILE)
FILE(READ ${SCOTCH_HEADER_FILE} SCOTCH_HEADER_FILE_CONTENT)

SET(ITER VERSION_MAJOR RELEASE_MINOR PATCHLEVEL_PATCH)
FOREACH(mmp ${ITER})
  STRING(REPLACE "_" ";" mmp_list ${mmp})
  LIST(GET mmp_list 0 mmp_search)
  LIST(GET mmp_list 1 mmp_client)
  STRING(REGEX MATCH "#define[\t ]+SCOTCH_${mmp_search}[\t ]+([0-9]+)" SCOTCH_MAJOR_VERSION_LINE "${SCOTCH_HEADER_FILE_CONTENT}")
  STRING(REGEX MATCH "([0-9]+)" SCOTCH_VERSION_${mmp_client} "${SCOTCH_MAJOR_VERSION_LINE}")
ENDFOREACH()

# End of detection of scotch/ptscotch

IF("${SCOTCH_VERSION_MAJOR}.${SCOTCH_VERSION_MINOR}.${SCOTCH_VERSION_PATCH}" VERSION_GREATER_EQUAL "6.0.0")
  # for ptscotch client of version >= 6.0.0 scotch.a library needs to be added
  FIND_LIBRARY(SCOTCH_LIBRARY scotch)
  LIST(APPEND PTSCOTCH_LIBRARIES ${SCOTCH_LIBRARY})
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PTScotch REQUIRED_VARS PTSCOTCH_INCLUDE_DIRS PTSCOTCH_LIBRARIES)
