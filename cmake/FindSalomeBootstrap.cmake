###########################################################################
# Copyright (C) 2007-2022  CEA/DEN, EDF R&D, OPEN CASCADE
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
