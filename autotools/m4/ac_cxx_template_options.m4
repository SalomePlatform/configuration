dnl Copyright (C) 2007-2016  CEA/DEN, EDF R&D, OPEN CASCADE
dnl
dnl Copyright (C) 2003-2007  OPEN CASCADE, EADS/CCR, LIP6, CEA/DEN,
dnl CEDRAT, EDF R&D, LEG, PRINCIPIA R&D, BUREAU VERITAS
dnl
dnl This library is free software; you can redistribute it and/or
dnl modify it under the terms of the GNU Lesser General Public
dnl License as published by the Free Software Foundation; either
dnl version 2.1 of the License, or (at your option) any later version.
dnl
dnl This library is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl Lesser General Public License for more details.
dnl
dnl You should have received a copy of the GNU Lesser General Public
dnl License along with this library; if not, write to the Free Software
dnl Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
dnl
dnl See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
dnl

dnl @synopsis AC_CXX_TEMPLATE_OPTIONS
dnl Check template options for C++ compiler
dnl
AC_DEFUN([AC_CXX_TEMPLATE_OPTIONS],[
dnl 
  for opt in -ftemplate-depth-42 "-pending_instantiations 42" ; do
    AC_CXX_OPTION($opt,CXXTMPDPTHFLAGS,flag=yes,flag=no)
    if test "$flag" = "yes"; then
      break
    fi
    AC_SUBST(CXXTMPDPTHFLAGS)
  done
dnl
  AC_CXX_OPTION(-tweak,CXXFLAGS)
])
