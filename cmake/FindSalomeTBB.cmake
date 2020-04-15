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

IF(NOT DEFINED MACHINE_IS_64)
  MESSAGE(FATAL_ERROR "Developer error -> SalomeSetupPlatform macros should be inclided before find_package(SalomeTBB) !")
ENDIF()

SALOME_FIND_PACKAGE_AND_DETECT_CONFLICTS(TBB TBB_INCLUDE_DIRS 1)

IF(TBB_INCLUDE_DIRS AND TBB_LIBRARIES)
  # No config mode 
  MARK_AS_ADVANCED(TBB_INCLUDE_DIRS TBB_LIBRARIES)
ELSEIF(TBB_IMPORTED_TARGETS)
  #Config mode
  SET(TBB_LIBRARIES ${TBB_IMPORTED_TARGETS})
ELSE()
  MESSAGE(FATAL_ERROR "Can't find tbb installation!")
ENDIF()

IF(TBB_FOUND) 
  IF(TBB_INCLUDE_DIRS AND TBB_LIBRARIES)
    # No config mode 
    SALOME_ACCUMULATE_HEADERS(TBB_INCLUDE_DIRS)
    SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${TBB_LIBRARIES})
  ELSEIF(TBB_IMPORTED_TARGETS)
    #Config mode
    LIST(GET TBB_IMPORTED_TARGETS 0 _first_tbb_target)

    # 1. Get TBB libraries dir
    GET_TARGET_PROPERTY(_tbb_f_lib ${_first_tbb_target} IMPORTED_LOCATION_RELASE)
    IF(NOT ${_tbb_f_lib})
      GET_TARGET_PROPERTY(_tbb_f_lib ${_first_tbb_target} IMPORTED_LOCATION_DEBUG)    
    ENDIF()
    GET_FILENAME_COMPONENT(_tbb_lib ${_tbb_f_lib} DIRECTORY)
    GET_FILENAME_COMPONENT(_tbb_lib ${_tbb_lib} ABSOLUTE)

    # 2. Get TBB includes dir
    GET_TARGET_PROPERTY(_tbb_inc ${_first_tbb_target} INTERFACE_INCLUDE_DIRECTORIES)
    GET_FILENAME_COMPONENT(_tbb_inc ${_tbb_inc} ABSOLUTE)

    SALOME_ACCUMULATE_HEADERS(_tbb_inc)
    SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${_tbb_lib})
  ENDIF()
ENDIF()