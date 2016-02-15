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

### \brief ReMake pkg-config support
#   The ReMake pkg-config macros provide support for generating pkg-config
#   files from ReMake projects. Such files are particularly useful when
#   deploying projects which consist in multiple libraries. Another ReMake
#   project may then greatly benefit from calling remake_find_package()
#   with the CONFIG option supplied, and conveniently pass the delivered
#   variable values to the build commands of its dependent library or
#   executable targets. See ReMakeFind for additional details.

include(ReMakePrivate)
include(ReMakeFile)

if(NOT DEFINED REMAKE_PKG_CONFIG_CMAKE)
  remake_set(REMAKE_PKG_CONFIG_CMAKE ON)

  remake_set(REMAKE_PKG_CONFIG_DIR ReMakePkgConfig)
  remake_file_rmdir(${REMAKE_PKG_CONFIG_DIR} TOPLEVEL)
else(NOT DEFINED REMAKE_PKG_CONFIG_CMAKE)
  return()
endif(NOT DEFINED REMAKE_PKG_CONFIG_CMAKE)

include(ReMakeComponent)

### \brief Configure ReMake pkg-config support.
#   This macro discovers the pkg-config executable and configures pkg-config
#   file generation support. It initializes a project variable named
#   PKG_CONFIG_DESTINATION that holds the default install destination
#   of all pkg-config files and defaults to lib/pkgconfig relative to
#   ${CMAKE_INSTALL_PREFIX}. Note that the macro automatically gets invoked
#   by the macros defined in this module. It needs not be called directly
#   from a CMakeLists.txt file.
macro(remake_pkg_config)
  if(NOT PKG_CONFIG_FOUND)
    remake_find_executable(pkg-config)
  endif(NOT PKG_CONFIG_FOUND)

  remake_file(pkg_config_dir ${REMAKE_PKG_CONFIG_DIR} TOPLEVEL)
  if(NOT IS_DIRECTORY pkg_config_dir)
    remake_project_set(PKG_CONFIG_DESTINATION lib/pkgconfig
      CACHE PATH "Install destination of pkg-config files.")
    remake_file_mkdir(${pkg_config_dir})
  endif(NOT IS_DIRECTORY pkg_config_dir)
endmacro(remake_pkg_config)

### \brief Generate a component's pkg-config file.
#   This macro generates a pkg-config file for the specified components of
#   the ReMake project. It queries and analyzes the component variables in
#   order to fill the required fields of the pkg-config file during the
#   configuration run of CMake. An install rule is then defined for the
#   generated file by calling remake_component_install() and passing
#   ${INSTALL_COMPONENT} as install component. See ReMakeComponent for
#   further information.
#   \optional[value] COMPONENT:component The name of the component from
#     which to populate the binary-related fields of the pkg-config file,
#     defaults to ${REMAKE_COMPONENT}.
#   \optional[value] DEV_COMPONENT:component The name of the component from
#     which to populate the header-related fields of the pkg-config file,
#     defaults to ${COMPONENT}-${REMAKE_COMPONENT_DEVEL_SUFFIX}.
#   \optional[value] INSTALL_COMPONENT:component The name of the component
#     for which to install the pkg-config file, defaults to ${DEV_COMPONENT}.
#   \optional[value] FILENAME:filename The name of the generated pkg-config
#     file, defaults to the component-specific filename for ${COMPONENT}
#     with the .pc file extension. See ReMakeComponent for further information.
#   \optional[value] NAME:name The component's name as indicated in the
#     pkg-config file, defaults to ${REMAKE_PROJECT_NAME} with the
#     component name appended in parentheses.
#   \optional[value] DESCRIPTION:string An optional description of the
#     install component that is appended to the project summary when
#     generating the pkg-config file.
#   \optional[list] REQUIRES:dep An optional list of requirements or
#     dependencies to be listed in the corresponding field of the
#     pkg-config file. Note that, for each requirement, a pkg-config file
#     with the same name must exist in the search path of pkg-config.
#   \optional[list] EXTRA_CFLAGS:flag An optional list of compiler flags to
#     be appended to the default flag for including the components
#     header destination.
#   \optional[list] EXTRA_LIBS:flag An optional list of linker flags to
#     be appended to the default flags. These include the linker flag
#     for searching the component's library destination and the flags
#     for linking against all libraries being installed by the component.
macro(remake_pkg_config_generate)
  remake_arguments(PREFIX pkg_config_ VAR COMPONENT VAR DEV_COMPONENT
    VAR INSTALL_COMPONENT VAR FILENAME VAR NAME VAR DESCRIPTION
    LIST REQUIRES LIST EXTRA_CFLAGS LIST EXTRA_LIBS ${ARGN})
  remake_set(pkg_config_component SELF DEFAULT ${REMAKE_COMPONENT})
  if(${pkg_config_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})
    remake_set(pkg_config_name SELF DEFAULT "${REMAKE_PROJECT_NAME}")
  else(${pkg_config_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})
    remake_set(pkg_config_name SELF DEFAULT
      "${REMAKE_PROJECT_NAME} (${pkg_config_component})")
  endif(${pkg_config_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})
  remake_component_name(pkg_config_dev_component_default
    ${pkg_config_component} ${REMAKE_COMPONENT_DEVEL_SUFFIX})
  remake_set(pkg_config_dev_component SELF DEFAULT
    ${pkg_config_dev_component_default})
  remake_set(pkg_config_install_component SELF DEFAULT
    ${pkg_config_dev_component})
  remake_component_get(${pkg_config_component} FILENAME
    OUTPUT pkg_config_filename_default)
  remake_set(pkg_config_filename SELF DEFAULT
    ${pkg_config_filename_default}.pc)

  remake_pkg_config()

  remake_file(pkg_config_file
    "${REMAKE_PKG_CONFIG_DIR}/${pkg_config_filename}" TOPLEVEL)
  remake_component_get(${pkg_config_component} INSTALL_PREFIX
    OUTPUT pkg_config_prefix)
  remake_file_write(${pkg_config_file} LINES
    "prefix=${pkg_config_prefix}")
  remake_file_write(${pkg_config_file} LINES
    "exec_prefix=\\\\\\\${prefix}")
  remake_component_get(${pkg_config_dev_component} INSTALL_PREFIX
    OUTPUT pkg_config_include_prefix)
  if(pkg_config_include_prefix STREQUAL pkg_config_prefix)
    remake_file_write(${pkg_config_file} LINES
      "include_prefix=\\\\\\\${prefix}")
  else(pkg_config_include_prefix STREQUAL pkg_config_prefix)
    remake_file_write(${pkg_config_file} LINES
      "include_prefix=${pkg_config_include_prefix}")
  endif(pkg_config_include_prefix STREQUAL pkg_config_prefix)

  remake_component_get(${pkg_config_component} LIBRARY_DESTINATION
    OUTPUT pkg_config_library_destination)
  if(IS_ABSOLUTE ${pkg_config_library_destination})
    remake_file_write(${pkg_config_file} LINES
      "libdir=${pkg_config_library_destination}")
  else(IS_ABSOLUTE ${pkg_config_library_destination})
    remake_file_write(${pkg_config_file} LINES
      "libdir=\\\\\\\${prefix}/${pkg_config_library_destination}")
  endif(IS_ABSOLUTE ${pkg_config_library_destination})

  remake_component_get(${pkg_config_dev_component} HEADER_DESTINATION
    OUTPUT pkg_config_header_destination)
  if(IS_ABSOLUTE ${pkg_config_header_destination})
    remake_file_write(${pkg_config_file} LINES
      "includedir=${pkg_config_header_destination}\n")
  else(IS_ABSOLUTE ${pkg_config_header_destination})
    remake_file_write(${pkg_config_file} LINES
      "includedir=\\\\\\\${include_prefix}/${pkg_config_header_destination}\n")
  endif(IS_ABSOLUTE ${pkg_config_header_destination})

  remake_file_write(${pkg_config_file} LINES
    "Name: ${pkg_config_name}")
  string(REGEX REPLACE "[.]$" "" pkg_config_summary ${REMAKE_PROJECT_SUMMARY})
  if(pkg_config_description)
    remake_file_write(${pkg_config_file} LINES
      "Description: ${pkg_config_summary} (${pkg_config_description})")
  else(pkg_config_description)
    remake_file_write(${pkg_config_file} LINES
      "Description: ${pkg_config_summary}")
  endif(pkg_config_description)
  remake_file_write(${pkg_config_file} LINES
    "Version: ${REMAKE_PROJECT_FILENAME_VERSION}")
  remake_set(pkg_config_cflags ${pkg_config_extra_cflags})
  if(pkg_config_cflags)
    string(REGEX REPLACE ";" " " pkg_config_cflags "${pkg_config_cflags}")
  endif(pkg_config_cflags)
  remake_file_write(${pkg_config_file} LINES
    "Cflags: -I\\\\\\\${includedir} ${pkg_config_cflags}")
  remake_component_get(${pkg_config_component} LIBRARIES
    OUTPUT pkg_config_libraries)
  if(pkg_config_libraries)
    string(REGEX REPLACE ";" " ;-l" pkg_config_libs
      "-l${pkg_config_libraries}")
  endif(pkg_config_libraries)
  remake_list_push(pkg_config_libs ${pkg_config_extra_libs})
  if(pkg_config_libs)
    string(REGEX REPLACE ";" " " pkg_config_libs "${pkg_config_libs}")
  endif(pkg_config_libs)
  remake_file_write(${pkg_config_file} LINES
    "Libs: -L\\\\\\\${libdir} ${pkg_config_libs}")

  if(pkg_config_requires)
    string(REGEX REPLACE ";" " " pkg_config_reqs "${pkg_config_requires}")
    remake_file_write(${pkg_config_file} LINES
      "Requires: ${pkg_config_reqs}")
  endif(pkg_config_requires)

  remake_project_get(PKG_CONFIG_DESTINATION)
  remake_component_install(
    FILES ${pkg_config_file}
    DESTINATION ${PKG_CONFIG_DESTINATION}
    COMPONENT ${pkg_config_install_component})
endmacro(remake_pkg_config_generate)
