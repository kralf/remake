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

include(FindPkgConfig)

### \brief ReMake package and file discovery macros
#   The ReMake package and file discovery macros provide a useful abstraction
#   to CMake's native find functionalities.

### \brief Find a package.
#   This macro calls CMake's find_package() or pkg_check_modules() to find
#   and load settings from an external project installed on the system. If
#   the package was found, essential variables are initialized and the
#   upper-case conversion of ${PACKAGE}_FOUND is set to TRUE. Arguments
#   given in addition to the package name are forwarded to find_package() and
#   pkg_check_modules(), respectively.
#   \required[value] package The name of the package to be discovered. Note
#     that CMake module naming conventions require the exact casing of
#     package names here, usually starting with a capital letter.
#   \optional[option] CONFIG If present, this option causes the macro to
#     call CMake's pkg_check_modules() instead of find_package(). With no
#     additional arguments provided, the package name is passed as
#     module name to pkg_check_modules().
#   \optional[value] ALIAS:alias An optional package alias that is used for
#     evaluating if ${ALIAS}_FOUND is set to TRUE. The alias has to be
#     provided in cases where the package name differs from the variable
#     prefix assumed by CMake's find_package().
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_package() and pkg_check_modules(), respectively. See the
#     CMake documentation for the correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_package find_package)
  remake_arguments(PREFIX find_ OPTION CONFIG VAR ALIAS ARGN args
    OPTION OPTIONAL ${ARGN})

  if(find_config)
    remake_var_name(find_package_var ${find_package})
    remake_set(find_args SELF DEFAULT ${find_package})
    pkg_check_modules(${find_package_var} ${find_args})
    remake_find_result(${find_package} ${${find_package_var}_FOUND}
      ${OPTIONAL})
  else(find_config)
    if(find_alias)
      remake_var_name(find_package_var ${find_alias} FOUND)
    else(find_alias)
      remake_var_name(find_package_var ${find_package} FOUND)
    endif(find_alias)
    find_package(${find_package} ${find_args})
    remake_find_result(${find_package} ${${find_package}_FOUND}
      ${${find_package_var}} ${OPTIONAL})
  endif(find_config)
endmacro(remake_find_package)

### \brief Find a library and it's header file.
#   This macro calls CMake's find_library() and find_path() to discover
#   a library and it's header files installed on the system. If the
#   library and the header were found, the variable name conversion of
#   ${LIBRARY}_FOUND is set to TRUE. Furthermore, ${LIBRARY}_LIBRARY and
#   ${LIBRARY}_HEADERS are initialized for linkage and header inclusion.
#   Arguments given in addition to the library and header name are forwarded
#   to find_library() and find_path().
#   \required[value] library The name of the library to be discovered.
#   \required[value] header The name of the header to be discovered.
#   \optional[value] PACKAGE:package The name of the package containing the
#     requested library, defaults to the provided library name and is used
#     for display and to set the PATH_SUFFIXES argument for find_path().
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_library() and find_path(). See the CMake documentation
#     for correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_library find_lib find_header)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args OPTION OPTIONAL ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_lib})
  remake_var_name(find_lib_var ${find_lib} LIBRARY)
  remake_var_name(find_headers_var ${find_lib} HEADERS)

  find_library(${find_lib_var} NAMES ${find_lib} ${find_args})
  if(${find_lib_var})
    remake_file_name(find_path_suffix ${find_package})
    find_path(${find_headers_var} NAMES ${find_header}
      PATH_SUFFIXES ${find_path_suffix} ${find_args})
  else(${find_lib_var})
    remake_set(${find_headers_var})
  endif(${find_lib_var})

  remake_find_result(${find_package} ${${find_headers_var}} ${OPTIONAL})
endmacro(remake_find_library)

### \brief Find an executable program.
#   This macro calls CMake's find_program() to discover an executable
#   installed on the system. If the executable was found, the variable
#   name conversion of ${PACKAGE}_FOUND is set to TRUE. Furthermore,
#   ${PACKAGE}_EXECUTABLE is initialized with the full path to the executable.
#   Arguments given in addition to the executable name are forwarded to
#   find_program().
#   \required[value] executable The name of the executable to be discovered.
#   \optional[value] PACKAGE:package The name of the package containing the
#     requested executable, defaults to the upper-case conversion of the
#     executable name and is used to set ${PACKAGE}_FOUND.
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_program(). See the CMake documentation for correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_executable find_exec)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args OPTION OPTIONAL ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_exec})
  remake_var_name(find_exec_var ${find_package} EXECUTABLE)

  find_program(${find_exec_var} NAMES ${find_exec} ${find_args})

  remake_find_result(${find_package} ${${find_exec_var}} ${OPTIONAL})
endmacro(remake_find_executable)

### \brief Find a file.
#   This macro calls CMake's find_path() to discover the full path to a file
#   installed on the system. If the file was found, the variable name
#   conversion of ${PACKAGE}_FOUND is set to TRUE. Furthermore,
#   ${PACKAGE}_FILE is initialized with the full path to the file.
#   Arguments given in addition to the file name are forwarded to
#   find_path().
#   \required[value] file The name of the file to be discovered.
#   \required[value] PACKAGE:package The name of the package containing the
#     requested file which is used to set ${PACKAGE}_FOUND.
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_path(). See the CMake documentation for correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_file find_file)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args OPTION OPTIONAL ${ARGN})
  remake_var_name(find_file_var ${find_package} FILE)

  find_path(${find_file_var} NAMES ${find_file} ${find_args})

  remake_find_result(${find_package} ${${find_file_var}} ${OPTIONAL})
endmacro(remake_find_file)

### \brief Evaluate the result of a find operation.
#   This macro is a helper macro to evaluate the result of a find operation.
#   It gets invoked by the specific find macros defined in this module
#   and should not be called directly from a CMakeLists.txt file. The macro's
#   main purpose is to emit a message on the result of the find operation and
#   to set the ${PACKAGE}_FOUND cache variable.
#   \required[value] package The name of the package that was to be found.
#   \optional[option] OPTIONAL If provided, a negative result will
#     not lead to a fatal error but to a warning message instead.
#   \required[value] result The find result returned to the calling macro,
#     usually depends on the macro-specific find operation.
macro(remake_find_result find_package)
  remake_arguments(PREFIX find_ OPTION OPTIONAL ARGN result ${ARGN})
  remake_var_name(find_result_var ${find_package} FOUND)

  if(find_result)
    remake_set(${find_result_var} ON CACHE BOOL
      "Found ${find_package} package." FORCE)
  else(find_result)
    remake_set(${find_result_var} OFF CACHE BOOL
      "Found ${find_package} package." FORCE)
    if(find_optional)
      message(STATUS "Warning: Missing ${find_package} support!")
    else(find_optional)
      message(FATAL_ERROR "Missing ${find_package} support!")
    endif(find_optional)
  endif(find_result)
endmacro(remake_find_result)
