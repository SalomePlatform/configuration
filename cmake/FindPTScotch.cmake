# Copyright (C) 2017-2019  CEA/DEN, EDF R&D, OPEN CASCADE
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
SET(PTSCOTCH_LIBRARIES ${PTSCOTCH_LIBRARIES} ${PTSCOTCH_ERR_LIBRARIES})
FIND_PATH(PTSCOTCH_INCLUDE_DIRS scotch.h PATH_SUFFIXES "/scotch")

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PTScotch REQUIRED_VARS PTSCOTCH_INCLUDE_DIRS PTSCOTCH_LIBRARIES)
