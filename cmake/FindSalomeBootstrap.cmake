###########################################################################
# Copyright (C) 2007-2026  CEA/DEN, EDF R&D, OPEN CASCADE
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

IF(NOT SalomeBootstrap_FIND_QUIETLY)
  MESSAGE(STATUS "Looking for Salome Bootstrap ...")
ENDIF()

SET(CMAKE_PREFIX_PATH "${SALOMEBOOTSTRAP_ROOT_DIR}/__RUN_SALOME__")
SALOME_FIND_PACKAGE(SalomeBootstrap SalomeBootstrap CONFIG)

IF(NOT SalomeBootstrap_FIND_QUIETLY)
  MESSAGE(STATUS "Found Salome Bootstrap: ${SALOMEBOOTSTRAP_ROOT_DIR}")
ENDIF()

IF (NOT SALOMEPYTHONINTERP_FOUND)
  MESSAGE(STATUS "Loading SALOME Python environment")
  FIND_PACKAGE(SalomePythonInterp REQUIRED)
ENDIF(NOT SALOMEPYTHONINTERP_FOUND)

SET(SALOMEBOOTSTRAP_ROOT_DIR "$ENV{SALOMEBOOTSTRAP_ROOT_DIR}")
IF(WIN32 AND NOT CYGWIN)
  SET(ENV{PYTHONPATH} "${SALOMEBOOTSTRAP_ROOT_DIR}\\__SALOME_BOOTSTRAP__;$ENV{PYTHONPATH}")
ELSE()
  SET(ENV{PYTHONPATH} "${SALOMEBOOTSTRAP_ROOT_DIR}/__SALOME_BOOTSTRAP__:$ENV{PYTHONPATH}")
ENDIF()
EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c "import SalomeOnDemandTK; print(SalomeOnDemandTK.__version__)" OUTPUT_VARIABLE SALOMEBOOTSTRAP_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)

IF(SALOMEBOOTSTRAP_VERSION)
  SET(SALOMEBOOTSTRAP_FOUND TRUE)
  MESSAGE(STATUS "Found Salome Bootstrap version ${SALOMEBOOTSTRAP_VERSION}")
ELSE()
  MESSAGE(FATAL_ERROR "Salome Bootstrap not found !!!")
ENDIF()
FIND_LIBRARY(SALOMEBOOTSTRAP_SALOMELocalTrace SALOMELocalTrace ${SALOMEBOOTSTRAP_ROOT_DIR}/lib/salome)
FIND_LIBRARY(SALOMEBOOTSTRAP_SALOMELocalTraceTest SALOMELocalTraceTest ${SALOMEBOOTSTRAP_ROOT_DIR}/__RUN_SALOME__/lib/salome)
FIND_LIBRARY(SALOMEBOOTSTRAP_SALOMEBasics SALOMEBasics ${SALOMEBOOTSTRAP_ROOT_DIR}/__RUN_SALOME__/lib/salome)
FIND_LIBRARY(SALOMEBOOTSTRAP_KERNELBasics KERNELBasics ${SALOMEBOOTSTRAP_ROOT_DIR}/__RUN_SALOME__/lib/salome)
FIND_LIBRARY(SALOMEBOOTSTRAP_SALOMEException SALOMEException ${SALOMEBOOTSTRAP_ROOT_DIR}/__RUN_SALOME__/lib/salome)
SET(SALOMEBOOTSTRAP_INCLUDE_DIRS ${SALOMEBOOTSTRAP_ROOT_DIR}/__RUN_SALOME__/include/salome)
