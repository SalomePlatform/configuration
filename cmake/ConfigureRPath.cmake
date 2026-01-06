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
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

# RPATH is used to specify the directories where the runtime linker should look for shared libraries.
# Setting RPATH individually for each target ensures that each target can have its own specific
# library search paths, which can be useful in complex projects where different targets may depend
# on different versions of the same library or on libraries located in different directories.
# 
# An updated example from cmake documentation at:
# https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling#default-rpath-settings
#
# NOTE: RUNPATH is preferred over RPATH on platforms where RUNPATH is supported,
# so CMake appears to be setting RUNPATH whenever we use its RPATH functionality.
# It's a reason why we need to check RUNPATH section in the ELF to check if the RPATH is set correctly.
# An example of how to check the RPATH in the ELF:
# readelf -d /path/to/your/library.so | grep 'RPATH\|RUNPATH'
# or
# objdump -x /path/to/your/library.so | grep 'RPATH\|RUNPATH'

# Set the maximum allowed length for RPATH.
# Check if MAX_RPATH_LENGTH is defined from a command line, otherwise set a default value.
if(NOT DEFINED MAX_RPATH_LENGTH)
    set(MAX_RPATH_LENGTH 2000 CACHE STRING "Maximum allowed length for RPATH")
endif()

# This block is commented out because we try to use patchelf instead of chrpath
# to handle RPATH reallocation issues. Must be proven in practice,
# because of known bug in recent patchelf version.
# Look at the following issue for more details:
# Regression in 0.18.0: --set-rpath creates broken header alignment
# https://github.com/NixOS/patchelf/issues/528
# 
# Preallocate the RPATH string with colons as a workaround for chrpath.
# to prevent trimming of a new rpath in case if it's larger than an old one.
# set(DFT_INSTALL_RPATH "")
# foreach(i RANGE ${MAX_RPATH_LENGTH})
#     set(DFT_INSTALL_RPATH "${DFT_INSTALL_RPATH}:")
# endforeach()

# Configure the same RPATH for all targets in the project,
# except part of RPATH that is set automatically by CMake.
# 
# This macro should be called before any target is created.
macro(configure_rpath)
    # RPATH settings:
    # use, i.e. don't skip the full RPATH for the build tree
    set(CMAKE_SKIP_BUILD_RPATH FALSE)

    # when building, don't use the install RPATH already
    # (but later on when installing)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

    # add the automatically determined parts of the RPATH
    # which point to directories outside the build tree to the install RPATH
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

    # Commmon RPATH settings, it's difficult to set RPATH for each target to point inside build tree
    #set(CMAKE_INSTALL_RPATH
    #    $ORIGIN # the same directory as the executable
    #    $ORIGIN/../../../../salome # from /lib/python3.9/site-packages/salome/kernel to /lib/salome $ORIGIN/../../../../salome
    #    $ORIGIN/../../lib/salome # from /bin/salome to /lib/salome
    #    $ORIGIN/../../../../../lib/salome # from bin/salome/test/kernel/<some_test> to /lib/salome
    #)

    # Commented out while we have a working solution with patchelf.
    # set(CMAKE_INSTALL_RPATH ${DFT_INSTALL_RPATH})
endmacro()

configure_rpath()
