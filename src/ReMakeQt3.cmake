############################################################################
#    Copyright (C) 2009 by Ralf 'Decan' Kaestner                           #
#    ralf.kaestner@gmail.com                                               #
#                                                                          #
#    This program is free software; you can redistribute it and#or modify  #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation; either version 2 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program; if not, write to the                         #
#    Free Software Foundation, Inc.,                                       #
#    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
############################################################################

include(ReMakePrivate)

### \brief Configure Qt3 meta-object processing.
#   This macro discovers the Qt3 package configuration and enables Qt3
#   meta-object processing. Note that the macro automatically gets
#   invoked by the macros defined in this module. It needs not be called
#   directly from a CMakeLists.txt file.
#   \optional[option] MT If provided, the macro tries to discover the
#     package configuration for the multithreaded version of Qt3.
macro(remake_qt3)
  remake_arguments(PREFIX qt3_ OPTION MT ${ARGN})
  remake_set(QT_MT_REQUIRED ${qt3_mt})

  if(NOT DEFINED QT_FOUND)
    remake_find_package(KDE3 QUIET)
    remake_find_package(Qt3 QUIET ALIAS Qt)
    remake_project_set(QT3_MOC ${QT_FOUND} CACHE BOOL
      "Process Qt3 meta-objects.")
  endif(NOT DEFINED QT_FOUND)
endmacro(remake_qt3)

### \brief Add the Qt3 header directories to the include path.
#   This macro adds the Qt3 header directories to the compiler's include path.
#   \optional[option] MT If provided, the macro adds the header directories
#     of the multithreaded version of Qt3.
macro(remake_qt3_include)
  remake_arguments(PREFIX qt3_ OPTION MT ${ARGN})

  remake_qt3(${MT})

  if(QT_FOUND)
    remake_include(${QT_INCLUDE_DIR})
  endif(QT_FOUND)
endmacro(remake_qt3_include)

### \brief Add Qt3 meta-object sources for a target.
#   This macro automatically defines meta-object sources for a target from
#   a list of glob expressions. The glob expressions should resolve to
#   header files containing a Q_OBJECT declaration.
#   \required[value] target The name of the target to add the meta-object
#     sources for.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the header files with Q_OBJECT declarations,
#     defaulting to *.h, *.hpp, and *.tpp.
#   \optional[option] MT If provided, the macro defines meta-object sources
#     for the multithreaded version of Qt3.
macro(remake_qt3_moc qt3_target)
  remake_arguments(PREFIX qt3_ ARGN globs OPTION MT ${ARGN})
  remake_set(qt3_globs SELF DEFAULT *.h DEFAULT *.hpp DEFAULT *.tpp)

  remake_qt3(${MT})

  remake_project_get(QT3_MOC)
  if(QT3_MOC)
    remake_file_glob(qt3_headers ${qt3_globs})
    remake_set(qt3_sources)
    kde3_add_moc_files(qt3_sources ${qt3_headers})
    remake_target_add_sources(${qt3_target} ${qt3_sources})
  endif(QT3_MOC)
endmacro(remake_qt3_moc)
