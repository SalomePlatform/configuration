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
# Author: Adrien Bruneton
#

# omniORB and detection for SALOME
#
#  !! Please read the generic detection procedure in SalomeMacros.cmake !!
#
SALOME_FIND_PACKAGE_AND_DETECT_CONFLICTS(OmniORB OMNIORB_INCLUDE_DIR 1)
#MARK_AS_ADVANCED()

IF(OMNIORB_FOUND) 
  SALOME_ACCUMULATE_HEADERS(OMNIORB_INCLUDE_DIR)
  SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${OMNIORB_LIBRARIES})
  SALOME_ACCUMULATE_ENVIRONMENT(PYTHONPATH ${OMNIORB_LIBRARIES}
                                           ${OMNIORB_PYTHONPATH})
  IF(WIN32) 
    GET_FILENAME_COMPONENT(_OMNI_BIN ${OMNIORB_IDL_COMPILER} PATH)
    SALOME_ACCUMULATE_ENVIRONMENT(LD_LIBRARY_PATH ${_OMNI_BIN})
  ENDIF()
ENDIF()