# Copyright (C) 2026  CEA, EDF, OPEN CASCADE
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
#
# Backend-neutral abstraction layer for generating Qt/Python artefacts.
#
# This module is intentionally "include-only": it only defines macros.
# Call SALOME_SETUP_QT_PYTHON_BINDINGS() explicitly to select a backend
# and perform the required discovery.

IF(NOT DEFINED _SALOME_QT_PYTHON_BINDINGS_INCLUDED)
  SET(_SALOME_QT_PYTHON_BINDINGS_INCLUDED 1)

  # Ensure SalomeMacros are available for FindSalome* modules.
  INCLUDE(SalomeMacros)

  # Global variable storing active backend once setup macro is called.
  SET(SALOME_QT_PYTHON_BINDINGS_BACKEND "" CACHE STRING "Qt/Python bindings backend: PYSIDE2 or PYQT5")
  MARK_AS_ADVANCED(SALOME_QT_PYTHON_BINDINGS_BACKEND)

MACRO(_SALOME_QT_PYTHON_BINDINGS_GET_BACKEND_OR_DEFAULT _out_backend)
  SET(_backend "")
  SET(_args ${ARGV})
  LIST(FIND _args "BACKEND" _backend_idx)
  IF(_backend_idx EQUAL -1)
    # No explicit BACKEND keyword:
    # 1) if a backend is already cached, keep it
    # 2) otherwise derive from SALOME_USE_PYSIDE
    IF(SALOME_QT_PYTHON_BINDINGS_BACKEND)
      SET(_backend "${SALOME_QT_PYTHON_BINDINGS_BACKEND}")
    ELSEIF(DEFINED SALOME_USE_PYSIDE AND SALOME_USE_PYSIDE)
      SET(_backend "PYSIDE2")
    ELSE()
      SET(_backend "PYQT5")
    ENDIF()
    STRING(TOUPPER "${_backend}" _backend)
    IF(NOT _backend STREQUAL "PYSIDE2" AND NOT _backend STREQUAL "PYQT5")
      MESSAGE(FATAL_ERROR "SALOME_SETUP_QT_PYTHON_BINDINGS(): Cached backend '${_backend}' is invalid (expected PYSIDE2 or PYQT5).")
    ENDIF()
  ELSE()
    MATH(EXPR _backend_val_idx "${_backend_idx} + 1")
    LIST(LENGTH _args _args_len)
    IF(_backend_val_idx GREATER_EQUAL _args_len)
      MESSAGE(FATAL_ERROR "SALOME_SETUP_QT_PYTHON_BINDINGS(): BACKEND value is missing (expected PYSIDE2 or PYQT5).")
    ENDIF()
    LIST(GET _args ${_backend_val_idx} _backend)
    STRING(TOUPPER "${_backend}" _backend)
    IF(NOT _backend STREQUAL "PYSIDE2" AND NOT _backend STREQUAL "PYQT5")
      MESSAGE(FATAL_ERROR "SALOME_SETUP_QT_PYTHON_BINDINGS(): Unknown BACKEND='${_backend}' (expected PYSIDE2 or PYQT5).")
    ENDIF()
  ENDIF()
  SET(${_out_backend} "${_backend}")
ENDMACRO()

####################################################################
# SALOME_SETUP_QT_PYTHON_BINDINGS
#
# Performs discovery of the selected backend.
#
# USAGE:
#   SALOME_SETUP_QT_PYTHON_BINDINGS(BACKEND PYSIDE2)
#   SALOME_SETUP_QT_PYTHON_BINDINGS(BACKEND PYQT5)
#   SALOME_SETUP_QT_PYTHON_BINDINGS()  # auto-selects using SALOME_USE_PYSIDE (default: PYQT5)
####################################################################
MACRO(SALOME_SETUP_QT_PYTHON_BINDINGS)
  _SALOME_QT_PYTHON_BINDINGS_GET_BACKEND_OR_DEFAULT(_backend ${ARGV})
  SET(SALOME_QT_PYTHON_BINDINGS_BACKEND "${_backend}" CACHE STRING "Qt/Python bindings backend: PYSIDE2 or PYQT5" FORCE)

  IF(SALOME_QT_PYTHON_BINDINGS_BACKEND STREQUAL "PYSIDE2")
    INCLUDE(UsePySide)
    SALOME_SETUP_PYSIDE_UIC_RCC()
  ELSEIF(SALOME_QT_PYTHON_BINDINGS_BACKEND STREQUAL "PYQT5")
    IF(NOT PYTHON_EXECUTABLE)
      FIND_PROGRAM(PYTHON_EXECUTABLE "python")
    ENDIF()
    # Use the Salome find modules to ensure consistent conflict detection and env accumulation.
    FIND_PACKAGE(SalomeSIP REQUIRED)
    FIND_PACKAGE(SalomePyQt5 REQUIRED)
    INCLUDE(UsePyQt)
  ENDIF()
ENDMACRO()

####################################################################
# SALOME_WRAP_UIC
#
# Unified wrapper for generating Python from Qt Designer *.ui
# Dispatches to PYSIDE2_WRAP_UIC or PYQT_WRAP_UIC.
####################################################################
MACRO(SALOME_WRAP_UIC)
  IF(NOT SALOME_QT_PYTHON_BINDINGS_BACKEND)
    MESSAGE(FATAL_ERROR "SALOME_WRAP_UIC(): call SALOME_SETUP_QT_PYTHON_BINDINGS() first.")
  ENDIF()
  IF(SALOME_QT_PYTHON_BINDINGS_BACKEND STREQUAL "PYSIDE2")
    PYSIDE2_WRAP_UIC(${ARGV})
  ELSEIF(SALOME_QT_PYTHON_BINDINGS_BACKEND STREQUAL "PYQT5")
    PYQT_WRAP_UIC(${ARGV})
  ELSE()
    MESSAGE(FATAL_ERROR "SALOME_WRAP_UIC(): Unknown backend '${SALOME_QT_PYTHON_BINDINGS_BACKEND}'.")
  ENDIF()
ENDMACRO()

####################################################################
# SALOME_WRAP_QRC
#
# Unified wrapper for generating Python from Qt resource *.qrc
# Dispatches to PYSIDE2_WRAP_QRC or PYQT_WRAP_QRC.
####################################################################
MACRO(SALOME_WRAP_QRC)
  IF(NOT SALOME_QT_PYTHON_BINDINGS_BACKEND)
    MESSAGE(FATAL_ERROR "SALOME_WRAP_QRC(): call SALOME_SETUP_QT_PYTHON_BINDINGS() first.")
  ENDIF()
  IF(SALOME_QT_PYTHON_BINDINGS_BACKEND STREQUAL "PYSIDE2")
    PYSIDE2_WRAP_QRC(${ARGV})
  ELSEIF(SALOME_QT_PYTHON_BINDINGS_BACKEND STREQUAL "PYQT5")
    PYQT_WRAP_QRC(${ARGV})
  ELSE()
    MESSAGE(FATAL_ERROR "SALOME_WRAP_QRC(): Unknown backend '${SALOME_QT_PYTHON_BINDINGS_BACKEND}'.")
  ENDIF()
ENDMACRO()
ENDIF()
