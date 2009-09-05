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

### \brief ReMake package and file discovery macros
#   The ReMake package and file discovery macros provide a useful abstraction
#   to CMake's native find functionalities.

### \brief Find a package.
#   This macro calls CMake's find_package() to find and load settings from an 
#   external project installed on the system. If the package was found, 
#   essential variables are initialized and the upper-case conversion
#   of ${PACKAGE}_FOUND is set to TRUE. Arguments given in addition to the
#   package name are forwarded to find_package() and remake_find_result().
#   \required[value] package The name of the package to be discovered. Note
#     that CMake module naming conventions require the exact casing of
#     package names here, usually starting with a capital letter.
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_package() and remake_find_result(). See the CMake
#     documentation for the correct usage of find_package().
macro(remake_find_package find_package)
  remake_var_name(find_package_var ${find_package} FOUND)

  find_package(${find_package} ${ARGN})
  remake_find_result(${find_package} ${${find_package_var}} ${ARGN})
endmacro(remake_find_package)

### \brief Find a library and it's header file.
#   This macro calls CMake's find_library() and find_path() to discover
#   a library and it's main header file installed on the system. If the 
#   library and the header were found, the upper-case conversion of 
#   ${PACKAGE}_FOUND is set to TRUE. Arguments given in addition to the
#   library and header name are forwarded to find_library(), find_path(), 
#   and remake_find_result().
#   \required[value] library The name of the library to be discovered.
#   \required[value] header The name of the header to be discovered.
#   \optional[value] PACKAGE:package The name of the package containing the
#     requested library, defaults to the provided library name and is used
#     to set ${PACKAGE}_FOUND and the PATH_SUFFIXES argument for find_path().
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_library(), find_path(), and remake_find_result().
#     See the CMake documentation for the correct usage of find_library()
#     and find_path().
macro(remake_find_library find_lib find_header)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_lib})
  remake_var_name(find_lib_var ${find_package} LIBRARY)
  remake_var_name(find_headers_var ${find_package} HEADERS)

  find_library(${find_lib_var} NAMES ${find_lib} ${args})
  if(${find_lib_var})
    find_path(${find_headers_var} NAMES ${find_header} 
      PATH_SUFFIXES ${find_package} ${args})
  else(${find_lib_var})
    remake_set(${find_headers_var})
  endif(${find_lib_var})

  remake_find_result(${find_package} ${${find_headers_var}} ${args})
endmacro(remake_find_library)

### \brief Find an executable program.
#   This macro calls CMake's find_program() to discover an executable
#   installed on the system. If the executable was found, the upper-case
#   conversion of ${PACKAGE}_FOUND is set to TRUE. Arguments given in 
#   addition to the executable name are forwarded to find_program()
#   and remake_find_result().
#   \required[value] executable The name of the executable to be discovered.
#   \optional[value] PACKAGE:package The name of the package containing the
#     requested executable, defaults to the upper-case conversion of the 
#     executable name and is used to set ${PACKAGE}_FOUND.
#   \optional[list] arg A list of optional arguments to be forwared to
#     CMake's find_program() and remake_find_result(). See the CMake
#     documentation for the correct usage of find_program().
macro(remake_find_executable find_exec)
  remake_arguments(prefix find_ VAR PACKAGE ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_exec})
  remake_var_name(find_exec_var ${find_package} EXECUTABLE)  

  find_program(${find_exec_var} NAMES ${find_exec})

  remake_find_result(${find_package} ${${find_exec_var}} ${ARGN})
endmacro(remake_find_executable)

### \brief Evaluate the result of a find operation.
#   This macro is a helper macro to evaluate the result of a find operation.
#   It gets invoked by the specific find macros defined in this module
#   and should not be called directly from a CMakeLists.txt file. The macro's
#   main purpose is to emit a message on the result of the find operation and
#   to set the ${PACKAGE}_FOUND variable. 
#   \required[value] package The name of the package that was to be found.
#   \optional[option] OPTIONAL If provided, a negative result will
#     not lead to a fatal error but to a warning message instead.
#   \required[value] result The find result returned to the calling macro,
#     usually depends on the macro-specific find operation.
macro(remake_find_result find_package)
  remake_arguments(PREFIX find_ OPTION OPTIONAL ARGN result ${ARGN})
  remake_var_name(find_result_var ${find_package} FOUND)

  if(find_result)
    remake_set(${find_result_var} TRUE)
  else(find_result)
    remake_set(${find_result_var} FALSE)
    if(find_optional)
      message(STATUS "Missing ${find_package} support!")
    else(find_optional)
      message(FATAL_ERROR "Missing ${find_package} support!")
    endif(find_optional)    
  endif(find_result)
endmacro(remake_find_result)
