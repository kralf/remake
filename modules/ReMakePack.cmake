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
include(ReMakeComponent)

### \brief ReMake packaging macros
#   The ReMake packaging macros have been designed to provide simple and
#   transparent package generation using CMake's CPack module.

remake_set(REMAKE_PACK_ALL_BINARY_TARGET packages)
remake_set(REMAKE_PACK_ALL_SOURCE_TARGET source_packages)
remake_set(REMAKE_PACK_BINARY_TARGET_SUFFIX package)
remake_set(REMAKE_PACK_INSTALL_ALL_TARGET packages_install)
remake_set(REMAKE_PACK_INSTALL_TARGET_SUFFIX package_install)
remake_set(REMAKE_PACK_UNINSTALL_ALL_TARGET packages_uninstall)
remake_set(REMAKE_PACK_UNINSTALL_TARGET_SUFFIX package_uninstall)

remake_set(REMAKE_PACK_DIR ReMakePackages)
remake_set(REMAKE_PACK_SOURCE_DIR ReMakeSourcePackages)

### \brief Generate binary packages from a ReMake project.
#   This macro generally configures binary package generation for a
#   ReMake project using CMake's CPack macros. It gets invoked by the
#   generator-specific macros defined in this module and should not be
#   called directly from a CMakeLists.txt file. The macro creates a
#   package build target from the specified install component and
#   initializes the CPack variables.
#   \required[value] generator The generator to be used for creating the
#     binary component package. See the CPack documentation for valid
#     generators.
#   \optional[value] NAME:name The name of the binary package to be
#     generated, defaults to the ${REMAKE_PROJECT_FILENAME}.
#   \optional[value] COMPONENT:component The name of the install
#     component to generate the binary package from, defaults to
#     ${REMAKE_DEFAULT_COMPONENT}.
macro(remake_pack_binary pack_generator)
  remake_arguments(PREFIX pack_ VAR NAME VAR COMPONENT ${ARGN})
  remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})

  remake_component_get(${pack_component} BUILD OUTPUT pack_build)
  if(pack_build)
    if(NOT TARGET ${REMAKE_PACK_ALL_BINARY_TARGET})
      remake_target(${REMAKE_PACK_ALL_BINARY_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_ALL_BINARY_TARGET})

    remake_set(pack_name SELF DEFAULT ${REMAKE_PROJECT_FILENAME})
    remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})

    if(pack_component STREQUAL REMAKE_DEFAULT_COMPONENT)
      remake_set(pack_prefix)
    else(pack_component STREQUAL REMAKE_DEFAULT_COMPONENT)
      remake_set(pack_prefix ${pack_component})
    endif(pack_component STREQUAL REMAKE_DEFAULT_COMPONENT)
    remake_file(pack_config
      ${REMAKE_PACK_DIR}/${pack_generator}/${pack_component}.cpack)
    remake_set(CPACK_OUTPUT_CONFIG_FILE ${pack_config})
    remake_file(pack_src_config
      ${REMAKE_PACK_SOURCE_DIR}/${pack_generator}/${pack_component}.cpack)
    remake_set(CPACK_SOURCE_OUTPUT_CONFIG_FILE ${pack_src_config})

    remake_set(CPACK_GENERATOR ${pack_generator})
    remake_set(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
      ${REMAKE_PROJECT_NAME} ${pack_component} /)
    remake_set(CPACK_SET_DESTDIR TRUE)

    remake_set(CPACK_PACKAGE_NAME ${pack_name})
    remake_set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})
    string(REGEX REPLACE "[.]$" "" pack_summary ${REMAKE_PROJECT_SUMMARY})
    if(pack_description)
      remake_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
        "${pack_summary} (${pack_description})")
    else(pack_description)
      remake_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${pack_summary})
    endif(pack_description)
    remake_set(CPACK_PACKAGE_CONTACT
      "${REMAKE_PROJECT_ADMIN} <${REMAKE_PROJECT_CONTACT}>")

    if(${pack_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})
      message(STATUS "Binary package: ${pack_name} (${pack_generator})")
    else(${pack_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})
      message(STATUS "Binary package: ${pack_name}, "
        "using component ${pack_component} (${pack_generator})")
    endif(${pack_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})

    remake_unset(CPack_CMake_INCLUDED)
    include(CPack)

    remake_target_name(pack_target ${pack_prefix}
      ${REMAKE_PACK_BINARY_TARGET_SUFFIX})
    if(NOT TARGET ${pack_target})
      remake_target(${pack_target})
    else(NOT TARGET ${pack_target})
      remake_debug(pack_target)
    endif(NOT TARGET ${pack_target})
    remake_target_add_command(${pack_target}
      COMMAND cpack --config ${pack_config}
      COMMENT "Building ${pack_name} binary package")
    remake_component_add_dependencies(
      COMPONENT ${pack_component}
      PROVIDES ${pack_target})
    add_dependencies(${REMAKE_PACK_ALL_BINARY_TARGET} ${pack_target})

    remake_var_regex(pack_variables "^CPACK_")
    foreach(pack_var ${pack_variables})
      remake_unset(${pack_var})
    endforeach(pack_var)
  endif(pack_build)
endmacro(remake_pack_binary)

### \brief Generate source packages from a ReMake project.
#   This macro generally configures source package generation for a
#   ReMake project using CMake's CPack macros. It gets invoked by the
#   generator-specific macros defined in this module and should not be
#   called directly from a CMakeLists.txt file. The macro creates a
#   project-wide package build target and initializes the CPack variables.
#   Assuming an out-of-source build, ${CMAKE_BINARY_DIR} is automatically
#   excluded from the package along with any hidden files or directories.
#   \required[value] generator The generator to be used for creating the
#     source package. See the CPack documentation for valid generators.
#   \optional[value] NAME:name The name of the source package to be
#     generated, defaults to ${REMAKE_PROJECT_FILENAME}.
macro(remake_pack_source pack_generator)
  remake_arguments(PREFIX pack_ VAR NAME ${ARGN})

  if(NOT TARGET ${REMAKE_PACK_ALL_SOURCE_TARGET})
    remake_target(${REMAKE_PACK_ALL_SOURCE_TARGET})
  endif(NOT TARGET ${REMAKE_PACK_ALL_SOURCE_TARGET})

  remake_set(pack_name SELF DEFAULT ${REMAKE_PROJECT_FILENAME})

  remake_file(pack_config
    ${REMAKE_PACK_DIR}/${pack_generator}/all.cpack)
  remake_set(CPACK_OUTPUT_CONFIG_FILE ${pack_config})
  remake_file(pack_src_config
    ${REMAKE_PACK_SOURCE_DIR}/${pack_generator}/all.cpack)
  remake_set(CPACK_SOURCE_OUTPUT_CONFIG_FILE ${pack_src_config})
  remake_set(CPACK_SOURCE_GENERATOR ${pack_generator})
  remake_set(CPACK_PACKAGE_NAME ${pack_name})
  remake_set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})

  file(RELATIVE_PATH pack_binary_dir ${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
  remake_set(CPACK_SOURCE_IGNORE_FILES
    "/\\\\\\\\\\\\\\\\..*/;/${pack_binary_dir}/")

  message(STATUS "Source package: ${pack_name} (${pack_generator})")

  remake_unset(CPack_CMake_INCLUDED)
  include(CPack)

  remake_target_add_command(${REMAKE_PACK_ALL_SOURCE_TARGET}
    COMMAND cpack --config ${pack_src_config}
    COMMENT "Building ${pack_name} source package")

  remake_var_regex(pack_variables "^CPACK_")
  foreach(pack_var ${pack_variables})
    remake_unset(${pack_var})
  endforeach(pack_var)
endmacro(remake_pack_source)

### \brief Generate a binary Debian package from the ReMake project.
#   This macro configures package generation using CPack's DEB generator
#   for binary Debian packages. It acquires all the information necessary
#   from the current project settings and the arguments passed. In addition
#   to creating a package build target through remake_pack(), the macro
#   adds simplified package install and uninstall targets. Project-internal
#   dependencies between these targets are automatically resolved. Also,
#   the macro provides automated resolution of package dependencies with
#   hardcoded version information, i.e. packages including the version
#   string in the package name.
#   \optional[value] ARCH:architecture The package architecture that is
#     inscribed into the package manifest, defaults to the local system
#     architecture as returned by 'dpkg --print-architecture'.
#   \optional[value] COMPONENT:component The name of the install component to
#     generate the Debian package from, defaults to ${REMAKE_DEFAULT_COMPONENT}.
#     Note that following Debian conventions, the component name is used as
#     suffix to the package name. However, a component name matching
#     ${REMAKE_DEFAULT_COMPONENT} results in an empty suffix.
#   \optional[value] DESCRIPTION:string An optional description of the
#     install component that is appended to the project summary when
#     generating the package description.
#   \optional[list] dep An optional list of package dependencies
#     that are inscribed into the package manifest. The format of a
#     dependency should comply to Debian conventions, meaning that the
#     dependency is of the form ${PACKAGE} [(>= ${VERSION})].
macro(remake_pack_deb)
  remake_arguments(PREFIX pack_ VAR ARCH VAR COMPONENT VAR DESCRIPTION
    ARGN dependencies ${ARGN})
  remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})

  remake_component_get(${pack_component} BUILD OUTPUT pack_build)
  if(pack_build)
    if(NOT TARGET ${REMAKE_PACK_INSTALL_ALL_TARGET})
      remake_target(${REMAKE_PACK_INSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_INSTALL_ALL_TARGET})
    if(NOT TARGET ${REMAKE_PACK_UNINSTALL_ALL_TARGET})
      remake_target(${REMAKE_PACK_UNINSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_UNINSTALL_ALL_TARGET})

    execute_process(COMMAND dpkg --print-architecture
      OUTPUT_VARIABLE pack_deb_arch OUTPUT_STRIP_TRAILING_WHITESPACE)
    remake_set(pack_arch SELF DEFAULT ${pack_deb_arch})
    if(pack_component MATCHES "^${REMAKE_DEFAULT_COMPONENT}[-]?.*$")
      string(REGEX REPLACE "^(${REMAKE_DEFAULT_COMPONENT})[-]?(.*)$" "\\2"
        pack_prefix ${pack_component})
    else(pack_component MATCHES "^${REMAKE_DEFAULT_COMPONENT}[-]?.*$")
      remake_set(pack_prefix ${pack_component})
    endif(pack_component MATCHES "^${REMAKE_DEFAULT_COMPONENT}[-]?.*$")
    remake_set(pack_suffix ${pack_prefix})

    if(pack_suffix)
      remake_file_name(pack_name ${REMAKE_PROJECT_FILENAME}-${pack_suffix})
      remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}-${pack_suffix}
        ${REMAKE_PROJECT_FILENAME_VERSION} ${pack_arch})
    else(pack_suffix)
      remake_file_name(pack_name ${REMAKE_PROJECT_FILENAME})
      remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}
        ${REMAKE_PROJECT_FILENAME_VERSION} ${pack_arch})
    endif(pack_suffix)

    remake_set(pack_component_deps)
    foreach(pack_dependency ${pack_dependencies})
      if(pack_dependency MATCHES "^${REMAKE_PROJECT_FILENAME}[-]?.*$")
        string(REGEX REPLACE "^(${REMAKE_PROJECT_FILENAME}[-]?[^ ]*).*$" "\\1"
          pack_name_dep ${pack_dependency})
        string(REGEX REPLACE "^(${REMAKE_PROJECT_FILENAME})[-]?([^ ]*).*$" "\\2"
          pack_component_dep ${pack_dependency})
        string(REGEX REPLACE "^([^\(]+)[(]?([^\)]*)[)]?$" "\\2"
          pack_version_dep ${pack_dependency})
        remake_set(pack_component_dep SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})
        remake_set(pack_version_dep SELF DEFAULT ">= ${REMAKE_PROJECT_VERSION}")
        remake_list_push(pack_component_deps ${pack_component_dep})
        remake_list_replace(pack_dependencies ${pack_dependency}
          REPLACE "${pack_name_dep} (${pack_version_dep})")
      else(pack_dependency MATCHES "^${REMAKE_PROJECT_FILENAME}[-]?.*$")
        execute_process(COMMAND dpkg --list "${pack_dependency}[0-9]*"
          OUTPUT_VARIABLE pack_deb_packages OUTPUT_STRIP_TRAILING_WHITESPACE
          RESULT_VARIABLE pack_deb_result ERROR_QUIET)
        if(${pack_deb_result} EQUAL 0)
          string(REGEX REPLACE "\n" ";" pack_deb_packages ${pack_deb_packages})
          foreach(pack_deb_pkg ${pack_deb_packages})
            if(${pack_deb_pkg} MATCHES "^ii[ ]+${pack_dependency}[-0-9.]+ ")
              string(REGEX REPLACE "^ii[ ]+(${pack_dependency}[-0-9.]+) .*$"
                "\\1" pack_deb_pkg_name ${pack_deb_pkg})
              remake_list_replace(pack_dependencies ${pack_dependency}
                REPLACE ${pack_deb_pkg_name})
            endif(${pack_deb_pkg} MATCHES "^ii[ ]+${pack_dependency}[-0-9.]+ ")
          endforeach(pack_deb_pkg)
        endif(${pack_deb_result} EQUAL 0)
      endif(pack_dependency MATCHES "^${REMAKE_PROJECT_FILENAME}[-]?.*$")
    endforeach(pack_dependency)

    string(REPLACE ";" ", " pack_replace "${pack_dependencies}")
    remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${pack_replace})
    remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${pack_arch})
    remake_set(CPACK_PACKAGE_FILE_NAME ${pack_file})

    remake_pack_binary(DEB COMPONENT ${pack_component} NAME ${pack_name})

    remake_target_name(pack_target ${pack_prefix}
      ${REMAKE_PACK_BINARY_TARGET_SUFFIX})
    remake_target_name(pack_install_target ${pack_prefix}
      ${REMAKE_PACK_INSTALL_TARGET_SUFFIX})
    remake_target(${pack_install_target}
      COMMAND sudo dpkg --install ${pack_file}.deb
      COMMENT "Installing ${pack_name} package")
    add_dependencies(${pack_install_target} ${pack_target})
    add_dependencies(${REMAKE_PACK_INSTALL_ALL_TARGET} ${pack_install_target})

    remake_target_name(pack_uninstall_target ${pack_prefix}
      ${REMAKE_PACK_UNINSTALL_TARGET_SUFFIX})
    remake_target(${pack_uninstall_target}
      COMMAND sudo dpkg --remove ${pack_name}
      COMMENT "Uninstalling ${pack_name} package")
    add_dependencies(${REMAKE_PACK_UNINSTALL_ALL_TARGET}
      ${pack_uninstall_target})

    foreach(pack_component_dep ${pack_component_deps})
      if(pack_component_dep STREQUAL REMAKE_DEFAULT_COMPONENT)
        remake_set(pack_prefix_dep)
      else(pack_component_dep STREQUAL REMAKE_DEFAULT_COMPONENT)
        remake_set(pack_prefix_dep ${pack_component_dep})
      endif(pack_component_dep STREQUAL REMAKE_DEFAULT_COMPONENT)

      remake_target_name(pack_install_target_dep ${pack_prefix_dep}
        ${REMAKE_PACK_INSTALL_TARGET_SUFFIX})
      remake_target_name(pack_uninstall_target_dep ${pack_prefix_dep}
        ${REMAKE_PACK_UNINSTALL_TARGET_SUFFIX})

      add_dependencies(${pack_install_target} ${pack_install_target_dep})
      add_dependencies(${pack_uninstall_target} ${pack_uninstall_target_dep})
    endforeach(pack_component_dep)
  endif(pack_build)
endmacro(remake_pack_deb)

### \brief Generate a binary archive from the ReMake project.
#   This macro configures binary package generation using one of CPack's
#   archive generators. It acquires all the information necessary from the
#   current project settings and the arguments passed.
#   \optional[value] GENERATOR:generator The generator to be used for creating
#     the binary archive, defaults to TGZ. See the CPack documentation for valid
#     archive generators.
#   \optional[value] ARCH:architecture The architecture that is appended to
#     the archive name, defaults to the local system architecture as returned
#     by 'uname -m'.
#   \optional[value] COMPONENT:component The name of the install component to
#     generate the binary archive from, defaults to ${REMAKE_DEFAULT_COMPONENT}.
#     Note that the component name is used as suffix to the package name.
#     However, a component name matching ${REMAKE_DEFAULT_COMPONENT} results
#     in an empty suffix.
macro(remake_pack_archive)
  remake_arguments(PREFIX pack_ VAR GENERATOR VAR ARCH VAR COMPONENT ${ARGN})
  remake_set(pack_generator SELF DEFAULT TGZ)
  remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})

  remake_component_get(${pack_component} BUILD OUTPUT pack_build)
  if(pack_build)
    execute_process(COMMAND uname -m
      OUTPUT_VARIABLE pack_uname_arch OUTPUT_STRIP_TRAILING_WHITESPACE)
    remake_set(pack_arch SELF DEFAULT ${pack_uname_arch})
    if(pack_component MATCHES "^${REMAKE_DEFAULT_COMPONENT}[-]?.*$")
      string(REGEX REPLACE "^(${REMAKE_DEFAULT_COMPONENT})[-]?(.*)$" "\\2"
        pack_prefix ${pack_component})
    else(pack_component MATCHES "^${REMAKE_DEFAULT_COMPONENT}[-]?.*$")
      remake_set(pack_prefix ${pack_component})
    endif(pack_component MATCHES "^${REMAKE_DEFAULT_COMPONENT}[-]?.*$")
    remake_set(pack_suffix ${pack_prefix})

    if(pack_suffix)
      remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}-${pack_suffix}
        ${REMAKE_PROJECT_FILENAME_VERSION} ${pack_arch})
    else(pack_suffix)
      remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}
        ${REMAKE_PROJECT_FILENAME_VERSION} ${pack_arch})
    endif(pack_suffix)

    remake_set(CPACK_PACKAGE_FILE_NAME ${pack_file})
    remake_pack_binary(${pack_generator} COMPONENT ${pack_component})
  endif(pack_build)
endmacro(remake_pack_archive)

### \brief Generate a source archive from the ReMake project.
#   This macro configures source package generation using one of CPack's
#   archive generators. It acquires all the information necessary from the
#   current project settings and the arguments passed.
#   \optional[value] GENERATOR:generator The generator to be used for creating
#     the source archive, defaults to TGZ. See the CPack documentation for valid
#     archive generators.
macro(remake_pack_source_archive)
  remake_arguments(PREFIX pack_ VAR GENERATOR ${ARGN})
  remake_set(pack_generator SELF DEFAULT TGZ)

  remake_file_name(pack_file
    ${REMAKE_PROJECT_FILENAME}-${REMAKE_PROJECT_FILENAME_VERSION})

  remake_set(CPACK_SOURCE_PACKAGE_FILE_NAME ${pack_file})
  remake_pack_source(${pack_generator})
endmacro(remake_pack_source_archive)

remake_file_rmdir(${REMAKE_PACK_DIR})
remake_file_rmdir(${REMAKE_PACK_SOURCE_DIR})
remake_file_mkdir(${REMAKE_PACK_DIR})
remake_file_mkdir(${REMAKE_PACK_SOURCE_DIR})
