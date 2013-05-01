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

include(ReMakeFile)
include(ReMakeList)

include(ReMakePrivate)

### \brief ReMake multi-project recursion macros
#   The ReMake recursion macros extend the CMake build system facilities
#   into multi-project environments. Recursion support exists for selected
#   build system types.

if(NOT DEFINED REMAKE_RECURSE_CMAKE)
  remake_set(REMAKE_RECURSE_CMAKE ON)

  remake_set(REMAKE_RECURSE_ALL_TARGET recursions)
  remake_set(REMAKE_RECURSE_TARGET_SUFFIX recursion)
  remake_set(REMAKE_RECURSE_CONFIGURE_ALL_TARGET recursions_configure)
  remake_set(REMAKE_RECURSE_CONFIGURE_TARGET_SUFFIX configure)
  remake_set(REMAKE_RECURSE_BUILD_ALL_TARGET recursions_build)
  remake_set(REMAKE_RECURSE_BUILD_TARGET_SUFFIX build)
  remake_set(REMAKE_RECURSE_INSTALL_ALL_TARGET recursions_install)
  remake_set(REMAKE_RECURSE_INSTALL_TARGET_SUFFIX install)
  remake_set(REMAKE_RECURSE_CLEAN_ALL_TARGET recursions_clean)
  remake_set(REMAKE_RECURSE_CLEAN_TARGET_SUFFIX clean)
endif(NOT DEFINED REMAKE_RECURSE_CMAKE)

### \brief Recurse into a Make project.
#   This macro adds recursion targets for a classical Makefile-based project.
#   Note that the Make build system does not require a configuration step.
#   However, the macro assumes the project to implement the standard targets
#   all, install, and clean.
#   \required[value] name The name of the Make project to be recursed.
#   \optional[value] PATH:path The path of the directory containing the
#     Make project along with its top-level Makefile, defaults to the
#     directory name conversion of the given project name under
#     ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] arg Additional arguments to be passed to remake_recurse().
macro(remake_recurse_make recurse_name)
  remake_arguments(PREFIX recurse_ VAR PATH ARGN args ${ARGN})
  remake_file_name(recurse_filename ${recurse_name})
  remake_set(recurse_path SELF
    DEFAULT ${CMAKE_CURRENT_SOURCE_DIR}/${recurse_filename})

  remake_recurse(Make ${recurse_name} ${recurse_path}
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    CLEAN_COMMAND make clean
    ${recurse_args})
endmacro(remake_recurse_make)

### \brief Recurse into a CMake project.
#   This macro adds recursion targets for a CMake-based project.
#   The CMake build system requires a configuration step to generate a
#   Makefile implementing the standard targets all, install, and clean.
#   \required[value] name The name of the CMake project to be recursed.
#   \optional[value] PATH:path The path of the directory containing the
#     CMake project along with its top-level CMakeLists.txt file,
#     defaults to the directory name conversion of the given project name
#     under ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] PASS:var An optional list containing the names of
#     defined CMake variables. The macro will pass the given variable names
#     and values during the configuration stage of the recursed project.
#     By default, the variables CMAKE_MODULE_PATH, CMAKE_BUILD_TYPE,
#     CMAKE_INSTALL_PREFIX, and CMAKE_INSTALL_RPATH are included in the list.
#   \optional[list] DEFINE:var An optional list of variable names and values
#     of the form ${VAR}=${VALUE} to be passed during the configuration
#     stage of the recursed project.
#   \optional[list] arg Additional arguments to be passed to remake_recurse().
macro(remake_recurse_cmake recurse_name)
  remake_arguments(PREFIX recurse_ VAR PATH LIST PASS LIST DEFINE
    LIST CONFIGURE_DEPENDS LIST BUILD_DEPENDS LIST INSTALL_DEPENDS ${ARGN})
  remake_set(recurse_path SELF
    DEFAULT ${CMAKE_CURRENT_SOURCE_DIR}/${recurse_name})
  remake_set(recurse_pass SELF
    DEFAULT CMAKE_MODULE_PATH CMAKE_BUILD_TYPE CMAKE_INSTALL_PREFIX
      CMAKE_INSTALL_RPATH)

  remake_set(recurse_build_path ${CMAKE_CURRENT_BINARY_DIR}/${recurse_name})
  remake_file_mkdir(${recurse_build_path})

  remake_set(recurse_definitions)
  foreach(recurse_var ${recurse_pass})
    remake_list_push(recurse_definitions -D${recurse_var}=${${recurse_var}})
  endforeach(recurse_var)
  foreach(recurse_var ${recurse_define})
    remake_list_push(recurse_definitions -D${recurse_var})
  endforeach(recurse_var)

  remake_recurse(CMake ${recurse_name} ${recurse_build_path}
    CONFIGURE_COMMAND cmake ${recurse_definitions} ${recurse_path}
    CONFIGURE_INPUT ${recurse_path}/CMakeLists.txt
    CONFIGURE_OUTPUT ${recurse_build_path}/CMakeCache.txt
      ${recurse_build_path}/Makefile
    ${CONFIGURE_DEPENDS}
    BUILD_COMMAND make
    ${BUILD_DEPENDS}
    INSTALL_COMMAND make install
    ${INSTALL_DEPENDS}
    CLEAN_COMMAND make clean)
endmacro(remake_recurse_cmake)

### \brief Recurse into a QMake project.
#   This macro adds recursion targets for a QMake-based project.
#   The QMake build system requires a configuration step to generate a
#   Makefile implementing the standard targets all, install, and clean.
#   \required[value] name The name of the QMake project to be recursed.
#   \optional[value] PATH:path The path of the directory containing the
#     QMake project along with its project file, defaults to the
#     directory name conversion of the given project name under
#     ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[value] PROJECT_FILE:filename The name of the QMake project
#     file, defaults to the filename conversion of the given project name
#     and the standard extension .pro.
#   \optional[list] arg Additional arguments to be passed to remake_recurse().
macro(remake_recurse_qmake recurse_name)
  remake_arguments(PREFIX recurse_ VAR PATH VAR PROJECT_FILE ARGN args
    ${ARGN})
  remake_file_name(recurse_filename ${recurse_name})
  remake_set(recurse_path SELF
    DEFAULT ${CMAKE_CURRENT_SOURCE_DIR}/${recurse_filename})
  remake_set(recurse_project_file SELF
    DEFAULT ${recurse_path}/${recurse_filename}.pro)

  remake_recurse(QMake ${recurse_name} ${recurse_path}
    CONFIGURE_COMMAND qmake ${recurse_project_file}
    CONFIGURE_INPUT ${recurse_project_file}
    CONFIGURE_OUTPUT ${recurse_path}/Makefile
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    CLEAN_COMMAND make clean
    ${recurse_args})
endmacro(remake_recurse_qmake)

### \brief Define project recursion rules.
#   This macro is a helper macro to define configuration, build, install, and
#   cleaning rules for recursion into another project. Note that the macro
#   gets invoked by the build system-specific macros defined in this module.
#   In most cases, it will therefore not be necessary to call it directly
#   from a CMakeLists.txt file.
#   Note that the macro will define one target for each of the rules
#   associated with the given project. The targets will be named
#   ${PROJECT_NAME}_configure, ${PROJECT_NAME}_build, ${PROJECT_NAME}_install,
#   and ${PROJECT_NAME}_clean. Thus, they may be used in order to define
#   dependencies between the recursion rules of different projects.
#   \required[value] build_system The build system name of the project to be
#     recursed.
#   \required[value] name The name of the project to be recursed.
#   \required[value] build_path The build path of the project, i.e. the path
#     to the intended working directory of all stage commands.
#   \optional[value] CONFIGURE_COMMAND:command The optional command that
#     should be invoked during the configuration stage of the recursed
#     project.
#   \optional[list] CONFIGURE_INPUT:filename An optional list of filenames
#     that identify the input files to the configuration stage.
#   \optional[list] CONFIGURE_OUTPUT:filename An optional list of filenames
#     that identify the output files to the configuration stage.
#   \optional[list] CONFIGURE_DEPENDS:target An optional list containing
#     the names of defined targets the configuration stage depends on.
#   \optional[value] BUILD_COMMAND:command The optional command that
#     should be invoked during the build stage of the recursed project.
#   \optional[list] BUILD_DEPENDS:target An optional list containing
#     the names of defined targets the build stage depends on.
#   \optional[value] INSTALL_COMMAND:command The optional command that
#     should be invoked during the install stage of the recursed project.
#   \optional[list] INSTALL_DEPENDS:target An optional list containing
#     the names of defined targets the install stage depends on.
#   \optional[value] CLEAN_COMMAND:command The optional command that
#     should be invoked during the cleaning stage of the recursed project.
macro(remake_recurse recurse_build_system recurse_name recurse_build_path)
  remake_arguments(PREFIX recurse_ LIST CONFIGURE_COMMAND
    LIST CONFIGURE_INPUT LIST CONFIGURE_OUTPUT LIST CONFIGURE_DEPENDS
    LIST BUILD_COMMAND LIST BUILD_DEPENDS
    LIST INSTALL_COMMAND LIST INSTALL_DEPENDS
    LIST CLEAN_COMMAND ${ARGN})

  remake_set(recurse_depends ${recurse_configure_depends}
    ${recurse_build_depends} ${recurse_install_depends})
  if(recurse_depends)
    string(REPLACE ";" ", " recurse_dependencies "${recurse_depends}")
    message(STATUS "Recursion: ${recurse_name}, depending on "
      "${recurse_dependencies}")
  else(recurse_depends)
    message(STATUS "Recursion: ${recurse_name}")
  endif(recurse_depends)

  if(NOT TARGET ${REMAKE_RECURSE_ALL_TARGET})
    remake_target(${REMAKE_RECURSE_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_RECURSE_ALL_TARGET})

  remake_set(recurse_configure_target)
  if(recurse_configure_command)
    if(NOT TARGET ${REMAKE_RECURSE_CONFIGURE_ALL_TARGET})
      remake_target(${REMAKE_RECURSE_CONFIGURE_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_RECURSE_CONFIGURE_ALL_TARGET})

    add_custom_command(
      COMMAND ${recurse_configure_command}
      DEPENDS ${recurse_configure_input}
      OUTPUT ${recurse_configure_output}
      WORKING_DIRECTORY ${recurse_build_path}
      COMMENT "Configuring ${recurse_build_system} project ${recurse_name}")
    remake_target_name(recurse_configure_target ${recurse_name}
      ${REMAKE_RECURSE_CONFIGURE_TARGET_SUFFIX})
    remake_target(${recurse_configure_target}
      DEPENDS ${recurse_configure_output})
    foreach(recurse_configure_dep ${recurse_configure_depends})
      add_dependencies(${recurse_configure_target} ${recurse_configure_dep})
    endforeach(recurse_configure_dep)
    add_dependencies(${REMAKE_RECURSE_CONFIGURE_ALL_TARGET}
      ${recurse_configure_target})
  endif(recurse_configure_command)

  remake_set(recurse_build_target)
  if(recurse_build_command)
    if(NOT TARGET ${REMAKE_RECURSE_BUILD_ALL_TARGET})
      remake_target(${REMAKE_RECURSE_BUILD_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_RECURSE_BUILD_ALL_TARGET})

    remake_target_name(recurse_build_target ${recurse_name}
      ${REMAKE_RECURSE_BUILD_TARGET_SUFFIX})
    remake_target(${recurse_build_target} ALL ${recurse_build_command}
      WORKING_DIRECTORY ${recurse_build_path}
      COMMENT "Building ${recurse_build_system} project ${recurse_name}")
    foreach(recurse_build_dep ${recurse_build_depends})
      add_dependencies(${recurse_build_target} ${recurse_build_dep})
    endforeach(recurse_build_dep)
    if(recurse_configure_target)
      add_dependencies(${recurse_build_target} ${recurse_configure_target})
    endif(recurse_configure_target)
    add_dependencies(${REMAKE_RECURSE_BUILD_ALL_TARGET}
      ${recurse_build_target})
  endif(recurse_build_command)

  remake_set(recurse_install_target)
  if(recurse_install_command)
    if(NOT TARGET ${REMAKE_RECURSE_INSTALL_ALL_TARGET})
      remake_target(${REMAKE_RECURSE_INSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_RECURSE_INSTALL_ALL_TARGET})

    remake_target_name(recurse_install_target ${recurse_name}
      ${REMAKE_RECURSE_INSTALL_TARGET_SUFFIX})
    remake_target(${recurse_install_target} ${recurse_install_command}
      WORKING_DIRECTORY ${recurse_build_path}
      COMMENT "Installing ${recurse_build_system} project ${recurse_name}")
    foreach(recurse_install_dep ${recurse_install_depends})
      add_dependencies(${recurse_install_target} ${recurse_install_dep})
    endforeach(recurse_install_dep)
    if(recurse_build_target)
      add_dependencies(${recurse_install_target} ${recurse_build_target})    
    endif(recurse_build_target)
    install(CODE "execute_process(COMMAND make ${recurse_install_target}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR})")
    add_dependencies(${REMAKE_RECURSE_INSTALL_ALL_TARGET}
      ${recurse_install_target})
  endif(recurse_install_command)

  if(recurse_clean_command)
    if(NOT TARGET ${REMAKE_RECURSE_CLEAN_ALL_TARGET})
      remake_target(${REMAKE_RECURSE_CLEAN_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_RECURSE_CLEAN_ALL_TARGET})

    remake_target_name(recurse_clean_target ${recurse_name}
      ${REMAKE_RECURSE_CLEAN_TARGET_SUFFIX})
    remake_target(${recurse_clean_target} ${recurse_clean_command}
      WORKING_DIRECTORY ${recurse_build_path}
      DEPENDS ${recurse_configure_output}
      COMMENT "Cleaning ${recurse_build_system} project ${recurse_name}")
    add_dependencies(${REMAKE_RECURSE_CLEAN_ALL_TARGET}
      ${recurse_clean_target})
  endif(recurse_clean_command)
endmacro(remake_recurse)
