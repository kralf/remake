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

### \brief ReMake Debian macros
#   The ReMake Debian macros provide abstracted access to Debian-specific
#   build system facilities.
#
#   \variable REMAKE_DEBIAN_FOUND Indicates if ReMake believes to run in a
#     Debian-compliant build environment.
#   \variable REMAKE_DEBIAN_ARCHITECTURE The name of the system architecture
#     as reported by the Debian package management. When cross-compiling,
#     it should be initialized in the toolchain file.
#   \variable REMAKE_DEBIAN_ID The distributor's ID of the build system's
#     Debian distribution.
#   \variable REMAKE_DEBIAN_CODENAME The code name of the build system's
#     Debian distribution.
#   \variable REMAKE_DEBIAN_RELEASE The release number of the build system's
#     Debian distribution.

include(ReMakePrivate)
include(ReMakeFind)

if(NOT DEFINED REMAKE_DEBIAN_CMAKE)
  remake_set(REMAKE_DEBIAN_CMAKE ON)
  remake_unset(REMAKE_DEBIAN_PACKAGES)
  remake_unset(REMAKE_DEBIAN_ID)
  remake_unset(REMAKE_DEBIAN_CODENAME)
  remake_unset(REMAKE_DEBIAN_RELEASE)

  if(NOT DEFINED REMAKE_DEBIAN_FOUND)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      remake_find_executable(dpkg OPTIONAL QUIET)
      if(DPKG_FOUND)
        remake_set(REMAKE_DEBIAN_FOUND ON)

        execute_process(
          COMMAND ${DPKG_EXECUTABLE} --print-architecture
          RESULT_VARIABLE debian_result
          OUTPUT_VARIABLE debian_arch
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        if(NOT debian_result)
          remake_set(REMAKE_DEBIAN_ARCHITECTURE ${debian_arch})
        endif(NOT debian_result)
      else(DPKG_FOUND)
        remake_set(REMAKE_DEBIAN_FOUND OFF)
      endif(DPKG_FOUND)
    else(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      remake_set(REMAKE_DEBIAN_FOUND OFF)
    endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

    if(REMAKE_DEBIAN_FOUND)
      remake_find_executable(lsb_release OPTIONAL QUIET)
      if(LSB_RELEASE_FOUND)
        execute_process(
          COMMAND ${LSB_RELEASE_EXECUTABLE} -i -s
          OUTPUT_VARIABLE REMAKE_DEBIAN_ID
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        execute_process(
          COMMAND ${LSB_RELEASE_EXECUTABLE} -c -s
          OUTPUT_VARIABLE REMAKE_DEBIAN_CODENAME
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        execute_process(
          COMMAND ${LSB_RELEASE_EXECUTABLE} -r -s
          OUTPUT_VARIABLE REMAKE_DEBIAN_RELEASE
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
      endif(LSB_RELEASE_FOUND)
    endif(REMAKE_DEBIAN_FOUND)

    remake_set(REMAKE_DEBIAN_FOUND ${REMAKE_DEBIAN_FOUND}
      CACHE BOOL "Build system is a Debian derivate.")
    remake_set(REMAKE_DEBIAN_ARCHITECTURE ${REMAKE_DEBIAN_ARCHITECTURE}
      CACHE STRING "Architecture reported by the Debian package management.")
    remake_set(REMAKE_DEBIAN_ID ${REMAKE_DEBIAN_ID}
      CACHE STRING "Distributor's ID of the Debian distribution.")
    remake_set(REMAKE_DEBIAN_CODENAME ${REMAKE_DEBIAN_CODENAME}
      CACHE STRING "Code name of the Debian distribution.")
    remake_set(REMAKE_DEBIAN_RELEASE ${REMAKE_DEBIAN_RELEASE}
      CACHE STRING "Release number of the Debian distribution.")

    if(REMAKE_DEBIAN_FOUND)
      if(REMAKE_DEBIAN_ID)
        remake_set(debian_description
          "${REMAKE_DEBIAN_ID} ${REMAKE_DEBIAN_RELEASE}")
        message(STATUS
          "The build system is Debian (${debian_description})")
      else(REMAKE_DEBIAN_ID)
        message(STATUS "The build system is an unknown Debian derivate")
      endif(REMAKE_DEBIAN_ID)
    endif(REMAKE_DEBIAN_FOUND)
  endif(NOT DEFINED REMAKE_DEBIAN_FOUND)
else(NOT DEFINED REMAKE_DEBIAN_CMAKE)
  return()
endif(NOT DEFINED REMAKE_DEBIAN_CMAKE)

include(ReMakeComponent)
include(ReMakeDistribute)
include(ReMakePack)

### \brief Compose a Debian-compliant package relationship specifier.
#   This macro composes a Debian-compliant package relationship specifier
#   from the package name and, if provided, the package version relation.
#   \required[value] name The name of the package for which to compose
#     the relationship specifier.
#   \optional[value] VERSION:relation An optional package version relation
#     which will be included in the relationship specifier. See the
#     Debian policies for version relation conventions.
#   \required[value] OUTPUT:variable The name of an output variable that
#     will be assigned the composed package relationship specifier.
macro(remake_debian_compose_package debian_name)
  remake_arguments(PREFIX debian_ VAR VERSION VAR OUTPUT ${ARGN})

  remake_set(${debian_output} ${debian_name})
  if(debian_version)
    remake_set(${debian_output} "${${debian_output}} (${debian_version})")
  endif(debian_version)
endmacro(remake_debian_compose_package)

### \brief Decompose a Debian-compliant package relationship specifier.
#   This macro decomposes a Debian-compliant package relationship specifier
#   into the package name and, if provided, the package version relation.
#   \required[value] specifier The Debian-compliant package relationship
#     specifier, consisting in the package name and an optional relation
#     for the package version following the name in parentheses. See the
#     Debian policies for package relationship specifier conventions.
#   \optional[value] OUTPUT_NAME:variable The name of an optional output
#     variable that will be assigned the extracted name of the package.
#   \optional[value] OUTPUT_VERSION:variable The name of an optional output
#     variable that will be assigned the extracted version relation.
macro(remake_debian_decompose_package debian_specifier)
  remake_arguments(PREFIX debian_ VAR OUTPUT_NAME VAR OUTPUT_VERSION ${ARGN})

  if(${debian_specifier} MATCHES "^[^ ]+[ ]+[(][^)]*[)]$")
    string(REGEX REPLACE "^([^ ]+)[ ]+[(]([^)]*)[)]$" "\\1"
      debian_name ${debian_specifier})
    string(REGEX REPLACE "^([^ ]+)[ ]+[(]([^)]*)[)]$" "\\2"
      debian_version ${debian_specifier})
  else(${debian_specifier} MATCHES "^[^ ]+[ ]+[(][^)]*[)]$")
    remake_set(debian_name ${debian_specifier})
    remake_unset(debian_version)
  endif(${debian_specifier} MATCHES "^[^ ]+[ ]+[(][^)]*[)]$")

  if(debian_output_name)
    remake_set(${debian_output_name} ${debian_name})
  endif(debian_output_name)
  if(debian_output_version)
    remake_set(${debian_output_version} ${debian_version})
  endif(debian_output_version)
endmacro(remake_debian_decompose_package)

### \brief Resolve project-internal Debian package dependencies.
#   This macro is a helper macro to resolve project-internal dependencies
#   between Debian packages. It takes a Debian-compliant package relationship
#   specifier, extracts the encoded package name by calling
#   remake_debian_decompose_package(), and matches the extracted package
#   name against the filenames defined for all project components to
#   deliver the corresponding component name.
#   \required[value] specifier The Debian-compliant package relationship
#     specifier as expected by remake_debian_decompose_package().
#   \required[value] OUTPUT:variable The name of an output variable that
#     will be assigned the name of the resolved component. Note that, if
#     none of the components matches the provided specifier, the output
#     variable will be undefined.
macro(remake_debian_resolve_package debian_specifier)
  remake_arguments(PREFIX debian_resolve_ VAR OUTPUT ${ARGN})
  remake_unset(${debian_resolve_output})

  remake_debian_decompose_package("${debian_specifier}"
    OUTPUT_NAME debian_name)
  remake_project_get(COMPONENTS OUTPUT debian_components)

  foreach(debian_component ${debian_components})
    remake_component_get(${debian_component} FILENAME
      OUTPUT debian_filename)
    if(debian_filename STREQUAL debian_name)
      remake_set(${debian_resolve_output} ${debian_component})
    endif(debian_filename STREQUAL debian_name)
  endforeach(debian_component)
endmacro(remake_debian_resolve_package)

### \brief Find a Debian package installed on the build system.
#   This macro employs the Debian dpkg tools in order to find a Debian
#   package installed on the build system. It takes a Debian package
#   relationship specifier containing a regular expression for the
#   package name and matches this expression against the output of
#   dpkg-query -W. Optionally, a version relation may be provided which,
#   if the regular expression for the package name could be matched,
#   will be compared against the version of that match. In addition to the
#   version, there exists the possibility to supply the name of a file or
#   directory. If no package could be matched according to the relationship
#   specifier, this file or directory name will be provided to dpkg-query -S
#   in order to find the package containing it.
#   \required[value] specifier The package relationship specifier of the
#     package to be found. Note that the specifier is not required to be
#     Debian-compliant in terms of the package name which may represent
#     a regular expression.
#   \optional[value] CONTAINS:filename The name of a file or directory
#     contained by the sought package. Note that this argument will only
#     apply if no package matching the provided relationship specifier could
#     be found on the build system.
#   \required[value] OUTPUT:variable The name of an output list variable
#     which will be assigned all matches being compliant with the provided
#     package specifier expression.
macro(remake_debian_find_package debian_specifier)
  remake_arguments(PREFIX debian_find_ VAR CONTAINS VAR OUTPUT ${ARGN})
  remake_unset(${debian_find_output})

  if(NOT REMAKE_DEBIAN_PACKAGES)
    if(NOT DPKG_QUERY_FOUND)
      remake_find_executable(dpkg-query QUIET OPTIONAL)
    endif(NOT DPKG_QUERY_FOUND)

    if(DPKG_QUERY_FOUND)
      execute_process(
        COMMAND ${DPKG_QUERY_EXECUTABLE} -W
        OUTPUT_VARIABLE debian_packages
        RESULT_VARIABLE debian_result
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

      if(NOT debian_result)
        string(REGEX REPLACE "\n" ";" REMAKE_DEBIAN_PACKAGES
          ${debian_packages})
      endif(NOT debian_result)
    endif(DPKG_QUERY_FOUND)
  endif(NOT REMAKE_DEBIAN_PACKAGES)

  remake_debian_decompose_package("${debian_specifier}"
    OUTPUT_NAME debian_name OUTPUT_VERSION debian_version)

  foreach(debian_package ${REMAKE_DEBIAN_PACKAGES})
    if("${debian_package}" MATCHES
      "^(${debian_name})(:${REMAKE_DEBIAN_ARCHITECTURE})?[\t].*$")
      string(REGEX REPLACE
        "^(${debian_name})(:${REMAKE_DEBIAN_ARCHITECTURE})?[\t].*$"
        "\\1" debian_package_name ${debian_package})
      string(REPLACE "+" "[+]" debian_package_regex ${debian_package_name})
      string(REGEX REPLACE
        "^${debian_package_regex}(:${REMAKE_DEBIAN_ARCHITECTURE})?[\t](.*)$"
        "\\2" debian_package_version ${debian_package})

      if(debian_version)
        if(DPKG_FOUND)
          string(REPLACE " " ";" debian_version_args ${debian_version})
          execute_process(
            COMMAND ${DPKG_EXECUTABLE} --compare-versions
              ${debian_package_version} ${debian_version_args}
            RESULT_VARIABLE debian_result
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

          if(NOT debian_result)
            remake_debian_compose_package(${debian_package_name}
              VERSION ${debian_version} OUTPUT debian_package_match)
            remake_list_push(${debian_find_output} ${debian_package_match})
          endif(NOT debian_result)
        endif(DPKG_FOUND)
      else(debian_version)
        remake_list_push(${debian_find_output} ${debian_package_name})
      endif(debian_version)
    endif("${debian_package}" MATCHES
      "^(${debian_name})(:${REMAKE_DEBIAN_ARCHITECTURE})?[\t].*$")
  endforeach(debian_package)

  if(DPKG_QUERY_FOUND)
    if(NOT ${debian_find_output} AND debian_find_contains)
      execute_process(
        COMMAND ${DPKG_QUERY_EXECUTABLE} -S ${debian_find_contains}
        OUTPUT_VARIABLE debian_packages
        RESULT_VARIABLE debian_result
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

      if(NOT debian_result)
        string(REGEX REPLACE "\n" ";" debian_packages ${debian_packages})
        foreach(debian_package ${debian_packages})
          string(REGEX REPLACE "^([^:]+):.*$" "\\1" debian_package
            ${debian_package})
          remake_list_push(${debian_find_output} ${debian_package})
        endforeach(debian_package)
      endif(NOT debian_result)
    endif(NOT ${debian_find_output} AND debian_find_contains)
  endif(DPKG_QUERY_FOUND)
endmacro(remake_debian_find_package)

### \brief Find the Debian package containing a file.
#   This macro employs the Debian apt-file tool in order to find the Debian
#   package containing a file which may or may not be installed on the build
#   system.
#   \required[value] pattern An expression matching the name of the file
#     to be found. This expression is passed as search pattern to apt-file.
#   \required[value] OUTPUT:variable The name of an output list variable
#     which will be assigned all packages containing the file.
macro(remake_debian_find_file debian_pattern)
  remake_arguments(PREFIX debian_find_ VAR OUTPUT ${ARGN})
  remake_unset(${debian_find_output})

  if(NOT APT_FILE_EXECUTABLE)
    find_program(APT_FILE_EXECUTABLE apt-file)
  endif(NOT APT_FILE_EXECUTABLE)

  if(APT_FILE_EXECUTABLE)
    execute_process(
      COMMAND ${APT_FILE_EXECUTABLE} search ${debian_pattern}
      OUTPUT_VARIABLE debian_packages
      RESULT_VARIABLE debian_result
      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    if(NOT debian_result AND debian_packages)
      string(REGEX REPLACE "\n" ";" debian_packages ${debian_packages})
      foreach(debian_package ${debian_packages})
        string(REGEX REPLACE "^([^:]+):.*$" "\\1" debian_package
          ${debian_package})
        remake_list_push(${debian_find_output} ${debian_package})
      endforeach(debian_package)
    endif(NOT debian_result AND debian_packages)
  endif(APT_FILE_EXECUTABLE)
endmacro(remake_debian_find_file)

### \brief Retrieve the Debian alternatives for a generic name.
#   This macro queries the Debian update-alternatives tool in order to
#   retrieve the alternative names for some generic name. Such generic
#   name may for instance refer to, but is not limited to, a program or
#   library with alternative implementations for the same or similar
#   functionalities. Further details are provided by the documentation
#   of the Debian alternatives system.
#   \required[value] name The generic name for which to retrieve the
#     alternative names.
#   \required[value] OUTPUT:variable The name of an output list variable
#     which will be assigned the alternative names in the system. If no
#     alternatives could be found, the output variable will be assigned
#     the generic name, assuming that it is the only alternative.
macro(remake_debian_get_alternatives debian_name)
  remake_arguments(PREFIX debian_ VAR OUTPUT ${ARGN})
  remake_set(${debian_output} ${debian_name})

  if(NOT UPDATE_ALTERNATIVES_EXECUTABLE)
    find_program(UPDATE_ALTERNATIVES_EXECUTABLE update-alternatives)
  endif(NOT UPDATE_ALTERNATIVES_EXECUTABLE)

  if(UPDATE_ALTERNATIVES_EXECUTABLE)
    execute_process(
      COMMAND ${UPDATE_ALTERNATIVES_EXECUTABLE} --list ${debian_name}
      OUTPUT_VARIABLE debian_alternatives
      RESULT_VARIABLE debian_result
      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    if(NOT debian_result AND debian_alternatives)
      string(REGEX REPLACE "\n" ";" ${debian_output} ${debian_alternatives})
    endif(NOT debian_result AND debian_alternatives)
  endif(UPDATE_ALTERNATIVES_EXECUTABLE)
endmacro(remake_debian_get_alternatives)

### \brief Generate a binary Debian package from a ReMake project component.
#   This macro configures package generation using CPack's DEB generator
#   for binary Debian packages on Debian-related build systems. It acquires
#   all the information necessary from the current project and component
#   settings and the arguments passed. In addition to creating a
#   component-specific package build target through remake_pack(), the macro
#   adds simplified package install and uninstall targets. Project-internal
#   dependencies between these targets are automatically resolved. Also, the
#   macro provides automated resolution of  dependencies on packages installed
#   on the build system.
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
#     defined in a previous call to remake_debian_pack() or an installed
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
#     defined in a previous call to remake_debian_pack() or an installed
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
#     previous call to remake_debian_pack(). Therefore, a recommendation
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
#     system or defined in a previous call to remake_debian_pack(). They may
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
#     postrm to be included in the Debian package's control section. The macro
#     calls remake_file_configure() to substitute variables within the files,
#     thereby replacing CMake's list separators by shell-compliant space
#     characters. See ReMakeFile for details.
macro(remake_debian_pack)
  if(NOT REMAKE_DEBIAN_FOUND)
    return()
  endif(NOT REMAKE_DEBIAN_FOUND)

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
    remake_file_configure(${pack_extra} LIST_SEPARATOR " " OUTPUT pack_extra)
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
endmacro(remake_debian_pack)

### \brief Distribute a ReMake project according to the Debian standards.
#   This macro configures source package distribution for a ReMake project
#   under the Debian standards on Debian-related build systems. Therefore,
#   it generates a TGZ source archive from the project by calling
#   remake_pack_source_archive(). Moreover, the macro takes care of creating
#   all configuration files commonly required for source packaging under the
#   debian directory. The distribution is then build from the sources by
#   calling 'dpkg-buildpackage -S'. Note that the distribution may define
#   multiple binaries, one for each Debian package defined by
#   remake_debian_pack().
#   \optional[value] DISTRIBUTION:distribution The name of the Debian
#     distribution for which the packages should be built, defaults to
#     ${REMAKE_DEBIAN_CODENAME}. This parameter is used for prefixing the
#     version specified in the changelog file. Consult the archive maintainers
#     for valid distribution names.
#   \optional[value] ALIAS:alias An optional alias for the distribution name,
#     defaulting to the actual name of the distribution. An alias can be
#     used to distinguish build configurations for the same distribution,
#     but having different parameters.
#   \optional[value] SECTION:section The archive area and section of the
#     distributed project, defaults to misc. See the Debian policies for
#     naming conventions, and consult the archive maintainer for a list
#     of valid areas and sections.
#   \optional[value] ARCH:architecture For architecture-dependent packages
#     in the distribution, this option may be used to explicitly specify
#     or override the architecture previously defined by remake_debian_pack().
#     The default value is any.
#   \optional[value] PRIORITY:priority The priority of the distributed
#     project, defaults to extra. See the Debian policies for valid priority
#     levels.
#   \optional[value] CHANGELOG:file The name of the changelog file to be
#     distributed with the sources, defaults to ${REMAKE_PROJECT_CHANGELOG}.
#     Note that the provided changelog file must follow the Debian standards
#     and should provide correct version information, the distribution name,
#     and the urgency level. The macro validates the information provided
#     in the changelog file against the current project settings and the
#     parameters provided, giving a fatal error in case of a mismatch. For
#     details about the standards and valid changelog properties, read the
#     Debian policy manual.
#   \optional[value] URGENCY:urgency The urgency of upgrading the distributed
#     packages from previous versions, defaults to low.  This parameter is
#     only used for validating the information contained in the changelog
#     prior to configuring the source package. See the Debian policies for
#     valid urgency values.
#   \optional[value] COMPATIBILITY:compatibility The debhelper compatibility
#     level, defaults to 7. See the debhelper documentation for valid
#     compatibility levels. Changing the compatibility to levels other than
#     7 is not recommended here, as the configuration files generated by
#     ReMake may not be compatible with earlier versions of debhelper.
#   \optional[list] DEPENDS:pkg An optional list of build dependencies for the
#     distribution, containing any packages in addition to debhelper and
#     cmake. The format of a dependency should comply to Debian conventions,
#     meaning that the dependency is of the form ${PACKAGE} [(>= ${VERSION})].
#   \optional[list] PASS:var An optional list containing the names of
#     defined CMake variables. The macro will pass the given variable names
#     and values during the configuration stage of the distribution.
#     By default, the variables CMAKE_BUILD_TYPE, CMAKE_INSTALL_PREFIX, and
#     CMAKE_INSTALL_RPATH are included in the list.
#   \optional[list] DEFINE:var An optional list of variable names and values
#     of the form ${VAR}=${VALUE} to be passed during the configuration
#     stage of the distribution.
#   \optional[list] OVERRIDE:target An optional list of target names to be
#     overridden in debian/rules in addition to dh_auto_configure,
#     dh_auto_install, dh_installdocs, dh_installchangelogs, and dh_pysupport.
#     Note that target overriding can sometimes be used to fix build problems.
#   \optional[var] UPLOAD:host An optional host for uploading the generated
#     source package via the dput Debian tool. See the dput documentation
#     for valid host formats.
#   \optional[list] EXCLUDE:pattern An optional list of patterns passed to
#     remake_pack_source_archive(), matching additional files or directories
#     in the source tree which shall not be distributed. By default,
#     the list contains /debian/ to prevent possible conflicts with the
#     distribution's debian directory.
#   \optional[option] FORCE_CONSISTENCY With this option being present, the
#     macro will not validate consistency of the changelog file against the
#     project settings. Note that use of the option is thus strongly
#     discouraged, except in rare cases where the changelog content needs
#     to be adapted during the run of CMake.
macro(remake_debian_distribute)
  if(NOT REMAKE_DEBIAN_FOUND)
    return()
  endif(NOT REMAKE_DEBIAN_FOUND)

  remake_arguments(PREFIX debian_ VAR DISTRIBUTION VAR ALIAS
    VAR SECTION VAR ARCH VAR PRIORITY VAR CHANGELOG VAR URGENCY
    VAR COMPATIBILITY LIST DEPENDS LIST PASS LIST DEFINE LIST OVERRIDE
    VAR UPLOAD LIST EXCLUDE OPTION FORCE_CONSISTENCY ${ARGN})
  remake_set(debian_section SELF DEFAULT misc)
  remake_set(debian_arch SELF DEFAULT any)
  remake_set(debian_priority SELF DEFAULT extra)
  remake_set(debian_changelog SELF DEFAULT ${REMAKE_PROJECT_CHANGELOG})
  remake_set(debian_distribution SELF DEFAULT ${REMAKE_DEBIAN_CODENAME})
  remake_set(debian_alias SELF DEFAULT ${debian_distribution})
  remake_set(debian_urgency SELF DEFAULT low)
  remake_set(debian_compatibility SELF DEFAULT 7)
  remake_set(debian_pass SELF
    DEFAULT CMAKE_BUILD_TYPE CMAKE_INSTALL_PREFIX CMAKE_INSTALL_RPATH)
  remake_set(debian_exclude SELF DEFAULT /debian/)

  remake_file_read(debian_changelog_content ${debian_changelog})
  string(REGEX REPLACE "([^\\\n]+).*" "\\1" debian_changelog_header
    "${debian_changelog_content}")
  string(REGEX REPLACE "[ ;]+" ";" debian_changelog_parameters
    ${debian_changelog_header})
  list(REMOVE_AT debian_changelog_parameters 2)
  remake_set(debian_parameters ${REMAKE_PROJECT_NAME}
    "(${REMAKE_PROJECT_VERSION})" "urgency=${debian_urgency}")

  if(NOT debian_force_consistency)
    if(NOT "${debian_changelog_parameters}" STREQUAL
        "${debian_parameters}")
      message(FATAL_ERROR "Changelog not consistent with the project settings!")
    endif(NOT "${debian_changelog_parameters}" STREQUAL
      "${debian_parameters}")
  endif(NOT debian_force_consistency)

  remake_set(debian_version
    "${REMAKE_PROJECT_VERSION}~${debian_alias}")
  remake_set(debian_changelog_parameters ${REMAKE_PROJECT_NAME}
    "(${debian_version})" "${debian_distribution},"
    "urgency=${debian_urgency}")
  string(REGEX REPLACE ";" " " debian_changelog_header
    "${debian_changelog_parameters}")
  string(REGEX REPLACE "," ";" debian_changelog_header
    "${debian_changelog_header}")
  string(REGEX REPLACE "([^\\\n]+)(.*)" "${debian_changelog_header}\\2"
    debian_changelog_content "${debian_changelog_content}")

  remake_file(debian_package_dir ${REMAKE_PACK_DIR}/DEB)
  remake_file_glob(debian_packages *.cpack
    WORKING_DIRECTORY ${debian_package_dir} FILES)

  if(debian_packages)
    remake_target_name(debian_target ${debian_alias}
      ${REMAKE_DISTRIBUTE_TARGET_SUFFIX})
    if(NOT TARGET ${debian_target})
      remake_target(${debian_target})
    endif(NOT TARGET ${debian_target})
    if(NOT TARGET ${REMAKE_DISTRIBUTE_ALL_TARGET})
      remake_target(${REMAKE_DISTRIBUTE_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_DISTRIBUTE_ALL_TARGET})
    add_dependencies(${REMAKE_DISTRIBUTE_ALL_TARGET} ${debian_target})

    execute_process(COMMAND apt-cache show debian-policy
      OUTPUT_VARIABLE debian_policy OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE
      ".*Version: ([0-9]+).([0-9]+).([0-9]+).*" "\\1.\\2.\\3"
      debian_standards_version ${debian_policy})
    remake_list_push(debian_depends
      "debhelper (>= ${debian_compatibility})" cmake)
    string(REGEX REPLACE ";" ", " debian_depends "${debian_depends}")

    remake_set(REMAKE_DISTRIBUTE_ALIAS ${REMAKE_DEBIAN_CODENAME}
      CACHE STRING "Name of the distribution on release build system.")
    remake_set(debian_definitions
      "-DREMAKE_DISTRIBUTE_ALIAS=${debian_alias}")
    foreach(debian_var ${debian_pass})
      remake_set(debian_definitions
        "${debian_definitions} -D${debian_var}=${${debian_var}}")
    endforeach(debian_var)
    foreach(debian_var ${debian_define})
      remake_set(debian_definitions
        "${debian_definitions} -D${debian_var}")
    endforeach(debian_var)

    remake_set(debian_control_source
      "Source: ${REMAKE_PROJECT_NAME}"
      "Section: ${debian_section}"
      "Priority: ${debian_priority}"
      "Maintainer: ${REMAKE_PROJECT_ADMIN} <${REMAKE_PROJECT_CONTACT}>"
      "Homepage: ${REMAKE_PROJECT_HOME}"
      "Standards-Version: ${debian_standards_version}"
      "Build-Depends: ${debian_depends}")

    remake_set(debian_rules
      "#! /usr/bin/make -f"
      "export DH_OPTIONS\n"
      "%:"
      "\tdh $@\n"
      "override_dh_auto_configure:"
      "\tdh_auto_configure -- ${debian_definitions}\n"
      "override_dh_pysupport:"
      "\t\n"
      "override_dh_installdocs:"
      "\t\n"
      "override_dh_installchangelogs:"
      "\t\n")

    foreach(debian_target ${debian_override})
      remake_list_push(debian_rules
        "override_${debian_target}:"
        "\t\n")
    endforeach(debian_target)

    remake_list_push(debian_rules
      "override_dh_auto_install:")
    remake_file(debian_dir
      ${REMAKE_DISTRIBUTE_DIR}/debian/${debian_alias})
    remake_file_mkdir(${debian_dir})

    remake_set(debian_control_release ${debian_control_source})
    foreach(debian_package ${debian_packages})
      include(${debian_package})

      if(NOT ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE} STREQUAL "all")
        remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${debian_arch})
      endif(NOT ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE} STREQUAL "all")
      get_filename_component(debian_component
        ${debian_package} NAME_WE)
      remake_set(debian_install "obj-$(DEB_BUILD_GNU_TYPE)")

      remake_unset(debian_binary_depends)
      if(CPACK_DEBIAN_PACKAGE_DEPENDS)
        string(REGEX REPLACE "[,][ ]*" ";" debian_dependencies
          ${CPACK_DEBIAN_PACKAGE_DEPENDS})

        foreach(debian_dependency ${debian_dependencies})
          remake_debian_resolve_package("${debian_dependency}"
            OUTPUT debian_component_dep)

          if(debian_component_dep)
            remake_debian_decompose_package("${debian_dependency}"
              OUTPUT_NAME debian_name_dep
              OUTPUT_VERSION debian_version_dep)

            remake_set(debian_version_dep
              "${debian_version_dep}~${debian_alias}")
            remake_set(debian_dependency
              "${debian_name_dep} (${debian_version_dep})")
          endif(debian_component_dep)
          remake_list_push(debian_binary_depends ${debian_dependency})
        endforeach(debian_dependency)
      endif(CPACK_DEBIAN_PACKAGE_DEPENDS)

      remake_unset(debian_binary_predepends)
      if(CPACK_DEBIAN_PACKAGE_PREDEPENDS)
        string(REGEX REPLACE "[,][ ]*" ";" debian_dependencies
          ${CPACK_DEBIAN_PACKAGE_PREDEPENDS})

        foreach(debian_dependency ${debian_dependencies})
          remake_debian_resolve_package("${debian_dependency}"
            OUTPUT debian_component_dep)

          if(debian_component_dep)
            remake_debian_decompose_package("${debian_dependency}"
              OUTPUT_NAME debian_name_dep
              OUTPUT_VERSION debian_version_dep)

            remake_set(debian_version_dep
              "${debian_version_dep}~${debian_alias}")
            remake_set(debian_dependency
              "${debian_name_dep} (${debian_version_dep})")
          endif(debian_component_dep)
          remake_list_push(debian_binary_predepends
            ${debian_dependency})
        endforeach(debian_dependency)
      endif(CPACK_DEBIAN_PACKAGE_PREDEPENDS)

      string(REPLACE ";" ", " debian_recommends
        "${CPACK_DEBIAN_PACKAGE_RECOMMENDS}")
      string(REPLACE ";" ", " debian_suggests
        "${CPACK_DEBIAN_PACKAGE_SUGGESTS}")
      string(REPLACE ";" ", " debian_enhances
        "${CPACK_DEBIAN_PACKAGE_ENHANCES}")
      string(REPLACE ";" ", " debian_breaks
        "${CPACK_DEBIAN_PACKAGE_BREAKS}")
      string(REPLACE ";" ", " debian_conflicts
        "${CPACK_DEBIAN_PACKAGE_CONFLICTS}")
      string(REPLACE ";" ", " debian_replaces
        "${CPACK_DEBIAN_PACKAGE_REPLACES}")
      string(REPLACE ";" ", " debian_provides
        "${CPACK_DEBIAN_PACKAGE_PROVIDES}")
      remake_set(debian_control_common
        "Recommends: ${debian_recommends}"
        "Suggests: ${debian_suggests}"
        "Enhances: ${debian_enhances}"
        "Breaks: ${debian_breaks}"
        "Conflicts: ${debian_conflicts}"
        "Replaces: ${debian_replaces}"
        "Provides: ${debian_provides}"
        "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")

      remake_list_push(debian_control_source
        "\nPackage: ${CPACK_PACKAGE_NAME}"
        "Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}"
        "Depends: # Determined by build system"
        "Pre-Depends: # Determined by build system"
        ${debian_control_common})
      string(REPLACE ";" ", " debian_binary_depends
        "${debian_binary_depends}")
      string(REPLACE ";" ", " debian_binary_predepends
        "${debian_binary_predepends}")
      remake_list_push(debian_control_release
        "\nPackage: ${CPACK_PACKAGE_NAME}"
        "Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}"
        "Depends: ${debian_binary_depends}"
        "Pre-Depends: ${debian_binary_predepends}"
        ${debian_control_common})

      list(LENGTH CPACK_INSTALL_CMAKE_PROJECTS debian_install_length)
      remake_set(debian_install_index 2)
      while(${debian_install_index} LESS ${debian_install_length})
        list(GET CPACK_INSTALL_CMAKE_PROJECTS ${debian_install_index}
          debian_extra_component)
        remake_set(debian_rule "\tDESTDIR=debian/${CPACK_PACKAGE_NAME}")
        remake_set(debian_rule
          "${debian_rule} cmake -DCOMPONENT=${debian_extra_component}")
        remake_set(debian_rule
          "${debian_rule} -P ${debian_install}/cmake_install.cmake")
        remake_list_push(debian_rules "${debian_rule}")
        math(EXPR debian_install_index "${debian_install_index}+4")
      endwhile(${debian_install_index} LESS ${debian_install_length})

      remake_unset(debian_extra_names)
      foreach(debian_extra ${CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA})
        get_filename_component(debian_extra_name ${debian_extra} NAME)
        file(COPY ${debian_extra} DESTINATION ${debian_dir}
          FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
        file(RENAME ${debian_dir}/${debian_extra_name}
          ${debian_dir}/${CPACK_PACKAGE_NAME}.${debian_extra_name})
      endforeach(debian_extra ${CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA})

      remake_var_regex(pack_variables "^CPACK_")
      foreach(pack_var ${pack_variables})
        remake_set(${pack_var})
      endforeach(pack_var)
    endforeach(debian_package)

    remake_file_write(${debian_dir}/control
      LINES ${debian_control_source})
    remake_file_write(${debian_dir}/rules LINES ${debian_rules})
    remake_file_permissions(${debian_dir}/rules
      OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ)
    remake_file_write(${debian_dir}/compat ${debian_compatibility})
    remake_file_write(${debian_dir}/changelog
      ${debian_changelog_content})
    remake_file_name(debian_build_dir ${debian_alias})
    remake_set(debian_build_path
      ${CMAKE_BINARY_DIR}/debian/${debian_build_dir})
    remake_file_mkdir(${debian_build_path})

    remake_unset(debian_release_build OFF)
    if(${debian_alias} STREQUAL ${REMAKE_DISTRIBUTE_ALIAS})
      if(EXISTS ${CMAKE_SOURCE_DIR}/debian/control)
        remake_file_create(${CMAKE_SOURCE_DIR}/debian/control)
        remake_file_write(${CMAKE_SOURCE_DIR}/debian/control
          LINES ${debian_control_release})
        remake_set(debian_release_build ON)
      endif(EXISTS ${CMAKE_SOURCE_DIR}/debian/control)
    endif(${debian_alias} STREQUAL ${REMAKE_DISTRIBUTE_ALIAS})

    remake_pack_source_archive(GENERATOR TGZ EXCLUDE ${debian_exclude})
    add_dependencies(${debian_target} ${REMAKE_PACK_ALL_SOURCE_TARGET})

    if(debian_release_build)
      message(STATUS "Distribution: ${debian_alias} (Debian) *")
    else(debian_release_build)
      message(STATUS "Distribution: ${debian_alias} (Debian)")
    endif(debian_release_build)

    remake_file_name(debian_archive
      ${REMAKE_PROJECT_NAME}-${REMAKE_PROJECT_FILENAME_VERSION})
    remake_target_add_command(${debian_target}
      COMMAND tar -xzf ${debian_archive}.tar.gz -C ${debian_build_path}
      COMMENT "Extracting ${REMAKE_PROJECT_NAME} source package")

    remake_set(debian_archive_path
      ${debian_build_path}/${debian_archive})
    remake_target_add_command(${debian_target}
      COMMAND cp -aT ${debian_dir} ${debian_archive_path}/debian)

    remake_target_add_command(${debian_target}
      COMMAND dpkg-buildpackage -S
      WORKING_DIRECTORY ${debian_archive_path}
      COMMENT "Building ${REMAKE_PROJECT_NAME} distribution")

    if(debian_upload)
      remake_set(debian_prompt
        "Upload distribution to ${debian_upload} (y/n)?")
      remake_target_add_command(${debian_target}
        COMMAND echo -n "${debian_prompt} " && read REPLY &&
          eval test \$REPLY = y VERBATIM)
      remake_file_name(debian_file ${REMAKE_PROJECT_NAME}
        ${REMAKE_PROJECT_FILENAME_VERSION}~${debian_alias}
        source.changes)
      remake_target_add_command(${debian_target}
        COMMAND dput ${debian_upload}
          ${debian_build_path}/${debian_file}
        COMMENT "Uploading ${REMAKE_PROJECT_NAME} distribution")
    endif(debian_upload)
  endif(debian_packages)
endmacro(remake_debian_distribute)
