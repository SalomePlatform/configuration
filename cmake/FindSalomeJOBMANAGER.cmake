# Copyright (C) 2007-2021  CEA/DEN, EDF R&D, OPEN CASCADE
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

IF(NOT SalomeJOBMANAGER_FIND_QUIETLY)
  MESSAGE(STATUS "Looking for Salome JOBMANAGER ...")
ENDIF()

SET(CMAKE_PREFIX_PATH "${JOBMANAGER_ROOT_DIR}")

SALOME_FIND_PACKAGE(SalomeJOBMANAGER SalomeJOBMANAGER CONFIG)

IF(NOT SalomeJOBMANAGER_FIND_QUIETLY)
  MESSAGE(STATUS "Found Salome JOBMANAGER: ${JOBMANAGER_ROOT_DIR}")
ENDIF()

FOREACH(_res ${SalomeJOBMANAGER_EXTRA_ENV})
  SALOME_ACCUMULATE_ENVIRONMENT(${_res} "${SalomeJOBMANAGER_EXTRA_ENV_${_res}}")
ENDFOREACH()