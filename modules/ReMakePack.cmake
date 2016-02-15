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

### \brief ReMake packaging macros
#   The ReMake packaging macros have been designed to provide simple and
#   transparent package generation using CMake's CPack module.

include(ReMakePrivate)

if(NOT DEFINED REMAKE_PACK_CMAKE)
  remake_set(REMAKE_PACK_CMAKE ON)

  remake_set(REMAKE_PACK_ALL_BINARY_TARGET packages)
  remake_set(REMAKE_PACK_ALL_SOURCE_TARGET source_packages)
  remake_set(REMAKE_PACK_BINARY_TARGET_SUFFIX package)
  remake_set(REMAKE_PACK_INSTALL_ALL_TARGET packages_install)
  remake_set(REMAKE_PACK_INSTALL_TARGET_SUFFIX package_install)
  remake_set(REMAKE_PACK_UNINSTALL_ALL_TARGET packages_uninstall)
  remake_set(REMAKE_PACK_UNINSTALL_TARGET_SUFFIX package_uninstall)

  remake_set(REMAKE_PACK_DIR ReMakePackages)
  remake_set(REMAKE_PACK_SOURCE_DIR ReMakeSourcePackages)

  remake_file_rmdir(${REMAKE_PACK_DIR})
  remake_file_rmdir(${REMAKE_PACK_SOURCE_DIR})
  remake_file_mkdir(${REMAKE_PACK_DIR})
  remake_file_mkdir(${REMAKE_PACK_SOURCE_DIR})
else(NOT DEFINED REMAKE_PACK_CMAKE)
  return()
endif(NOT DEFINED REMAKE_PACK_CMAKE)

include(ReMakeComponent)
include(ReMakeDebian)

### \brief Generate binary packages from a ReMake project component.
#   This macro generally configures binary package generation for a
#   ReMake project component using CMake's CPack macros. It gets invoked
#   by the generator-specific macros defined in this module and should
#   not be called directly from a CMakeLists.txt file. The macro creates
#   a  package build target from the specified install component and
#   initializes the CPack variables.
#   \required[value] generator The generator to be used for creating the
#     binary component package. See the CPack documentation for valid
#     generators.
#   \optional[value] NAME:name The name of the binary package to be
#     generated, defaults to the component-specific filename defined
#     for the provided component.
#   \optional[value] VERSION:version The version of the binary package to
#     be generated, defaults to the ${REMAKE_PROJECT_VERSION}.
#   \optional[value] COMPONENT:component The name of the install
#     component to generate the binary package from, defaults to
#     ${REMAKE_DEFAULT_COMPONENT}.
#   \optional[list] EXTRA_COMPONENTS:component An optional list of
#     additional install components to generate the binary package
#     from.
#   \optional[value] DESCRIPTION:string An optional description of the
#     install component that is appended to the project summary when
#     generating the package description.
macro(remake_pack_binary pack_generator)
  remake_arguments(PREFIX pack_ VAR NAME VAR VERSION VAR COMPONENT
    LIST EXTRA_COMPONENTS VAR DESCRIPTION ${ARGN})
  remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})

  remake_component_get(${pack_component} BUILD OUTPUT pack_build)
  if(pack_build)
    if(NOT TARGET ${REMAKE_PACK_ALL_BINARY_TARGET})
      remake_target(${REMAKE_PACK_ALL_BINARY_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_ALL_BINARY_TARGET})

    remake_component_get(${pack_component} FILENAME
      OUTPUT ${pack_default_name})
    remake_set(pack_name SELF DEFAULT ${pack_default_name})
    remake_set(pack_version SELF DEFAULT ${REMAKE_PROJECT_VERSION})

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
    foreach(pack_extra_component ${pack_extra_components})
      remake_list_push(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
        ${REMAKE_PROJECT_NAME} ${pack_extra_component} /)
    endforeach(pack_extra_component)
    remake_set(CPACK_SET_DESTDIR TRUE)

    remake_set(CPACK_PACKAGE_NAME ${pack_name})
    remake_set(CPACK_PACKAGE_VERSION ${pack_version})
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
      if(pack_extra_components)
        string(REGEX REPLACE ";" ", " pack_components
          "${pack_extra_components}")
        message(STATUS "Binary package: ${pack_name}, "
          "using component(s) ${pack_components} (${pack_generator})")
      else(pack_extra_components)
        message(STATUS "Binary package: ${pack_name} (${pack_generator})")
      endif(pack_extra_components)
    else(${pack_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})
      if(pack_extra_components)
        string(REGEX REPLACE ";" ", " pack_components
          "${pack_component};${pack_extra_components}")
        message(STATUS "Binary package: ${pack_name}, "
          "using components ${pack_components} (${pack_generator})")
      else(pack_extra_components)
        message(STATUS "Binary package: ${pack_name}, "
          "using component ${pack_component} (${pack_generator})")
      endif(pack_extra_components)
    endif(${pack_component} STREQUAL ${REMAKE_DEFAULT_COMPONENT})

    remake_unset(CPack_CMake_INCLUDED)
    include(CPack)

    remake_target_name(pack_target ${pack_prefix}
      ${REMAKE_PACK_BINARY_TARGET_SUFFIX})
    if(NOT TARGET ${pack_target})
      remake_target(${pack_target})
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
#     generated, defaults to ${REMAKE_PROJECT_NAME}.
#   \optional[value] VERSION:version The version of the source package to
#     be generated, defaults to the ${REMAKE_PROJECT_VERSION}.
#   \optional[list] EXCLUDE:pattern An optional list of patterns matching
#     additional files or directories in the source tree which shall not be
#     packaged. Note that ${CMAKE_BINARY_DIR} and any hidden files or
#     directories are automatically excluded and thus need not be considered
#     in this list. See the CPack documentation for regular expression
#     patterns and their proper escaping.
macro(remake_pack_source pack_generator)
  remake_arguments(PREFIX pack_ VAR NAME VAR VERSION LIST EXCLUDE ${ARGN})

  if(NOT TARGET ${REMAKE_PACK_ALL_SOURCE_TARGET})
    remake_target(${REMAKE_PACK_ALL_SOURCE_TARGET})
  endif(NOT TARGET ${REMAKE_PACK_ALL_SOURCE_TARGET})

  remake_set(pack_name SELF DEFAULT ${REMAKE_PROJECT_NAME})
  remake_set(pack_version SELF DEFAULT ${REMAKE_PROJECT_VERSION})
  remake_file(pack_config
    ${REMAKE_PACK_DIR}/${pack_generator}/all.cpack)
  remake_file(pack_src_config
    ${REMAKE_PACK_SOURCE_DIR}/${pack_generator}/all.cpack)

  if(NOT EXISTS ${pack_src_config})
    remake_set(CPACK_OUTPUT_CONFIG_FILE ${pack_config})
    remake_set(CPACK_SOURCE_OUTPUT_CONFIG_FILE ${pack_src_config})
    remake_set(CPACK_SOURCE_GENERATOR ${pack_generator})
    remake_set(CPACK_PACKAGE_NAME ${pack_name})
    remake_set(CPACK_PACKAGE_VERSION ${pack_version})

    file(RELATIVE_PATH pack_binary_dir ${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
    remake_set(CPACK_SOURCE_IGNORE_FILES "/[.].*/;/${pack_binary_dir}/")
    if(pack_exclude)
      remake_list_push(CPACK_SOURCE_IGNORE_FILES ${pack_exclude})
    endif(pack_exclude)

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
  endif(NOT EXISTS ${pack_src_config})
endmacro(remake_pack_source)

### \brief Generate a binary Debian package from a ReMake project component.
#   This macro configures package generation using CPack's DEB generator
#   for binary Debian packages on Debian-related build systems. It is currently
#   deprecated but kept for backward compatibility and simply invokes
#   remake_debian_pack(), forwarding all arguments.
#   \required[list] arg The arguments to be passed on to remake_debian_pack().
#     See ReMakePack for details.
macro(remake_pack_deb)
  message(DEPRECATION
    "This macro is deprecated in favor of remake_debian_pack().")
  remake_debian_pack(${ARGN})
endmacro(remake_pack_deb)

### \brief Generate a binary archive from a ReMake project component.
#   This macro configures binary package generation using one of CPack's
#   archive generators. It acquires all the information necessary from the
#   current project and component settings and the arguments passed.
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

    remake_component_get(${pack_component} FILENAME OUTPUT pack_name)
    remake_file_name(pack_file ${pack_name} ${REMAKE_PROJECT_FILENAME_VERSION}
      ${pack_arch})

    remake_set(CPACK_PACKAGE_FILE_NAME ${pack_file})
    remake_pack_binary(${pack_generator} COMPONENT ${pack_component})
  endif(pack_build)
endmacro(remake_pack_archive)

### \brief Generate a source archive from the ReMake project.
#   This macro configures source package generation using one of CPack's
#   archive generators. It acquires all the information necessary from the
#   current project settings and the arguments passed.
#   \optional[value] GENERATOR:generator The generator to be used for creating
#     the source archive, defaults to TGZ. See the CPack documentation for
#     valid archive generators.
#   \optional[list] EXCLUDE:pattern An optional list of patterns passed to
#     remake_pack_source(), matching additional files or directories in the
#     source tree which shall not be packaged.
macro(remake_pack_source_archive)
  remake_arguments(PREFIX pack_ VAR GENERATOR LIST EXCLUDE ${ARGN})
  remake_set(pack_generator SELF DEFAULT TGZ)

  remake_file_name(pack_file
    ${REMAKE_PROJECT_NAME}-${REMAKE_PROJECT_FILENAME_VERSION})

  remake_set(CPACK_SOURCE_PACKAGE_FILE_NAME ${pack_file})
  remake_pack_source(${pack_generator} ${EXCLUDE})
endmacro(remake_pack_source_archive)
