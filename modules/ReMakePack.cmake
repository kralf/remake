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
include(ReMakeComponent)
include(ReMakeDebian)

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
          "using component(s) ${pack_components} (${pack_generator})")
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
#   \optional[value] ARCH:architecture The package architecture that
#     is inscribed into the package manifest, defaults to
#     ${REMAKE_DEBIAN_ARCHITECTURE}.
#   \optional[value] COMPONENT:component The name of the install component to
#     generate the Debian package from, defaults to ${REMAKE_DEFAULT_COMPONENT}.
#     Note that following Debian conventions, the component name is used as
#     suffix to the package name. However, a component name matching
#     ${REMAKE_DEFAULT_COMPONENT} results in an empty suffix.
#   \optional[list] EXTRA_COMPONENTS:component An optional list of additional
#     install components to generate the Debian package from.
#   \optional[value] DESCRIPTION:string An optional description of the
#     install component that is appended to the project summary when
#     generating the Debian package description.
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
#   \optional[list] PREDEPENDS:pkg An optional list of mandatory package
#     dependencies that are matched and inscribed into the package manifest.
#     Pre-dependencies are similar to regular dependencies, except that the
#     packaging system will be told to complete the installation of these
#     packages before attempting to install the defined package. The format
#     of a pre-dependency should comply to Debian conventions, meaning
#     that an entry is of the form ${PACKAGE} [(>= ${VERSION})]. The macro
#     requires each pre-dependency to match against another binary package
#     defined in a previous call to remake_pack_deb() or an installed
#     package reported by dpkg on the build system. In the first case,
#     the version of the pre-dependency should be omitted as it will be
#     equated with ${REMAKE_PROJECT_VERSION}. In the second case, the
#     pre-dependency may be passed as regular expression. Failure to match
#     such expression will result in a fatal error.
#   \optional[list] RECOMMENDS:pkg An optional list of recommended packages
#     that are directly inscribed into the package manifest. The format of a
#     recommendation should comply to Debian conventions, meaning that
#     an entry is of the form ${PACKAGE} [(>= ${VERSION})]. As opposed to
#     mandatory dependencies, recommended packages are not matched against
#     the names of packages installed on the build system or defined in a
#     previous call to remake_pack_deb(). Therefore, a recommendation
#     should generally be precise. As this is often difficult when
#     attempting to build binary packages for several distributions, use
#     of the DEPENDS argument is strongly encouraged. Note that recommended
#     packages would generally be installed together with the defined package
#     in all but unusual cases.
#   \optional[list] SUGGESTS:pkg An optional list of suggested packages
#     that are directly inscribed into the package manifest. The format of a
#     suggestion should comply to Debian conventions, meaning that
#     an entry is of the form ${PACKAGE} [(>= ${VERSION})]. Suggested packages
#     are not matched against the names of packages installed on the build
#     system or defined in a previous call to remake_pack_deb(). They may
#     perhaps enhance the usefulness of the defined package, but not installing
#     is perfectly reasonable.
#   \optional[list] ENHANCES:pkg An optional list of packages that are
#     directly inscribed into the package manifest and meant to be enhanced
#     by the defined package. The format of an enhancement should comply to
#     Debian conventions and thus be of the form ${PACKAGE} [(>= ${VERSION})].
#     Enhanced packages are not matched against the names of packages installed
#     on the build system. They declare the opposite relationship to suggested
#     packages.
#   \optional[list] BREAKS:pkg An optional list of packages that are
#     directly inscribed into the package manifest and suspected to be broken
#     by the defined package. The format of a break should comply to Debian
#     conventions and thus be of the form ${PACKAGE} [(>= ${VERSION})].
#   \optional[list] CONFLICTS:pkg An optional list of packages that are
#     directly inscribed into the package manifest and suspected to conflict
#     with the defined package. The format of a conflict should comply to
#     Debian conventions and thus be of the form ${PACKAGE} [(>= ${VERSION})].
#     Conflicting packages generally pose stronger restrictions on package
#     handling than breaks.
#   \optional[list] REPLACES:pkg An optional list of packages that are
#     directly inscribed into the package manifest and suspected to contain
#     files which may be overwritten by the defined package. The format of a
#     replacement should comply to Debian conventions and thus be of the form
#     ${PACKAGE} [(>= ${VERSION})].
#   \optional[list] PROVIDES:pkg An optional list of virtual packages that are
#     directly inscribed into the package manifest. The mentioning of a virtual
#     package should comply to Debian conventions and thus only contain the
#     virtual package's name.
#   \optional[list] EXTRA:glob An optional list of glob expressions matching
#     extra control information files such as preinst, postinst, prerm, and
#     postrm to be included in the Debian package's control section.
macro(remake_pack_deb)
  remake_arguments(PREFIX pack_ VAR ARCH VAR COMPONENT LIST EXTRA_COMPONENTS
    VAR DESCRIPTION LIST DEPENDS LIST PREDEPENDS LIST RECOMMENDS LIST SUGGESTS
    LIST ENHANCES LIST BREAKS LIST CONFLICTS LIST REPLACES LIST PROVIDES
    LIST EXTRA ARGN depends ${ARGN})
  remake_set(pack_component SELF DEFAULT ${REMAKE_DEFAULT_COMPONENT})
  remake_set(pack_arch SELF DEFAULT ${REMAKE_DEBIAN_ARCHITECTURE})

  remake_component_get(${pack_component} BUILD OUTPUT pack_build)
  if(pack_build)
    if(NOT TARGET ${REMAKE_PACK_INSTALL_ALL_TARGET})
      remake_target(${REMAKE_PACK_INSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_INSTALL_ALL_TARGET})
    if(NOT TARGET ${REMAKE_PACK_UNINSTALL_ALL_TARGET})
      remake_target(${REMAKE_PACK_UNINSTALL_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_PACK_UNINSTALL_ALL_TARGET})

    remake_component_get(${pack_component} FILENAME OUTPUT pack_name)
    remake_file_name(pack_file ${pack_name} ${REMAKE_PROJECT_FILENAME_VERSION}
      ${pack_arch})

    remake_unset(pack_binary_deps pack_binary_predeps)
    remake_unset(pack_component_deps)
    remake_unset(pack_deb_packages)
    remake_unset(pack_binary_prefix)
    foreach(pack_dependency ${pack_depends} / ${pack_predepends})
      if(NOT pack_dependency STREQUAL "/")
        remake_debian_resolve_package("${pack_dependency}"
          OUTPUT pack_component_dep)

        if(pack_component_dep)
          remake_list_push(pack_component_deps ${pack_component_dep})
          remake_component_get(${pack_component_dep} FILENAME
            OUTPUT pack_name_dep)
          remake_set(pack_version_dep SELF DEFAULT "= ${REMAKE_PROJECT_VERSION}")
          remake_debian_compose_package(${pack_name_dep}
            VERSION ${pack_version_dep} OUTPUT pack_dependency)
        else(pack_component_dep)
          remake_debian_find_package("${pack_dependency}" OUTPUT pack_deb_found)

          list(LENGTH pack_deb_found pack_deb_length)
          if(NOT pack_deb_length)
            remake_set(pack_deb_message
              "No package on build system matches dependency")
            message(FATAL_ERROR "${pack_deb_message} ${pack_dependency}")
          elseif(pack_deb_length GREATER 1)
            remake_set(pack_deb_message
              "Multiple packages on build system match dependency")
            message(FATAL_ERROR "${pack_deb_message} ${pack_dependency}")
          else(NOT pack_deb_length)
            remake_set(pack_dependency ${pack_deb_found})
          endif(NOT pack_deb_length)
        endif(pack_component_dep)

        remake_list_push(pack_binary_${pack_binary_prefix}deps
          ${pack_dependency})
      else(NOT pack_dependency STREQUAL "/")
        remake_set(pack_binary_prefix "pre")
      endif(NOT pack_dependency STREQUAL "/")
    endforeach(pack_dependency)

    string(REPLACE ";" ", " pack_binary_deps "${pack_binary_deps}")
    string(REPLACE ";" ", " pack_recommends "${pack_recommends}")
    remake_file_glob(pack_extra ${pack_extra})
    remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${pack_binary_deps})
    remake_set(CPACK_DEBIAN_PACKAGE_PREDEPENDS ${pack_binary_predeps})
    remake_set(CPACK_DEBIAN_PACKAGE_RECOMMENDS ${pack_recommends})
    remake_set(CPACK_DEBIAN_PACKAGE_SUGGESTS ${pack_suggests})
    remake_set(CPACK_DEBIAN_PACKAGE_ENHANCES ${pack_enhances})
    remake_set(CPACK_DEBIAN_PACKAGE_BREAKS ${pack_breaks})
    remake_set(CPACK_DEBIAN_PACKAGE_CONFLICTS ${pack_conflicts})
    remake_set(CPACK_DEBIAN_PACKAGE_REPLACES ${pack_replaces})
    remake_set(CPACK_DEBIAN_PACKAGE_PROVIDES ${pack_provides})
    remake_set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA ${pack_extra})
    remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${pack_arch})
    remake_set(CPACK_PACKAGE_FILE_NAME ${pack_file})

    remake_pack_binary(DEB
      COMPONENT ${pack_component}
      ${EXTRA_COMPONENTS}
      NAME ${pack_name}
      ${DESCRIPTION})

    remake_target_name(pack_target ${pack_prefix}
      ${REMAKE_PACK_BINARY_TARGET_SUFFIX})
    remake_target_name(pack_install_target ${pack_prefix}
      ${REMAKE_PACK_INSTALL_TARGET_SUFFIX})
    remake_target(${pack_install_target}
      COMMAND sudo ${DPKG_EXECUTABLE} --install ${pack_file}.deb
      COMMENT "Installing ${pack_name} package")
    add_dependencies(${pack_install_target} ${pack_target})
    add_dependencies(${REMAKE_PACK_INSTALL_ALL_TARGET} ${pack_install_target})

    remake_target_name(pack_uninstall_target ${pack_prefix}
      ${REMAKE_PACK_UNINSTALL_TARGET_SUFFIX})
    remake_target(${pack_uninstall_target}
      COMMAND sudo ${DPKG_EXECUTABLE} --remove ${pack_name}
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
