# Copyright (C) 2013-2016  CEA/DEN, EDF R&D, OPEN CASCADE
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

# - Find Qwt installation
# Sets the following variables:
#   QWT_LIBRARY         - path to the Qwt library
#   QWT_INCLUDE_DIR     - path to the Qwt headers
#
#  The header qwt_plot.h is looked for.
#  The libraries 
#      qwt-qt<qt_version>, qwt
#  are looked for.
#  Here, <qt_version> is a Qt version being used.
#  For this to work correctly, Qt detection procedure must preceed Qwt one.
#

IF(NOT Qwt_FIND_QUIETLY)
    MESSAGE(STATUS "Looking for Qwt ...")
ENDIF()

IF(QT_VERSION)
  STRING(REPLACE "." ";" _qwt_qt_version_list ${QT_VERSION})
  LIST(GET _qwt_qt_version_list 0 _qwt_qt_version_major)
ELSE()
  # by default use version 5 of Qt
  SET(_qwt_qt_version_major "5")
ENDIF()

FIND_PATH(QWT_INCLUDE_DIR qwt_plot.h PATH_SUFFIXES qwt-qt${_qwt_qt_version_major})
FIND_PATH(QWT_INCLUDE_DIR qwt_plot.h PATH_SUFFIXES qwt)

IF(WIN32)
  SET(QWT_DEFINITIONS "-DQWT_DLL")
  
  IF(CMAKE_BUILD_TYPE STREQUAL Debug)
    FIND_LIBRARY(QWT_LIBRARY qwtd)
  ENDIF()
  FIND_LIBRARY(QWT_LIBRARY qwt)
ELSE(WIN32)
  # Give precedence to qwt-qt<version> library.
  # Note: on some platforms there can be several native qwt libraries linked against different 
  #       versions of Qt; for example /usr/lib/libqwt.so for qwt linked against Qt 3 and
  #       /usr/lib/libqwt-qt4.so for qwt linked against Qt 4, etc.
  #       We need only qwt library built with version of Qt we use, so we search libqwt-qt<version>,
  #       then libqwt library; first ignoring system paths, then including system paths.
  FIND_LIBRARY(QWT_LIBRARY qwt-qt${_qwt_qt_version_major} PATH_SUFFIXES lib lib64 PATHS "${QWT_ROOT_DIR}" NO_DEFAULT_PATH)
  FIND_LIBRARY(QWT_LIBRARY qwt-qt${_qwt_qt_version_major} PATHS "${QWT_ROOT_DIR}" NO_DEFAULT_PATH)
  FIND_LIBRARY(QWT_LIBRARY qwt PATH_SUFFIXES lib lib64 PATHS "${QWT_ROOT_DIR}" NO_DEFAULT_PATH)
  FIND_LIBRARY(QWT_LIBRARY qwt PATHS "${QWT_ROOT_DIR}" NO_DEFAULT_PATH)
  FIND_LIBRARY(QWT_LIBRARY qwt-qt${_qwt_qt_version_major} PATH_SUFFIXES lib lib64)
  FIND_LIBRARY(QWT_LIBRARY qwt-qt${_qwt_qt_version_major})
  FIND_LIBRARY(QWT_LIBRARY qwt PATH_SUFFIXES lib lib64)
  FIND_LIBRARY(QWT_LIBRARY qwt)
ENDIF(WIN32)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Qwt REQUIRED_VARS QWT_INCLUDE_DIR QWT_LIBRARY)

