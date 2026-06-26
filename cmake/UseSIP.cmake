# Copyright (C) 2012-2025  CEA, EDF, OPEN CASCADE
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
# Author: Vadim SANDLER, Open CASCADE S.A.S. (vadim.sandler@opencascade.com)

####################################################################
#
# SIP_WRAP_SIP macro
#
# Generate C++ wrappings for *.sip files by driving sip-build (SIP 6).
#
# USAGE: SIP_WRAP_SIP(output_files sip_file [sip_file...] [OPTIONS options])
#
# ARGUMENTS:
#   output_files [out] variable where generated C++ file names are listed to
#   sip_file     [in]  input .sip file (the first one is the main module file)
#   options      [in]  additional options. Supported sub-options:
#                        -t <tag>     SIP feature tag (appended to [tool.sip.bindings].tags)
#                        -I <dir>     extra include dir for the generated C++
#
# REQUIRED CMAKE VARIABLES:
#   QT_QMAKE_EXECUTABLE  path to the qmake binary (set by FindQt5 / SalomeQt5)
#   PYQT_SIPS_DIR        path to PyQt5 .sip bindings (set by FindPyQt5)
#
# NOTES:
#   - Input files are considered relative to the current source directory.
#   - sip-build is invoked at configure time (execute_process); generated
#     C++ sources are collected via GLOB_RECURSE and returned through
#     ${outfiles} so callers can ADD_LIBRARY(... ${outfiles}).
#
####################################################################
MACRO(SIP_WRAP_SIP outfiles)
  # ---------------------------------------------------------------------------
  # Required variables
  # ---------------------------------------------------------------------------
  IF(NOT QT_QMAKE_EXECUTABLE)
    MESSAGE(FATAL_ERROR "[SIP_WRAP_SIP] QT_QMAKE_EXECUTABLE is not set; "
                        "Qt5 must be found before calling this macro.")
  ENDIF()
  IF(NOT PYQT_SIPS_DIR)
    MESSAGE(FATAL_ERROR "[SIP_WRAP_SIP] PYQT_SIPS_DIR is not set; "
                        "PyQt5 must be found before calling this macro.")
  ENDIF()

  # ---------------------------------------------------------------------------
  # Parse arguments: SIP files, OPTIONS
  # ---------------------------------------------------------------------------
  set(_sip_files "")
  set(_opt_list "")
  set(_get_options 0)

  foreach(_input ${ARGN})
    if("${_input}" STREQUAL "OPTIONS")
      set(_get_options 1)
    elseif(_get_options)
      list(APPEND _opt_list "${_input}")
    else()
      list(APPEND _sip_files "${_input}")
    endif()
  endforeach()

  if(NOT _sip_files)
    message(STATUS "[SIP_WRAP_SIP] No .sip file provided -> skip.")
    set(${outfiles})
    return()
  endif()

  # The first SIP file is the one passed to sip-build
  list(GET _sip_files 0 _sip_main_rel)
  get_filename_component(_sip_main_abs "${_sip_main_rel}" ABSOLUTE)
  get_filename_component(_sip_dir      "${_sip_main_abs}" DIRECTORY)

  message(STATUS "[SIP_WRAP_SIP] Processing SIP6 file: ${_sip_main_abs}")

  # ---------------------------------------------------------------------------
  # Collect include dirs and feature tags.
  # The caller's INCLUDE_DIRECTORIES() already exposes Qt5 / PyQt5 / Python
  # include paths (gui/CMakeLists.txt sets QT_INCLUDES before calling this).
  # ---------------------------------------------------------------------------
  set(_tags "")
  set(_includes "${_sip_dir}")
  get_directory_property(_all_inc_dirs INCLUDE_DIRECTORIES)
  list(APPEND _includes ${_all_inc_dirs})

  set(_expect_tag 0)
  set(_expect_inc 0)
  foreach(opt IN LISTS _opt_list)
    if("${opt}" STREQUAL "-t")
      set(_expect_tag 1)
      set(_expect_inc 0)
    elseif("${opt}" STREQUAL "-I")
      set(_expect_inc 1)
      set(_expect_tag 0)
    elseif(_expect_tag)
      list(APPEND _tags "${opt}")
      set(_expect_tag 0)
    elseif(_expect_inc)
      list(APPEND _includes "${opt}")
      set(_expect_inc 0)
    endif()
  endforeach()

  # ---------------------------------------------------------------------------
  # Build directory for SIP6
  # ---------------------------------------------------------------------------
  set(_bdir "${CMAKE_CURRENT_BINARY_DIR}/${outfiles}_sipbuild")
  file(MAKE_DIRECTORY "${_bdir}")

  # ---------------------------------------------------------------------------
  # Generate pyproject.toml for sip-build (SIP >= 6.0, PyQt5).
  # abi-version is pinned to 12.15 (matches the locally installed PyQt5);
  # bump if the host's PyQt5 ships a different ABI.
  # ---------------------------------------------------------------------------
  set(_py "${_bdir}/pyproject.toml")

  file(WRITE "${_py}"
"[build-system]
requires = [\"sip >= 6.0\"]
build-backend = \"sipbuild.api\"

[project]
name = \"${outfiles}\"
version = \"1.0\"

[tool.sip]
project-factory = \"pyqtbuild:PyQtProject\"

[tool.sip.builder]
qmake = \"${QT_QMAKE_EXECUTABLE}\"

[tool.sip.project]
sip-include-dirs = [\"${PYQT_SIPS_DIR}\"]
abi-version = \"12.15\"

[tool.sip.bindings.${outfiles}]
sip-file = \"${_sip_main_abs}\"
include-dirs = [
")
  foreach(inc IN LISTS _includes)
    file(APPEND "${_py}" "  \"${inc}\",\n")
  endforeach()
  file(APPEND "${_py}" "]\n")

  if(_tags)
    file(APPEND "${_py}" "tags = [")
    set(_first 1)
    foreach(t IN LISTS _tags)
      if(_first)
        file(APPEND "${_py}" "\"${t}\"")
        set(_first 0)
      else()
        file(APPEND "${_py}" ", \"${t}\"")
      endif()
    endforeach()
    file(APPEND "${_py}" "]\n")
  endif()

  # ---------------------------------------------------------------------------
  # Run sip-build at configure time and collect generated C++ sources.
  # ---------------------------------------------------------------------------
  execute_process(
    COMMAND sip-build --no-compile --verbose --build-dir "${_bdir}"
    WORKING_DIRECTORY "${_bdir}"
    RESULT_VARIABLE _sip_res
  )
  if(_sip_res)
    message(FATAL_ERROR "[SIP_WRAP_SIP] sip-build failed with code ${_sip_res}")
  endif()

  file(GLOB_RECURSE _generated_cpp "${_bdir}/*/*.c*")

  if(NOT _generated_cpp)
    message(FATAL_ERROR "[SIP_WRAP_SIP] No .cpp generated by sip-build in ${_bdir}")
  endif()

  message(STATUS "[SIP_WRAP_SIP] Generated C++ sources:")
  foreach(f ${_generated_cpp})
    message(STATUS "   - ${f}")
  endforeach()

  set(${outfiles} "${_generated_cpp}")
ENDMACRO()
