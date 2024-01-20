# Copyright (C) 2013-2024  CEA, EDF, OPEN CASCADE
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

SALOME_FIND_PACKAGE_AND_DETECT_CONFLICTS(Netgen NETGEN_INCLUDE_DIRS 1)
MARK_AS_ADVANCED(NETGEN_INCLUDE_DIRS NETGEN_LIBRARIES)

# process case when netgen is found in config mode
IF(NOT NETGEN_DEFINITIONS AND NETGEN_COMPILE_DEFINITIONS)
  SET(NETGEN_DEFINITIONS)
  FOREACH(_ng_def ${NETGEN_COMPILE_DEFINITIONS})
    LIST(APPEND NETGEN_DEFINITIONS "-D${_ng_def}")
  ENDFOREACH()
ENDIF()
IF(NOT NETGEN_LIBRARIES)
  SET(NETGEN_LIBRARIES)
  FOREACH(_ng_lib nglib csg gen geom2d gprim interface la mesh occ stl ngcore)
    IF(TARGET ${_ng_lib})
      LIST(APPEND NETGEN_LIBRARIES "${_ng_lib}")
    ENDIF()
  ENDFOREACH()
ENDIF()
IF(NOT NETGEN_V5 AND NOT NETGEN_V6 AND NETGEN_VERSION_MAJOR)
  IF(NETGEN_VERSION_MAJOR VERSION_EQUAL 6)
    SET(NETGEN_V6 ON)
  ELSEIF(NETGEN_VERSION_MAJOR VERSION_EQUAL 5)
    SET(NETGEN_V5 ON)
  ENDIF()
ENDIF()
IF(NETGEN_INCLUDE_DIR AND NETGEN_INCLUDE_DIRS)
  LIST(APPEND NETGEN_INCLUDE_DIRS ${NETGEN_INCLUDE_DIR}/core)
ENDIF()
IF(NETGEN_INCLUDE_DIRS)
  LIST(REMOVE_DUPLICATES NETGEN_INCLUDE_DIRS)
ENDIF()

IF(NETGEN_V6)
  MESSAGE(STATUS "NETGEN V6 or newer found")
  SET(NETGEN_DEFINITIONS "${NETGEN_DEFINITIONS} -DNETGEN_V6")
ELSEIF(NETGEN_V5)
  MESSAGE(STATUS "NETGEN V5 found")
  SET(NETGEN_DEFINITIONS "${NETGEN_DEFINITIONS} -DNETGEN_V5")
ENDIF()

IF(NETGEN_FOUND)
  SALOME_ACCUMULATE_HEADERS(NETGEN_INCLUDE_DIRS)
  SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${NETGEN_LIBRARIES})
ENDIF()
