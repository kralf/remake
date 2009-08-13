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

### \brief ReMake packaging macros
#   The ReMake packaging macros have been designed to provide simple and
#   transparent package generation using CMake's CPack module.

remake_set(REMAKE_PACK_ALL_TARGET packages)
remake_set(REMAKE_PACK_TARGET package)
remake_set(REMAKE_PACK_INSTALL_TARGET package_install)

remake_set(REMAKE_PACK_DIR ReMakePackages)
remake_set(REMAKE_PACK_SOURCE_DIR ReMakeSourcePackages)

### \brief Generate packages from a ReMake project.
#   This macro generally configures package generation for a ReMake project 
#   using CMake's CPack macros. It gets invoked by the generator-specific
#   macros defined in this module and should not be called directly from a 
#   CMakeLists.txt file. The macro creates a package build target from the
#   specified install component and initializes the CPack variables.
#   \required[value] generator The generator to be used for creating the
#     component package. See the CPack documentation for valid generators.
#   \optional[value] NAME:name The name of the package to be generated,
#     defaults to the ReMake project name.
#   \optional[value] COMPONENT:component The name of the install component
#     to generate the package from, defaults to default.
macro(remake_pack pack_generator)
  if(NOT TARGET ${REMAKE_PACK_ALL_TARGET})
    remake_target(${REMAKE_PACK_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_PACK_ALL_TARGET})

  remake_arguments(PREFIX pack_ VAR NAME VAR COMPONENT ${ARGN})
  remake_set(pack_name SELF DEFAULT ${REMAKE_PROJECT_NAME})

  remake_set(pack_prefix ${pack_component})
  remake_set(pack_component SELF DEFAULT default)
  remake_file(pack_config ${REMAKE_PACK_DIR}/${pack_component}.cpack)
  remake_file(pack_src_config
    ${REMAKE_PACK_SOURCE_DIR}/${pack_component}.cpack)
  remake_set(CPACK_OUTPUT_CONFIG_FILE ${pack_config})
  remake_set(CPACK_SOURCE_OUTPUT_CONFIG_FILE ${pack_src_config})

  remake_set(CPACK_GENERATOR ${pack_generator})
  remake_set(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
    ${REMAKE_PROJECT_NAME} ${pack_component} /)
  remake_set(CPACK_SET_DESTDIR TRUE)

  remake_set(CPACK_PACKAGE_NAME ${pack_name})
  remake_set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})
  remake_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${REMAKE_PROJECT_SUMMARY})
  remake_set(CPACK_PACKAGE_CONTACT ${REMAKE_PROJECT_CONTACT})

  include(CPack)

  remake_target_name(pack_target ${pack_prefix} ${REMAKE_PACK_TARGET})
  remake_target(${pack_target} COMMAND cpack --config ${pack_config}
    COMMENT "Building ${pack_name} package")
  add_dependencies(${REMAKE_PACK_ALL_TARGET} ${pack_target})

  remake_var_regex(pack_variables "^CPACK_")
  foreach(pack_var ${pack_variables})
    remake_set(${pack_var})
  endforeach(pack_var)
endmacro(remake_pack)

### \brief Generate a Debian package from the ReMake project.
#   This macro configures package generation using CPack's DEB generator
#   for Debian packages. It acquires all the information necessary from
#   the current project settings and the arguments passed. In addition to
#   creating a package build target through remake_pack(), the macro adds a 
#   simplified package install target.
#   \optional[value] ARCH:architecture The package architecture that is
#     inscribed into the package manifest, defaults to the local system
#     architecture as returned by 'dpkg --print-architecture'.
#   \optional[value] COMPONENT:component The name of the install component
#     to generate the Debian package from, defaults to the empty string.
#     Note that following Debian conventions, the component name is used as 
#     suffix to the package name.
#   \optional[list] dep An optional list of package dependencies
#     that are inscribed into the package manifest. The format of a 
#     dependency should comply to Debian conventions, meaning that the
#     dependency is of the form ${PACKAGE} [(>= ${VERSION})].
macro(remake_pack_deb)
  remake_arguments(PREFIX pack_ VAR ARCH VAR COMPONENT ARGN dependencies 
    ${ARGN})

  execute_process(COMMAND dpkg --print-architecture
    OUTPUT_VARIABLE pack_deb_arch OUTPUT_STRIP_TRAILING_WHITESPACE)
  remake_set(pack_arch SELF DEFAULT ${pack_deb_arch})
  remake_set(pack_prefix ${pack_component})
  remake_set(pack_suffix ${pack_component})

  if(pack_suffix)
    remake_file_name(pack_name ${REMAKE_PROJECT_FILENAME}-${pack_suffix})
    remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}-${pack_suffix}
      ${REMAKE_PROJECT_VERSION} ${pack_arch})
  else(pack_suffix)
    remake_file_name(pack_name ${REMAKE_PROJECT_FILENAME})
    remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}
      ${REMAKE_PROJECT_VERSION} ${pack_arch})
  endif(pack_suffix)

  string(REPLACE ";" ", " pack_replace "${pack_dependencies}")
  remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${pack_replace})
  remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${pack_arch})
  remake_set(CPACK_PACKAGE_FILE_NAME deb/${pack_file})

  remake_pack(DEB ${COMPONENT} NAME ${pack_name})

  remake_target_name(pack_target ${pack_prefix} ${REMAKE_PACK_TARGET})
  remake_target_name(pack_install_target ${pack_prefix}
    ${REMAKE_PACK_INSTALL_TARGET})
  remake_target(${pack_install_target}
    COMMAND sudo dpkg --install deb/${pack_file}.deb
    COMMENT "Installing ${pack_name} package")
  add_dependencies(${pack_install_target} ${pack_target})
endmacro(remake_pack_deb)
