# Copyright (C) 2012-2026  CEA, EDF, OPEN CASCADE
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
# See http://www.salome-platform.org/
#

# NOTE: This file defines CMake *macros* (not functions). Inside macros,
# variables like CMAKE_CURRENT_LIST_DIR refer to the *call site* (the including
# module), not to this file. Compute paths that must be stable (like helper
# scripts shipped with CONFIGURATION) at include-time here.
SET(_SALOME_PYSIDE2_UIC_POSTPROCESS_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/pyside2_uic_postprocess.py")

####################################################################
#
# NAME: PYSIDE2_CONFIG
#
# Implements a generic interface to pyside2_config.py
# given the pyside2_config.py option, returns the output in a variable
#
#
####################################################################
MACRO(PYSIDE2_CONFIG OPTION output_var)
  IF(${ARGC} GREATER 2)
    SET(is_list ${ARGV2})
  ELSE()
    SET(is_list "")
  ENDIF()
  IF(NOT PYTHON_EXECUTABLE)
    FIND_PROGRAM(PYTHON_EXECUTABLE "python")
  ENDIF()
  SET(PYSIDE2_ROOT_DIR $ENV{PYSIDE2_ROOT_DIR} CACHE PATH "Path to the PYSIDE installation")

  SET(PYSIDE2_CONFIGURATION_SCRIPT "")
  IF(PYSIDE2_ROOT_DIR)
    IF (CMAKE_SYSTEM_NAME STREQUAL "Linux")
      SET(_pyside2_config_candidate "${PYSIDE2_ROOT_DIR}/bin/pyside2_config.py")
    ELSEIF (CMAKE_SYSTEM_NAME STREQUAL "Windows")
      SET(_pyside2_config_candidate "${PYSIDE2_ROOT_DIR}/Scripts/pyside2_config.py")
    ELSE()
      SET(_pyside2_config_candidate "${PYSIDE2_ROOT_DIR}/bin/pyside2_config.py")
    ENDIF()
    IF(EXISTS "${_pyside2_config_candidate}")
      SET(PYSIDE2_CONFIGURATION_SCRIPT "${_pyside2_config_candidate}")
    ENDIF()
  ENDIF()

  IF(NOT PYSIDE2_CONFIGURATION_SCRIPT)
    FIND_FILE(PYSIDE2_CONFIGURATION_SCRIPT
      NAMES pyside2_config.py
      HINTS ${PYSIDE2_ROOT_DIR}
      PATH_SUFFIXES bin Scripts
    )
  ENDIF()

  IF(NOT PYSIDE2_CONFIGURATION_SCRIPT)
    MESSAGE(FATAL_ERROR "Error: pyside2_config.py not found. Set PYSIDE2_ROOT_DIR (or env PYSIDE2_ROOT_DIR) to your PySide2 installation.")
  ENDIF()
  EXECUTE_PROCESS(
    COMMAND "${PYTHON_EXECUTABLE}" "${PYSIDE2_CONFIGURATION_SCRIPT}"
    ${OPTION}
    OUTPUT_VARIABLE ${output_var}
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  
  IF("${${output_var}}" STREQUAL "")
    MESSAGE(FATAL_ERROR "Error: Calling ${PYSIDE2_CONFIGURATION_SCRIPT} ${OPTION} returned no output.")
  ENDIF()
  IF(is_list)
    SET(_pyside2_config_list "${${output_var}}")
    STRING(REPLACE "\r" "" _pyside2_config_list "${_pyside2_config_list}")
    STRING(REPLACE "\n" " " _pyside2_config_list "${_pyside2_config_list}")
    SEPARATE_ARGUMENTS(_pyside2_config_list)
    SET(${output_var} "${_pyside2_config_list}")
  ENDIF()
ENDMACRO()

####################################################################
#
# NAME: SALOME_SETUP_PYSIDE_UIC_RCC macro
#
# USAGE: returns the pyside2-uic and pyside2-rcc location
#   PYSIDE2_PYUIC_EXECUTABLE
#   PYSIDE2_PYRCC_EXECUTABLE
#
# ARGUMENTS:
#
# NOTES:
#
####################################################################
MACRO(SALOME_SETUP_PYSIDE_UIC_RCC)
  SET(PYSIDE2_ROOT_DIR $ENV{PYSIDE2_ROOT_DIR} CACHE PATH "Path to the PYSIDE installation")

  SET(_pyside2_bin_hints "")
  IF(PYSIDE2_ROOT_DIR)
    LIST(APPEND _pyside2_bin_hints "${PYSIDE2_ROOT_DIR}/bin" "${PYSIDE2_ROOT_DIR}/Scripts")
  ENDIF()

  FIND_PROGRAM(PYSIDE2_PYUIC_EXECUTABLE
    NAMES pyside2-uic pyside2-uic.bat
    HINTS ${_pyside2_bin_hints}
  )
  FIND_PROGRAM(PYSIDE2_PYRCC_EXECUTABLE
    NAMES pyside2-rcc pyside2-rcc.bat
    HINTS ${_pyside2_bin_hints}
  )
  MESSAGE(STATUS "Found pyside2 uic: ${PYSIDE2_PYUIC_EXECUTABLE}")
  MESSAGE(STATUS "Found pyside2 rcc: ${PYSIDE2_PYRCC_EXECUTABLE}")

  IF(NOT PYSIDE2_PYUIC_EXECUTABLE)
    MESSAGE(FATAL_ERROR "Error: pyside2-uic not found in PATH.")
  ENDIF()
  IF(NOT PYSIDE2_PYRCC_EXECUTABLE)
    MESSAGE(FATAL_ERROR "Error: pyside2-rcc not found in PATH.")
  ENDIF()
ENDMACRO(SALOME_SETUP_PYSIDE_UIC_RCC)

####################################################################
#
# NAME: SALOME_SETUP_PYSIDE_SHIBOKEN macro
#
# USAGE: setup the required CMake variables
#
# ARGUMENTS:
#
# NOTES:
#
####################################################################
MACRO(SALOME_SETUP_PYSIDE_SHIBOKEN)
  # Use provided python interpreter if given.
  IF(NOT PYTHON_EXECUTABLE)
    FIND_PROGRAM(PYTHON_EXECUTABLE "python")
  ENDIF()
  MESSAGE(STATUS "Using python interpreter: ${PYTHON_EXECUTABLE}")
  # Query for the shiboken generator path, Python path, include paths and linker flags.
  PYSIDE2_CONFIG(--shiboken2-module-path SHIBOKEN2_MODULE_PATH)
  PYSIDE2_CONFIG(--shiboken2-generator-path SHIBOKEN2_GENERATOR_PATH)
  PYSIDE2_CONFIG(--pyside2-path PYSIDE2_PATH)
  PYSIDE2_CONFIG(--pyside2-include-path PYSIDE2_INCLUDE_DIR 1)
  PYSIDE2_CONFIG(--python-include-path PYSIDE2_PYTHON_INCLUDE_DIR)
  PYSIDE2_CONFIG(--shiboken2-generator-include-path SHIBOKEN2_INCLUDE_DIR 1)
  PYSIDE2_CONFIG(--shiboken2-module-shared-libraries-cmake SHIBOKEN2_SHARED_LIBRARIES 0)
  PYSIDE2_CONFIG(--python-link-flags-cmake PYSIDE2_PYTHON_LINKING_DATA 0)
  PYSIDE2_CONFIG(--pyside2-shared-libraries-cmake PYSIDE2_SHARED_LIBRARIES 0)
  
  SET(SHIBOKEN2_GENERATOR_EXECUTABLE "${SHIBOKEN2_GENERATOR_PATH}/shiboken2${CMAKE_EXECUTABLE_SUFFIX}")
  IF(NOT EXISTS "${SHIBOKEN2_GENERATOR_EXECUTABLE}")
    MESSAGE(FATAL_ERROR "Shiboken executable not found at path: ${SHIBOKEN2_GENERATOR_EXECUTABLE}")
  ENDIF()
  FILE(GLOB_RECURSE PYSIDE2_INCLUDE_DIRS LIST_DIRECTORIES TRUE "${PYSIDE2_PATH}/include/*")
  LIST(FILTER PYSIDE2_INCLUDE_DIRS EXCLUDE REGEX \.h$)
  LIST(APPEND PYSIDE2_INCLUDE_DIRS ${PYSIDE2_PATH}/include)
  MESSAGE(STATUS "PYSIDE2_INCLUDE_DIRS: ${PYSIDE2_INCLUDE_DIRS}")
ENDMACRO()

####################################################################
#
# NAME: SALOME_GENERATE_PYSIDE_BINDINGS
#
#
# USAGE:
#
# ARGUMENTS:
#
# NOTES:
#
####################################################################
MACRO(SALOME_GENERATE_PYSIDE_BINDINGS)
  SET(OPTIONS)
  SET(oneValueArgs PYSIDE2_BINDING_WRAPPED_HEADER PYSIDE2_BINDING_TYPESYSTEM_FILE PYSIDE2_BINDING_BINARY_DIR PYSIDE2_BINDING_DEPENDS)
  SET(multiValueArgs PYSIDE2_BINDING_GENERATED_SOURCES PYSIDE2_BINDING_INCLUDE_DIRECTORIES)
  CMAKE_PARSE_ARGUMENTS(ARG "${OPTIONS}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  SET(BINDING_INCLUDE_DIRECTORIES "")
  FOREACH(I ${ARG_PYSIDE2_BINDING_INCLUDE_DIRECTORIES})
    LIST(APPEND BINDING_INCLUDE_DIRECTORIES "-I${I}")
  ENDFOREACH()
  
  # Set up the options to pass to shiboken.
  # --generator-set                 -> path to the Shiboken generator
  # --enable-parent-ctor-heuristic  -> gestion de la relation entre les différentes classes parent enfant - gestion des destructeurs
  # --enable-return-value-heuristic -> gestion des objets c++ renvoyés par des méthodes
  # --use-isnull-as-nb_nonzero      -> is une classe c++ implémente une méthode isNull() const, cette méthode sera utilisée pour vérifier si des objets sont Null
  # --avoid-protected-hack          -> évite d'utiliser le hack #define protected public -  utilise une approche plus standardisée pour accéder aux membres protected
  # --drop-type-entries             -> force Shiboken à ignorer les classes indiquées - --drop-type-entries="Class1;Class2;..."
  # --enable-pyside-extensions      -> activation du support des extensions pyside (signals/slots)
  # --typesystem-paths              -> chemin de recherche des fichiers xml
  # --include-path                  -> chemin de recherche des fichiers C++ à utiliser par le parseur clang
  SET(SHIBOKEN_OPTIONS --generator-set=shiboken
                       --enable-parent-ctor-heuristic
                       --enable-return-value-heuristic
                       --use-isnull-as-nb_nonzero
                       --avoid-protected-hack
                       --enable-pyside-extensions # --debug-level=full
                       ${BINDING_INCLUDE_DIRECTORIES}
                       -I${PYSIDE2_PYTHON_INCLUDE_DIR}
                       -I${SHIBOKEN2_INCLUDE_DIR}
                       -T${PYSIDE2_PATH}/typesystems
                       -T${CMAKE_SOURCE_DIR}
                       --output-directory=${ARG_PYSIDE2_BINDING_BINARY_DIR}
                       )

  # Add custom target to run shiboken to generate the binding cpp files.
  SET(GENERATED_SOURCES_DEPENDENCIES ${ARG_PYSIDE2_BINDING_WRAPPED_HEADER}
                                     ${ARG_PYSIDE2_BINDING_TYPESYSTEM_FILE})
  IF(ARG_PYSIDE2_BINDING_DEPENDS)
    LIST(APPEND GENERATED_SOURCES_DEPENDENCIES ${ARG_PYSIDE2_BINDING_DEPENDS})
  ENDIF()

  ADD_CUSTOM_COMMAND(OUTPUT ${ARG_PYSIDE2_BINDING_GENERATED_SOURCES}
    COMMAND "${SHIBOKEN2_GENERATOR_EXECUTABLE}"
    ${SHIBOKEN_OPTIONS} ${ARG_PYSIDE2_BINDING_WRAPPED_HEADER} ${ARG_PYSIDE2_BINDING_TYPESYSTEM_FILE}
    DEPENDS ${GENERATED_SOURCES_DEPENDENCIES}
    IMPLICIT_DEPENDS CXX ${ARG_PYSIDE2_BINDING_WRAPPED_HEADER}
    WORKING_DIRECTORY ${ARG_PYSIDE2_BINDING_BINARY_DIR}
    COMMENT "Running generator for ${ARG_PYSIDE2_BINDING_TYPESYSTEM_FILE}.")
ENDMACRO()

####################################################################
#
# NAME: PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME
#
# USAGE: PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME(prefix unique_name)
#
# ARGUMENTS:
#   prefix [in] prefix for the name
#   unique_name [out] unique name generated by function
#
####################################################################
FUNCTION(PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME name unique_name)
  SET(_propertyName "_PYSIDE2_WRAP_UNIQUE_COUNTER_${name}")
  GET_PROPERTY(_currentCounter GLOBAL PROPERTY "${_propertyName}")
  IF(NOT _currentCounter)
    SET(_currentCounter 1)
  ENDIF()
  SET(${unique_name} "${name}_${_currentCounter}" PARENT_SCOPE)
  MATH(EXPR _currentCounter "${_currentCounter} + 1")
  SET_PROPERTY(GLOBAL PROPERTY ${_propertyName} ${_currentCounter} )
ENDFUNCTION()

####################################################################
#
# NAME: PYSIDE2_WRAP_QRC macro
#
# Generate Python wrappings for *.qrc files by processing them with pyside2-rcc.
#
# USAGE: PYSIDE2_WRAP_QRC(output_files qrc_files)
#
####################################################################
MACRO(PYSIDE2_WRAP_QRC outfiles)
  SALOME_SETUP_PYSIDE_UIC_RCC()
  FOREACH(_input ${ARGN})
    GET_FILENAME_COMPONENT(_input_name ${_input} NAME)
    STRING(REPLACE ".qrc" "_qrc.py" _input_name ${_input_name})
    SET(_output ${CMAKE_CURRENT_BINARY_DIR}/${_input_name})
    ADD_CUSTOM_COMMAND(
      OUTPUT ${_output}
      COMMAND "${PYSIDE2_PYRCC_EXECUTABLE}" -o ${_output} ${CMAKE_CURRENT_SOURCE_DIR}/${_input}
      MAIN_DEPENDENCY ${_input}
      )
    SET(${outfiles} ${${outfiles}} ${_output})
  ENDFOREACH()
  PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME(BUILD_QRC_PY_FILES _uniqueTargetName)
  ADD_CUSTOM_TARGET(${_uniqueTargetName} ALL DEPENDS ${${outfiles}})
ENDMACRO(PYSIDE2_WRAP_QRC)

####################################################################
#
# NAME: PYSIDE2_WRAP_UIC macro
#
#
# USAGE: Create Python modules by processing input *.ui (Qt designer) files with
#        PySide2 pyside2-uic tool.
#        PYSIDE2_WRAP_UIC(output_files uic_files)
#
# ARGUMENTS:
#   output_files [out] variable where output file names are listed to
#   uic_files    [in]  list of *.ui files
#   options      [in]  additional options to be specified to pyside2-uic
#
# NOTES:
#   - Input files are considered relative to the current source directory.
#   - Output files are generated in the current build directory.
#   - Macro automatically adds custom build target to generate output files
#
####################################################################
MACRO(PYSIDE2_WRAP_UIC outfiles)
  SET(_output)
  PARSE_ARGUMENTS(PYSIDE2_WRAP_UIC "TARGET_NAME;OPTIONS" "" ${ARGN})
  SALOME_SETUP_PYSIDE_UIC_RCC()

  # Emulate a subset of PyQt5's pyuic5 options that are used in SALOME but not
  # supported by pyside2-uic (which delegates to Qt's uic).
  SET(_pyside2_uic_import_from "")
  SET(_pyside2_uic_resource_suffix "")
  SET(_pyside2_uic_options_filtered "")
  SET(_pyside2_uic_expect_value_for "")
  FOREACH(_opt ${PYSIDE2_WRAP_UIC_OPTIONS})
    IF(_pyside2_uic_expect_value_for STREQUAL "import-from")
      SET(_pyside2_uic_import_from "${_opt}")
      SET(_pyside2_uic_expect_value_for "")
    ELSEIF(_pyside2_uic_expect_value_for STREQUAL "resource-suffix")
      SET(_pyside2_uic_resource_suffix "${_opt}")
      SET(_pyside2_uic_expect_value_for "")
    ELSEIF(_opt STREQUAL "--import-from")
      SET(_pyside2_uic_expect_value_for "import-from")
    ELSEIF(_opt STREQUAL "--resource-suffix")
      SET(_pyside2_uic_expect_value_for "resource-suffix")
    ELSEIF(_opt MATCHES "^--import-from=(.+)$")
      SET(_pyside2_uic_import_from "${CMAKE_MATCH_1}")
    ELSEIF(_opt MATCHES "^--resource-suffix=(.+)$")
      SET(_pyside2_uic_resource_suffix "${CMAKE_MATCH_1}")
    ELSE()
      LIST(APPEND _pyside2_uic_options_filtered "${_opt}")
    ENDIF()
  ENDFOREACH()

  SET(_pyside2_uic_postprocess_args "")
  IF(_pyside2_uic_import_from OR _pyside2_uic_resource_suffix)
    IF(NOT PYTHON_EXECUTABLE)
      FIND_PROGRAM(PYTHON_EXECUTABLE "python")
    ENDIF()
    SET(_pyside2_uic_postprocess_script "${_SALOME_PYSIDE2_UIC_POSTPROCESS_SCRIPT}")
    IF(_pyside2_uic_import_from)
      LIST(APPEND _pyside2_uic_postprocess_args --import-from "${_pyside2_uic_import_from}")
    ENDIF()
    IF(_pyside2_uic_resource_suffix)
      LIST(APPEND _pyside2_uic_postprocess_args --resource-suffix "${_pyside2_uic_resource_suffix}")
    ENDIF()
  ENDIF()

  IF(NOT WIN32)
    FOREACH(_input ${PYSIDE2_WRAP_UIC_DEFAULT_ARGS})
      GET_FILENAME_COMPONENT(_input_name ${_input} NAME)
      STRING(REPLACE ".ui" "_ui.py" _input_name ${_input_name})
      SET(_output ${CMAKE_CURRENT_BINARY_DIR}/${_input_name})
      IF(_pyside2_uic_postprocess_args)
        ADD_CUSTOM_COMMAND(
          OUTPUT ${_output}
          COMMAND "${PYSIDE2_PYUIC_EXECUTABLE}" ${_pyside2_uic_options_filtered} -o ${_output} ${CMAKE_CURRENT_SOURCE_DIR}/${_input}
          COMMAND "${PYTHON_EXECUTABLE}" "${_pyside2_uic_postprocess_script}" --input ${_output} ${_pyside2_uic_postprocess_args}
          MAIN_DEPENDENCY ${_input}
        )
      ELSE()
        ADD_CUSTOM_COMMAND(
          OUTPUT ${_output}
          COMMAND "${PYSIDE2_PYUIC_EXECUTABLE}" ${_pyside2_uic_options_filtered} -o ${_output} ${CMAKE_CURRENT_SOURCE_DIR}/${_input}
          MAIN_DEPENDENCY ${_input}
        )
      ENDIF()
      SET(${outfiles} ${${outfiles}} ${_output})
    ENDFOREACH()
    PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME(BUILD_UI_PY_FILES _uniqueTargetName)
    ADD_CUSTOM_TARGET(${_uniqueTargetName} ALL DEPENDS ${${outfiles}})
    IF(PYSIDE2_WRAP_UIC_TARGET_NAME)
      SET(${PYSIDE2_WRAP_UIC_TARGET_NAME} ${_uniqueTargetName})
    ENDIF(PYSIDE2_WRAP_UIC_TARGET_NAME)

  ELSE(NOT WIN32)
    SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
    PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME(BUILD_UI_PY_FILES _uniqueTargetName)
    ADD_CUSTOM_TARGET(${_uniqueTargetName} ALL)
    IF(PYSIDE2_WRAP_UIC_TARGET_NAME)
      SET(${PYSIDE2_WRAP_UIC_TARGET_NAME} ${_uniqueTargetName})
    ENDIF(PYSIDE2_WRAP_UIC_TARGET_NAME)
    SET_TARGET_PROPERTIES(${_uniqueTargetName} PROPERTIES FOLDER PYSIDE2_WRAP_UIC_TARGETS)
    FOREACH(_input ${PYSIDE2_WRAP_UIC_DEFAULT_ARGS})
      GET_FILENAME_COMPONENT(_input_name ${_input} NAME)
      STRING(REPLACE ".ui" "_ui.py" _input_name ${_input_name})
      SET(_output ${CMAKE_CURRENT_BINARY_DIR}/${_input_name})
      PYSIDE2_WRAP_GET_UNIQUE_TARGET_NAME(BUILD_UI_PY_FILES _TgName)
      IF(_pyside2_uic_postprocess_args)
        ADD_CUSTOM_TARGET(${_TgName}
          COMMAND "${PYSIDE2_PYUIC_EXECUTABLE}" ${_pyside2_uic_options_filtered} -o ${_output} ${CMAKE_CURRENT_SOURCE_DIR}/${_input}
          COMMAND "${PYTHON_EXECUTABLE}" "${_pyside2_uic_postprocess_script}" --input ${_output} ${_pyside2_uic_postprocess_args}
          DEPENDS ${_input}
        )
      ELSE()
        ADD_CUSTOM_TARGET(${_TgName}
          COMMAND "${PYSIDE2_PYUIC_EXECUTABLE}" ${_pyside2_uic_options_filtered} -o ${_output} ${CMAKE_CURRENT_SOURCE_DIR}/${_input}
          DEPENDS ${_input}
        )
      ENDIF()
      SET_TARGET_PROPERTIES(${_TgName} PROPERTIES FOLDER PYSIDE2_WRAP_UIC_TARGETS)
      ADD_DEPENDENCIES(${_uniqueTargetName} ${_TgName})
      SET(${outfiles} ${${outfiles}} ${_output})
    ENDFOREACH()
  ENDIF(NOT WIN32)
ENDMACRO(PYSIDE2_WRAP_UIC)
