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
# Author: Gilles DAVID
#
# Looking for an installation of psutil, and if found the following variable is set
#   PSUTIL_VERSION     - Psutil version
#

IF(SALOMEPYTHONINTERP_FOUND)
  # Numpy
  EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c "import psutil ; import sys ; sys.stdout.write(psutil.__version__)" OUTPUT_VARIABLE PSUTIL_VERSION ERROR_QUIET )
  IF(PSUTIL_VERSION)
    SET(PSUTIL_FOUND TRUE)
  ENDIF(PSUTIL_VERSION)
  IF(PSUTIL_FOUND)
    MESSAGE(STATUS "Psutil found : Version ${PSUTIL_VERSION}")
  ELSE(PSUTIL_FOUND)
    MESSAGE(STATUS "Psutil not found.")
  ENDIF(PSUTIL_FOUND)
ENDIF()