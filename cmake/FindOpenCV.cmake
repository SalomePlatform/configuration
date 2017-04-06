#########################################################################
# Copyright (C) 2007-2016  CEA/DEN, EDF R&D, OPEN CASCADE
#
# Copyright (C) 2003-2007  OPEN CASCADE, EADS/CCR, LIP6, CEA/DEN,
# CEDRAT, EDF R&D, LEG, PRINCIPIA R&D, BUREAU VERITAS
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

# - Find OpenCV
# Sets the following variables:
#   OpenCV_FOUND        - found flag
#   OpenCV_INCLUDE_DIRS - path to the OpenCV include directories
#   OpenCV_LIBS         - path to the OpenCV libraries to be linked against
#

IF(NOT OpenCV_FIND_QUIETLY)
  MESSAGE(STATUS "Check for OpenCV ...")
ENDIF()

FIND_PATH(OpenCV_INCLUDE_DIRS cv.h PATH_SUFFIXES opencv)
IF(OpenCV_INCLUDE_DIRS)
  SET(_OpenCV_INCLUDE_DIR_TMP "${OpenCV_INCLUDE_DIRS}/../opencv2")
  GET_FILENAME_COMPONENT(_OpenCV_INCLUDE_DIR_TMP "${_OpenCV_INCLUDE_DIR_TMP}" REALPATH)
  LIST(APPEND OpenCV_INCLUDE_DIRS ${_OpenCV_INCLUDE_DIR_TMP})
ENDIF()

SET(OpenCV_LIB_COMPONENTS videostab;video;ts;superres;stitching;photo;ocl;objdetect;ml;legacy;imgproc;highgui;gpu;flann;features2d)

FOREACH(_compo ${OpenCV_LIB_COMPONENTS})
  FIND_LIBRARY(OpenCV_${_compo} opencv_${_compo})
  IF(OpenCV_${_compo})
    LIST(APPEND OpenCV_LIBRARIES ${OpenCV_${_compo}})
  ENDIF()
ENDFOREACH()
IF(OpenCV_LIBRARIES AND OpenCV_INCLUDE_DIRS)
  IF(NOT OpenCV_LIBS)
    SET(OpenCV_LIBS ${OpenCV_LIBRARIES})
  ENDIF()
  SET(OpenCV_FOUND 1)  

  IF(NOT OpenCV_FIND_QUIETLY)
    MESSAGE("OpenCV found !")
  ENDIF()
ELSE()
  IF(NOT OpenCV_FIND_QUIETLY)
    MESSAGE("Could not find OpenCV ...")
  ENDIF()
ENDIF()
