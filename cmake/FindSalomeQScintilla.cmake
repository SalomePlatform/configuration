# Copyright (C) 2013-2019  CEA/DEN, EDF R&D
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

# QScintilla detection for Salome
#
#  !! Please read the generic detection procedure in SalomeMacros.cmake !!
#
SALOME_FIND_PACKAGE_AND_DETECT_CONFLICTS(QScintilla QSCINTILLA_ROOT_DIR 0)
# IF(QScintilla_FOUND OR QSCINTILLA_FOUND)
#    MESSAGE(STATUS "QScintilla include dir is: ${QSCINTILLA_INCLUDE_DIRS}")
# ENDIF()   

IF(QSCINTILLA_FOUND)
  SALOME_ACCUMULATE_HEADERS(QSCINTILLA_INCLUDE_DIRS)
  SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${QSCINTILLA_LIBRARIES})
ENDIF()