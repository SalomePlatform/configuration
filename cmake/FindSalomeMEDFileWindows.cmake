# Copyright (C) 2013-2026  CEA, EDF, OPEN CASCADE
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
# Author: Maud Salvoldi Gouge
#

# Medfile detection for Salome
#
SET(MED_INT_IS_LONG FALSE) # fallback value

# Find specifics MEDFile for Windows
FIND_LIBRARY(MED_FIFLE NAMES med HINS ${MEDFILE_WIN})
FIND_LIBRARY(MEDC_FILE NAMES medC HINS ${MEDFILE_WIN})
FIND_LIBRARY(MEDFWRAP_FILE NAMES medfwrap HINS ${MEDFILE_WIN})
SET(MEDFILE_LIBRARIES ${MED_FIFLE} ${MEDC_FILE} ${MEDFWRAP_FILE})
SET(MED_INT_IS_LONG TRUE)
   
      
SALOME_ACCUMULATE_HEADERS(MEDFILE_INCLUDE_DIRS)
SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${MEDFILE_LIBRARIES})

# Check size of med_int
SET(_med_int_cxx ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/check_med_int_size.cxx)
FILE(WRITE ${_med_int_cxx}
      "#include <med.h>\n#include <stdio.h>\nint main(){printf(\"%d\", sizeof(med_int)); return 0;}")
TRY_RUN(_med_int_run_result _med_int_compile_results
     ${CMAKE_BINARY_DIR} ${_med_int_cxx}
     CMAKE_FLAGS "-DINCLUDE_DIRECTORIES:STRING=${MEDFILE_INCLUDE_DIRS};${HDF5_INCLUDE_DIR}"
	  LINK_LIBRARIES ${MEDC_FILE} ${HDF5_LIBRARIES}
	  RUN_OUTPUT_VARIABLE _med_int_output)
IF(_med_int_compile_results)
   SET(MED_INT_SIZE ${_med_int_output})
ELSE()
   SET(MED_INT_SIZE UNKNOWN)
ENDIF()
IF(MED_INT_SIZE EQUAL 8)
   SET(MED_INT_IS_LONG TRUE)
ELSE()
   SET(MED_INT_IS_LONG FALSE)
ENDIF()
MESSAGE(STATUS "MEDFile windows: size of med_int is ${MED_INT_SIZE}")
UNSET(_med_int_cxx)
UNSET(_med_int_run_result)
UNSET(_med_int_compile_results)
UNSET(_med_int_output)

