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
endif(NOT DEFINED REMAKE_PACK_CMAKE)

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
macro(remake_pack_binary pack_generator)
  remake_arguments(PREFIX pack_ VAR NAME VAR VERSION VAR COMPONENT ${ARGN})
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

  remake_set(pack_name SELF DEFAULT ${REMAKE_PROJECT_FILENAME})
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
#   for binary Debian packages. It acquires all the information necessary
#   from the current project and component settings and the arguments passed.
#   In addition to creating a component-specific package build target through
#   remake_pack(), the macro adds simplified package install and uninstall
#   targets. Project-internal dependencies between these targets are
#   automatically resolved. Also, the macro provides automated resolution of
#   dependencies on packages installed on the build system.
#   \optional[value] ARCH:architecture The package architecture that is
#     inscribed into the package manifest, defaults to the local system
#     architecture as returned by 'dpkg --print-architecture'. When
#     cross-compiling, the default may be overridden by the toolchain
#     variable ${REMAKE_PACK_DEBIAN_ARCHITECTURE}.
#   \optional[value] COMPONENT:component The name of the install component to
#     generate the Debian package from, defaults to ${REMAKE_DEFAULT_COMPONENT}.
#     Note that following Debian conventions, the component name is used as
#     suffix to the package name. However, a component name matching
#     ${REMAKE_DEFAULT_COMPONENT} results in an empty suffix.
#   \optional[value] DESCRIPTION:string An optional description of the
#     install component that is appended to the project summary when
#     generating the package description.
#   \optional[list] DEPENDS:pkg An optional list of mandatory package
#     dependencies that are matched and inscribed into the package manifest.
#     The format of a dependency should comply to Debian conventions, meaning
#     that an entry is of the form ${PACKAGE} [(>= ${VERSION})]. The macro
#     requires each dependency to match against another binary package
#     defined in a previous call to remake_pack_deb() or an installed
#     package reported by dpkg on the build system. In the first case,
#     the version of the dependency should be omitted as it will be equated
#     with ${REMAKE_PROJECT_VERSION}. In the second case, the dependency
#     may be passed as regular expression. Failure to match such expression
#     will result in a fatal error.
#   \optional[list] RECOMMENDS:pkg An optional list of recommended packages
#     that are directly inscribed into the package manifest. The format of a
#     recommendation should comply to Debian conventions, meaning that
#     an entry is of the form ${PACKAGE} [(>= ${VERSION})]. As opposed to
#     mandatory dependencies, recommended packages are not matched against
#     the names of packages installed on the build system or defined in a
#     previous call to remake_pack_deb(). Therefore, a recommendation
#     should generally be precise. As this is often difficult when
#     attempting to build binary packages for several distributions, use
#     of the DEPENDS argument is strongly encouraged.
#   \optional[list] EXTRA:glob An optional list of glob expressions matching
#     extra control information files such as preinst, postinst, prerm, and
#     postrm to be included in the Debian package's control section.
macro(remake_pack_deb)
  remake_arguments(PREFIX pack_ VAR ARCH VAR COMPONENT VAR DESCRIPTION
    LIST DEPENDS LIST RECOMMENDS LIST EXTRA ARGN depends ${ARGN})
  remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})

  remake_component_get(${pack_component} BUILD OUTPUT pack_build)
  if(pack_build)
    if(NOT TARGET ${REMAKE_PACK_INSTALL_ALL_TARGET})
      remake_target(${REMAKE_PACK_INSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_INSTALL_ALL_TARGET})
    if(NOT TARGET ${REMAKE_PACK_UNINSTALL_ALL_TARGET})
      remake_target(${REMAKE_PACK_UNINSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_UNINSTALL_ALL_TARGET})

    if(CMAKE_CROSSCOMPILING AND REMAKE_PACK_DEBIAN_ARCHITECTURE)
      remake_set(pack_arch SELF DEFAULT ${REMAKE_PACK_DEBIAN_ARCHITECTURE})
    else(CMAKE_CROSSCOMPILING AND REMAKE_PACK_DEBIAN_ARCHITECTURE)
      execute_process(COMMAND dpkg --print-architecture
        OUTPUT_VARIABLE pack_deb_arch OUTPUT_STRIP_TRAILING_WHITESPACE)
      remake_set(pack_arch SELF DEFAULT ${pack_deb_arch})
    endif(CMAKE_CROSSCOMPILING AND REMAKE_PACK_DEBIAN_ARCHITECTURE)

    remake_component_get(${pack_component} FILENAME OUTPUT pack_name)
    remake_file_name(pack_file ${pack_name} ${REMAKE_PROJECT_FILENAME_VERSION}
      ${pack_arch})

    remake_unset(pack_binary_deps)
    remake_unset(pack_component_deps)
    remake_unset(pack_deb_packages)
    foreach(pack_dependency ${pack_depends})
      remake_pack_resolve_deb(${pack_dependency}
        OUTPUT_NAME pack_name_dep
        OUTPUT_VERSION pack_version_dep
        OUTPUT_COMPONENT pack_component_dep)

      if(pack_component_dep)
        remake_list_push(pack_component_deps ${pack_component_dep})
        remake_component_get(${pack_component_dep} FILENAME
          OUTPUT pack_name_dep)
        remake_set(pack_version_dep SELF DEFAULT "= ${REMAKE_PROJECT_VERSION}")
        remake_set(pack_dependency "${pack_name_dep} (${pack_version_dep})")
      else(pack_component_dep)
        remake_unset(pack_deb_found)
        if(NOT pack_deb_packages)
          execute_process(COMMAND dpkg-query -W
            OUTPUT_VARIABLE pack_deb_packages OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE pack_deb_result ERROR_QUIET)
          string(REGEX REPLACE "\n" ";" pack_deb_packages ${pack_deb_packages})
        endif(NOT pack_deb_packages)

        if(${pack_deb_result} EQUAL 0)
          foreach(pack_deb_pkg ${pack_deb_packages})
            if("${pack_deb_pkg}" MATCHES "^${pack_name_dep}[\t].*$")
              if(NOT pack_deb_found)
                string(REGEX REPLACE "^(${pack_name_dep})[\t].*$"
                  "\\1" pack_deb_pkg_name ${pack_deb_pkg})
                string(REGEX REPLACE "^${pack_name_dep}[\t](.*)$"
                  "\\1" pack_deb_pkg_version ${pack_deb_pkg})
                if(pack_version_dep)
                  string(REPLACE " " ";" pack_version_args ${pack_version_dep})
                  execute_process(COMMAND dpkg --compare-versions
                    ${pack_deb_pkg_version} ${pack_version_args}
                    RESULT_VARIABLE pack_deb_result ERROR_QUIET)
                  if(NOT pack_deb_result)
                    remake_set(pack_dependency
                      "${pack_deb_pkg_name} (${pack_version_dep})")
                    remake_set(pack_deb_found ON)
                  endif(NOT pack_deb_result)
                else(pack_version_dep)
                  remake_set(pack_dependency ${pack_deb_pkg_name})
                  remake_set(pack_deb_found ON)
                endif(pack_version_dep)
              else(NOT pack_deb_found)
                remake_set(pack_deb_message
                  "Multiple packages on build system match dependency")
                message(FATAL_ERROR "${pack_deb_message} ${pack_dependency}")
              endif(NOT pack_deb_found)
            endif("${pack_deb_pkg}" MATCHES "^${pack_name_dep}[\t].*$")
          endforeach(pack_deb_pkg)
        endif(${pack_deb_result} EQUAL 0)
        if(NOT pack_deb_found)
          remake_set(pack_deb_message
            "No package on build system matches dependency")
          message(FATAL_ERROR "${pack_deb_message} ${pack_dependency}")
        endif(NOT pack_deb_found)
      endif(pack_component_dep)
      remake_list_push(pack_binary_deps ${pack_dependency})
    endforeach(pack_dependency)

    string(REPLACE ";" ", " pack_binary_deps "${pack_binary_deps}")
    string(REPLACE ";" ", " pack_recommends "${pack_recommends}")
    remake_file_glob(pack_extra ${pack_extra})
    remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${pack_binary_deps})
    remake_set(CPACK_DEBIAN_PACKAGE_RECOMMENDS ${pack_recommends})
    remake_set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA ${pack_extra})
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
    remake_target_get_dependencies(pack_uninstall_target_deps
      ${pack_uninstall_target})
    if(pack_uninstall_target_deps)
      add_dependencies(${pack_uninstall_target} ${pack_uninstall_target_deps})
    endif(pack_uninstall_target_deps)

    foreach(pack_component_dep ${pack_component_deps})
      if(pack_component_dep STREQUAL REMAKE_DEFAULT_COMPONENT)
        remake_unset(pack_prefix_dep)
      else(pack_component_dep STREQUAL REMAKE_DEFAULT_COMPONENT)
        remake_set(pack_prefix_dep ${pack_component_dep})
      endif(pack_component_dep STREQUAL REMAKE_DEFAULT_COMPONENT)

      remake_target_name(pack_install_target_dep ${pack_prefix_dep}
        ${REMAKE_PACK_INSTALL_TARGET_SUFFIX})
      remake_target_name(pack_uninstall_target_dep ${pack_prefix_dep}
        ${REMAKE_PACK_UNINSTALL_TARGET_SUFFIX})

      add_dependencies(${pack_install_target} ${pack_install_target_dep})
      if(TARGET ${pack_uninstall_target_dep})
        add_dependencies(${pack_uninstall_target_dep} ${pack_uninstall_target})
      else(TARGET ${pack_uninstall_target_dep})
        remake_target_add_dependencies(${pack_uninstall_target_dep}
          ${pack_uninstall_target})
      endif(TARGET ${pack_uninstall_target_dep})
    endforeach(pack_component_dep)
  endif(pack_build)
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
    ${REMAKE_PROJECT_FILENAME}-${REMAKE_PROJECT_FILENAME_VERSION})

  remake_set(CPACK_SOURCE_PACKAGE_FILE_NAME ${pack_file})
  remake_pack_source(${pack_generator} ${EXCLUDE})
endmacro(remake_pack_source_archive)

### \brief Resolve project-internal package dependencies.
#   This macro is a helper macro to resolve project-internal dependencies
#   between Debian packages. It takes a Debian-compliant fully qualified
#   package name and matches it against the component specifications to
#   deliver the corresponding component name.
#   \required[value] name The fully qualified Debian package name,
#     consisting in the actual package name and an optional version
#     specifier, for which to resolve the project component. See the
#     Debian policies for naming conventions.
#   \optional[value] OUTPUT_NAME:variable The name of an optional output
#     variable that will be assigned the actual name of the package.
#   \optional[value] OUTPUT_VERSION:variable The name of an optional output
#     variable that will be assigned the version of the package.
#   \optional[value] OUTPUT_COMPONENT:variable The name of an optional output
#     variable that will be assigned the name of the resolved component. Note
#     that if none of the components matches the provided package name, the
#     output variable will be undefined.
macro(remake_pack_resolve_deb pack_full_name)
  remake_arguments(PREFIX pack_deb_ VAR OUTPUT_NAME VAR OUTPUT_VERSION
    VAR OUTPUT_COMPONENT ${ARGN})

  if(${pack_full_name} MATCHES "^[^ ]+[ ]+[(][^)]*[)]$")
    string(REGEX REPLACE "^([^ ]+)[ ]+[(]([^)]*)[)]$" "\\1"
      pack_deb_name ${pack_full_name})
    string(REGEX REPLACE "^([^ ]+)[ ]+[(]([^)]*)[)]$" "\\2"
      pack_deb_version ${pack_full_name})
  else(${pack_full_name} MATCHES "^[^ ]+[ ]+[(][^)]*[)]$")
    remake_set(pack_deb_name ${pack_full_name})
    remake_unset(pack_deb_version)
  endif(${pack_full_name} MATCHES "^[^ ]+[ ]+[(][^)]*[)]$")

  if(pack_deb_output_name)
    remake_set(${pack_deb_output_name} ${pack_deb_name})
  endif(pack_deb_output_name)
  if(pack_deb_output_version)
    remake_set(${pack_deb_output_version} ${pack_deb_version})
  endif(pack_deb_output_version)

  if(pack_deb_output_component)
    remake_unset(${pack_deb_output_component})
    remake_project_get(COMPONENTS OUTPUT pack_deb_components)

    foreach(pack_deb_component ${pack_deb_components})
      remake_component_get(${pack_deb_component} FILENAME
        OUTPUT pack_deb_filename)
      if(pack_deb_filename STREQUAL pack_deb_name)
        remake_set(${pack_deb_output_component} ${pack_deb_component})
      endif(pack_deb_filename STREQUAL pack_deb_name)
    endforeach(pack_deb_component)
  endif(pack_deb_output_component)
endmacro(remake_pack_resolve_deb)
