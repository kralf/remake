############################################################################
#    Copyright (C) 2013 by Ralf Kaestner                                   #
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

if(NOT DEFINED REMAKE_FIND_CMAKE)
  remake_set(REMAKE_FIND_CMAKE ON)
endif(NOT DEFINED REMAKE_FIND_CMAKE)

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
#     module name to pkg_check_modules(). Note that, when cross-compiling,
#     the default pkg-config system root directory and search directory may
#     be overridden by the toolchain variables
#     ${REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR} and
#     ${REMAKE_FIND_PKG_CONFIG_LIBRARY_DIR}, respectively.
#   \optional[value] ALIAS:alias An optional package alias that is used for
#     evaluating if the upper-case conversion of ${ALIAS}_FOUND is set to TRUE.
#     The alias has to be provided in cases where the package name differs from
#     the variable prefix assumed by CMake's find_package().
#   \optional[value] RESULT_VAR:variable The optional name of the variable that
#     will contain the result of CMake's find_package() or pkg_check_modules().
#     This argument should be provided if the name of the result variable
#     defined by CMake's modules is different from the upper-case conversion
#     of ${PACKAGE}_FOUND.
#   \optional[list] arg A list of optional arguments to be forwarded to
#     CMake's find_package() and pkg_check_modules(), respectively. See the
#     CMake documentation for the correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_package find_package)
  remake_arguments(PREFIX find_ OPTION CONFIG VAR ALIAS VAR RESULT_VAR
    OPTION OPTIONAL ARGN args ${ARGN})
  remake_var_name(find_pkg_var ${find_package} FOUND)
  if(find_alias)
    remake_var_name(find_default_result_var ${find_alias} FOUND)
  else(find_alias)
    remake_set(find_default_result_var ${find_pkg_var})
  endif(find_alias)
  remake_set(find_result_var SELF DEFAULT ${find_default_result_var})

  if(NOT ${find_pkg_var})
    if(find_config)
      remake_set(find_args SELF DEFAULT ${find_package})

      if(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR)
        remake_set(ENV{PKG_CONFIG_SYSROOT_DIR}
          ${REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR})
      endif(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR)
      if(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_DIR)
        string(REGEX REPLACE ";" ":" PKG_CONFIG_PATH
          "${REMAKE_FIND_PKG_CONFIG_DIR}")
        remake_set(ENV{PKG_CONFIG_PATH} ${PKG_CONFIG_PATH})
        string(REGEX REPLACE ";" ":" PKG_CONFIG_LIBDIR
          "${REMAKE_FIND_PKG_CONFIG_DIR}")
        remake_set(ENV{PKG_CONFIG_LIBDIR} ${PKG_CONFIG_LIBDIR})
      endif(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_DIR)

      if(find_alias)
        remake_var_name(find_prefix ${find_alias})
      else(find_alias)
        remake_var_name(find_prefix ${find_package})
      endif(find_alias)
      pkg_check_modules(${find_prefix} ${find_args})
    else(find_config)
      find_package(${find_package} ${find_args})
    endif(find_config)
        
    remake_find_result(${find_package} ${${find_result_var}}
      TYPE package ${OPTIONAL})
  endif(NOT ${find_pkg_var})
endmacro(remake_find_package)

### \brief Find a library and it's header file.
#   This macro calls CMake's find_library() and find_path() to discover
#   a library and it's header files installed on the system. If the
#   library and the header were found, the variable name conversion of
#   ${LIBRARY}_FOUND is set to TRUE. Furthermore, ${LIBRARY}_LIBRARY and
#   ${LIBRARY}_HEADERS are initialized for linkage and header inclusion.
#   Arguments given in addition to the library and header name are forwarded
#   to find_library() and find_path(). If the library could not be found
#   in a standard location, the macro searches the ldconfig cache in addition
#   and passes hints to CMake's find_library().
#   \required[value] library The name of the library to be discovered.
#   \required[value] header The name of the header to be discovered.
#   \optional[value] PACKAGE:package The name of the package containing the
#     requested library, defaults to the provided library name and is used
#     for display and to set the PATH_SUFFIXES argument for find_path().
#   \optional[list] arg A list of optional arguments to be forwarded to
#     CMake's find_library() and find_path(). See the CMake documentation
#     for correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_library find_lib find_header)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args OPTION OPTIONAL ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_lib})
  remake_var_name(find_lib_var ${find_lib} LIBRARY)
  remake_var_name(find_headers_var ${find_lib} HEADERS)

  remake_set(find_shared_prefix ${CMAKE_SHARED_LIBRARY_PREFIX})
  remake_set(find_shared_suffix ${CMAKE_SHARED_LIBRARY_SUFFIX})
  remake_set(find_static_prefix ${CMAKE_STATIC_LIBRARY_PREFIX})
  remake_set(find_static_suffix ${CMAKE_STATIC_LIBRARY_SUFFIX})

  find_library(${find_lib_var} NAMES ${find_lib} ${find_args})

  if(NOT ${find_lib_var})
    execute_process(COMMAND ldconfig -p
      OUTPUT_VARIABLE find_lib_ld ERROR_QUIET)
    if(find_lib_ld MATCHES "[ ]*${find_shared_prefix}${find_lib}[.]")
      string(REGEX MATCH "[ ]*${find_shared_prefix}${find_lib}[.][^\\\n]*"
        find_lib_ld "${find_lib_ld}")
      string(REGEX MATCH "[^ ]+$" find_lib_ld "${find_lib_ld}")
      get_filename_component(find_lib_hint "${find_lib_ld}" PATH)

      find_library(${find_lib_var} NAMES ${find_lib} HINTS ${find_lib_hint})
    endif(find_lib_ld MATCHES "[ ]*${find_shared_prefix}${find_lib}[.]")
  endif(NOT ${find_lib_var})

  remake_find_result(
    ${find_package} ${${find_lib_var}}
    NAME ${find_lib}
    TYPE library
    FILES "${find_shared_prefix}${find_lib}${find_shared_suffix}"
      "${find_static_prefix}${find_lib}${find_static_suffix}"
    ${OPTIONAL})

  if(${find_lib_var})
    remake_file_name(find_path_suffix ${find_package})
    find_path(${find_headers_var} NAMES ${find_header}
      PATH_SUFFIXES ${find_path_suffix} ${find_args})
  else(${find_lib_var})
    remake_set(${find_headers_var})
  endif(${find_lib_var})

  remake_find_result(
    ${find_package} ${${find_headers_var}}
    NAME ${find_header}
    TYPE header
    FILES ${find_header}
    ${OPTIONAL})
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
#   \optional[list] arg A list of optional arguments to be forwarded to
#     CMake's find_program(). See the CMake documentation for correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_executable find_exec)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args OPTION OPTIONAL ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_exec})
  remake_var_name(find_exec_var ${find_package} EXECUTABLE)

  find_program(${find_exec_var} NAMES ${find_exec} ${find_args})

  remake_find_result(
    ${find_package} ${${find_exec_var}}
    NAME ${find_exec}
    TYPE executable
    FILES ${find_exec}
    ${OPTIONAL})
endmacro(remake_find_executable)

### \brief Find a file.
#   This macro calls CMake's find_path() to discover the full path to a file
#   installed on the system. If the file was found, the variable name
#   conversion of ${PACKAGE}_FOUND is set to TRUE. Furthermore,
#   ${PACKAGE}_PATH is initialized with the full path to the file.
#   Arguments given in addition to the file name are forwarded to
#   find_path().
#   \required[value] file The name of the file to be discovered.
#   \required[value] PACKAGE:package The name of the package containing the
#     requested file which is used to set ${PACKAGE}_FOUND.
#   \optional[list] arg A list of optional arguments to be forwarded to
#     CMake's find_path(). See the CMake documentation for correct usage.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_find_file find_file)
  remake_arguments(PREFIX find_ VAR PACKAGE ARGN args OPTION OPTIONAL ${ARGN})
  remake_var_name(find_path_var ${find_package} PATH)

  find_path(${find_path_var} NAMES ${find_file} ${find_args})

  remake_find_result(
    ${find_package} ${${find_path_var}}
    NAME ${find_file}
    TYPE file
    FILES ${find_file}
    ${OPTIONAL})
endmacro(remake_find_file)

### \brief Evaluate the result of a find operation.
#   This macro is a helper macro to evaluate the result of a find operation.
#   It gets invoked by the specific find macros defined in this module
#   and should not be called directly from a CMakeLists.txt file. The macro's
#   main purpose is to emit a message on the result of the find operation and
#   to set the ${PACKAGE}_FOUND cache variable.
#   \required[value] package The name of the package supposedly containing
#     the object that was to be found. If no object name is provided with the
#     macro arguments, it is the package itself that was to be found.
#   \optional[value] NAME:name The optional name of the object that was to
#     be found. If this argument is not supplied, it is the package itself
#     that was to be found.
#   \required[value] TYPE:type The type of object that was to be found,
#     defaulting to package.
#   \optional[list] FILES:filename An optional list naming any files which
#     may indicate the installation candidates for the sought object. In
#     Debian Linux, each filename is passed to remake_debian_find_file()
#     to generate a list of candidate packages in case of a negative result.
#   \optional[option] OPTIONAL If provided, a negative result will
#     not lead to a fatal error but to a warning message instead.
#   \required[value] result The find result returned to the calling macro,
#     usually depends on the macro-specific find operation.
macro(remake_find_result find_package)
  remake_arguments(PREFIX find_ VAR TYPE VAR NAME LIST FILES OPTION OPTIONAL
    ARGN result ${ARGN})
  remake_set(find_type SELF DEFAULT package)
  remake_var_name(find_result_var ${find_package} FOUND)

  if(find_name)
    remake_set(find_description
      "Found ${find_package} ${find_type} ${find_name}.")
  else(find_name)
    remake_set(find_description
      "Found ${find_type} ${find_package}.")
  endif(find_name)

  if(find_result)
    remake_set(${find_result_var} ON CACHE BOOL ${find_description} FORCE)
  else(find_result)
    remake_set(${find_result_var} OFF CACHE BOOL ${find_description} FORCE)
  
    if(find_name)
      remake_set(find_message
        "Missing ${find_type} ${find_name}!")
    else(find_name)
      remake_set(find_message "Missing ${find_type} ${find_package}!")
    endif(find_name)

    if(NOT find_optional)
      remake_unset(find_candidates)
      if(find_files)
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
          foreach(find_file ${find_files})
            remake_debian_find_file(${find_file} OUTPUT find_candidate)
            remake_list_push(find_candidates ${find_candidate})
          endforeach(find_file)
        endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      endif(find_files)
      if(find_candidates)
        remake_list_remove_duplicates(find_candidates)
        string(REGEX REPLACE ";" ", " find_candidates "${find_candidates}")
        remake_set(find_message
          "${find_message}\nInstallation candidate(s): ${find_candidates}")
      else(find_candidates)
        remake_set(find_message "${find_message}\nNo installation candidates.")
      endif(find_candidates)
      message(FATAL_ERROR "${find_message}")
    else(NOT find_optional)
      message(STATUS "Warning: ${find_message}")
    endif(NOT find_optional)
  endif(find_result)
endmacro(remake_find_result)
