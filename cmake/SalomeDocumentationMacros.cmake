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
# Author: Roman NIKOLAEV
#

#----------------------------------------------------------------------------
# SALOME_ADD_SPHINX_DOC is a macro useful for generating sphinx documentation
#
# USAGE: SALOME_ADD_SPHINX_DOC(sphinx_type sphinx_name src_dir cfg_dir)
#
# ARGUMENTS:
#
# sphinx_type: IN - type of the sphinx generator, use one of the following  types: 
#
#                       html       - to make standalone HTML files
#                       dirhtml    - to make HTML files named index.html in directories
#                       singlehtml - to make a single large HTML file
#                       pickle     - to make pickle files
#                       json       - to make JSON files
#                       htmlhelp   - to make HTML files and a HTML help project
#                       qthelp     - to make HTML files and a qthelp project"
#                       devhelp    to make HTML files and a Devhelp project"
#                       epub       to make an epub"
#                       latex      to make LaTeX files, you can set PAPER=a4 or PAPER=letter
#                       latexpdf   to make LaTeX files and run them through pdflatex"
#                       text       to make text files"
#                       man        to make manual pages"
#                       texinfo    to make Texinfo files"
#                       info       to make Texinfo files and run them through makeinfo
#                       gettext    to make PO message catalogs"
#                       changes    to make an overview of all changed/added/deprecated items
#                       linkcheck  to check all external links for integrity"
#                       doctest    to run all doctests embedded in the documentation (if enabled)\
# 
# sphinx_name: IN - documentation target name
#
# src_dir : IN - path to directory that contains the sphinx source files
# 
# cfg_dir : IN - path to directory that contains sphinx configuration file (if not specified,
#           it is considered equal to src_dir)
#
# ADDITIONAL SETTINGS:
#
# Also you can set these variables to define additional sphinx settings:
#
#                        SPHINXOPTS    - sphinx executable options
#                        PAPER         - LaTeX paper type          ("a4" by default)
#                        BUILDDIR      - local sphinx build directory  ("_build" by default)
#----------------------------------------------------------------------------

MACRO(SALOME_ADD_SPHINX_DOC sphinx_type sphinx_name src_dir cfg_dir)

  # Get type and additional settings
  SET(SPHINX_TYPE ${sphinx_type})
  IF(${SPHINX_TYPE} STREQUAL "")
    SET(SPHINX_TYPE html)
  ENDIF(${SPHINX_TYPE} STREQUAL "")

  IF("${PAPER}" STREQUAL "")
    SET(PAPER a4)
  ENDIF()
 
  IF("${BUILDDIR}" STREQUAL "")
    SET(BUILDDIR _build)
  ENDIF()

  SET(SPHINX_CFG ${cfg_dir})
  IF("${SPHINX_CFG}" STREQUAL "")
    SET(SPHINX_CFG ${src_dir})
  ENDIF()

  # Initialize internal variables
  SET(PAPEROPT_a4 -D latex_paper_size=a4)
  SET(PAPEROPT_letter -D latex_paper_size=letter)
  SET(ALLSPHINXOPTS  -d ${BUILDDIR}/doctrees ${PAPEROPT_${PAPER}} ${SPHINXOPTS})
  SET(I18NSPHINXOPTS  ${PAPEROPT_${PAPER}} ${SPHINXOPTS})

  SET(ALLSPHINXOPTS ${ALLSPHINXOPTS} ${src_dir})
  SET(I18NSPHINXOPTS ${I18NSPHINXOPTS} ${src_dir})

  # Set internal out directory
  SET(_OUT_DIR ${SPHINX_TYPE}) 
  IF(${SPHINX_TYPE} STREQUAL "gettext")
    SET(_OUT_DIR gettext)
    SET(ALLSPHINXOPTS ${I18NSPHINXOPTS})
  ENDIF(${SPHINX_TYPE} STREQUAL "gettext")

  # Build sphinx command
  SET(_CMD_OPTIONS -b ${SPHINX_TYPE} -c ${SPHINX_CFG} ${ALLSPHINXOPTS} ${BUILDDIR}/${_OUT_DIR})

  # This macro mainly prepares the environment in which sphinx should run:
  # this sets the PYTHONPATH and LD_LIBRARY_PATH to include OMNIORB, DOCUTILS, SETUPTOOLS, etc ...
  SALOME_GENERATE_ENVIRONMENT_SCRIPT(_cmd env_script "${SPHINX_EXECUTABLE}" "${_CMD_OPTIONS}")
  ADD_CUSTOM_TARGET(${sphinx_name} ALL ${_cmd})

ENDMACRO(SALOME_ADD_SPHINX_DOC)
