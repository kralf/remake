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
include(ReMakePack)
include(ReMakeDebian)

### \brief ReMake distribution macros
#   The ReMake distribution macros facilitate automated distribution of
#   a ReMake project.

if(NOT DEFINED REMAKE_DISTRIBUTE_CMAKE)
  remake_set(REMAKE_DISTRIBUTE_CMAKE ON)

  remake_set(REMAKE_DISTRIBUTE_TARGET_SUFFIX distribution)
  remake_set(REMAKE_DISTRIBUTE_ALL_TARGET distributions)

  remake_file(REMAKE_DISTRIBUTE_DIR ReMakeDistributions TOPLEVEL)
  remake_file_rmdir(${REMAKE_DISTRIBUTE_DIR})
  remake_file_mkdir(${REMAKE_DISTRIBUTE_DIR})
endif(NOT DEFINED REMAKE_DISTRIBUTE_CMAKE)

### \brief Distribute a ReMake project according to the Debian standards.
#   This macro configures source package distribution for a ReMake project
#   under the Debian standards. Therefore, it generates a TGZ source archive
#   from the project by calling remake_pack_source_archive(). Moreover, the
#   macro takes care of creating all configuration files commonly required
#   for source packaging under the debian directory. The distribution is
#   then build from the sources by calling 'dpkg-buildpackage -S'. Note
#   that the distribution may define multiple binaries, one for each Debian
#   package defined by remake_pack_deb().
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
#     or override the architecture previously defined by remake_pack_deb().
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
macro(remake_distribute_deb)
  remake_arguments(PREFIX distribute_ VAR DISTRIBUTION VAR ALIAS
    VAR SECTION VAR ARCH VAR PRIORITY VAR CHANGELOG VAR URGENCY
    VAR COMPATIBILITY LIST DEPENDS LIST PASS LIST DEFINE VAR UPLOAD
    LIST EXCLUDE OPTION FORCE_CONSISTENCY ${ARGN})
  remake_set(distribute_section SELF DEFAULT misc)
  remake_set(distribute_arch SELF DEFAULT any)
  remake_set(distribute_priority SELF DEFAULT extra)
  remake_set(distribute_changelog SELF DEFAULT ${REMAKE_PROJECT_CHANGELOG})
  remake_set(distribute_distribution SELF DEFAULT ${REMAKE_DEBIAN_CODENAME})
  remake_set(distribute_alias SELF DEFAULT ${distribute_distribution})
  remake_set(distribute_urgency SELF DEFAULT low)
  remake_set(distribute_compatibility SELF DEFAULT 7)
  remake_set(distribute_pass SELF
    DEFAULT CMAKE_BUILD_TYPE CMAKE_INSTALL_PREFIX CMAKE_INSTALL_RPATH)
  remake_set(distribute_exclude SELF DEFAULT /debian/)

  remake_file_read(distribute_changelog_content ${distribute_changelog})
  string(REGEX REPLACE "([^\\\n]+).*" "\\1" distribute_changelog_header
    "${distribute_changelog_content}")
  string(REGEX REPLACE "[ ;]+" ";" distribute_changelog_parameters
    ${distribute_changelog_header})
  list(REMOVE_AT distribute_changelog_parameters 2)
  remake_set(distribute_parameters ${REMAKE_PROJECT_FILENAME}
    "(${REMAKE_PROJECT_VERSION})" "urgency=${distribute_urgency}")

  if(NOT distribute_force_consistency)
    if(NOT "${distribute_changelog_parameters}" STREQUAL
        "${distribute_parameters}")
      message(FATAL_ERROR "Changelog not consistent with the project settings!")
    endif(NOT "${distribute_changelog_parameters}" STREQUAL
      "${distribute_parameters}")
  endif(NOT distribute_force_consistency)

  remake_set(distribute_version
    "${REMAKE_PROJECT_VERSION}~${distribute_alias}")
  remake_set(distribute_changelog_parameters ${REMAKE_PROJECT_FILENAME}
    "(${distribute_version})" "${distribute_distribution},"
    "urgency=${distribute_urgency}")
  string(REGEX REPLACE ";" " " distribute_changelog_header
    "${distribute_changelog_parameters}")
  string(REGEX REPLACE "," ";" distribute_changelog_header
    "${distribute_changelog_header}")
  string(REGEX REPLACE "([^\\\n]+)(.*)" "${distribute_changelog_header}\\2"
    distribute_changelog_content "${distribute_changelog_content}")

  remake_file(distribute_package_dir ${REMAKE_PACK_DIR}/DEB)
  remake_file_glob(distribute_packages *.cpack
    WORKING_DIRECTORY ${distribute_package_dir} FILES)

  if(distribute_packages)
    remake_target_name(distribute_target ${distribute_alias}
      ${REMAKE_DISTRIBUTE_TARGET_SUFFIX})
    if(NOT TARGET ${distribute_target})
      remake_target(${distribute_target})
    endif(NOT TARGET ${distribute_target})
    if(NOT TARGET ${REMAKE_DISTRIBUTE_ALL_TARGET})
      remake_target(${REMAKE_DISTRIBUTE_ALL_TARGET})
    endif(NOT TARGET ${REMAKE_DISTRIBUTE_ALL_TARGET})
    add_dependencies(${REMAKE_DISTRIBUTE_ALL_TARGET} ${distribute_target})

    execute_process(COMMAND apt-cache show debian-policy
      OUTPUT_VARIABLE distribute_policy OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE
      ".*Version: ([0-9]+).([0-9]+).([0-9]+).*" "\\1.\\2.\\3"
      distribute_standards_version ${distribute_policy})
    remake_list_push(distribute_depends
      "debhelper (>= ${distribute_compatibility})" cmake)
    string(REGEX REPLACE ";" ", " distribute_depends "${distribute_depends}")

    remake_set(REMAKE_DISTRIBUTE_ALIAS ${REMAKE_DEBIAN_CODENAME}
      CACHE STRING "Name of the distribution on release build system.")
    remake_set(distribute_definitions
      "-DREMAKE_DISTRIBUTE_ALIAS=${distribute_alias}")
    foreach(distribute_var ${distribute_pass})
      remake_set(distribute_definitions
        "${distribute_definitions} -D${distribute_var}=${${distribute_var}}")
    endforeach(distribute_var)
    foreach(distribute_var ${distribute_define})
      remake_set(distribute_definitions
        "${distribute_definitions} -D${distribute_var}")
    endforeach(distribute_var)

    remake_set(distribute_control_source
      "Source: ${REMAKE_PROJECT_FILENAME}"
      "Section: ${distribute_section}"
      "Priority: ${distribute_priority}"
      "Maintainer: ${REMAKE_PROJECT_ADMIN} <${REMAKE_PROJECT_CONTACT}>"
      "Homepage: ${REMAKE_PROJECT_HOME}"
      "Standards-Version: ${distribute_standards_version}"
      "Build-Depends: ${distribute_depends}")

    remake_set(distribute_rules
      "#! /usr/bin/make -f"
      "export DH_OPTIONS\n"
      "%:"
      "\tdh $@\n"
      "override_dh_auto_configure:"
      "\tdh_auto_configure -- ${distribute_definitions}\n"
      "override_dh_pysupport:"
      "\t\n"
      "override_dh_installdocs:"
      "\t\n"
      "override_dh_installchangelogs:"
      "\t\n"
      "override_dh_auto_install:")

    remake_file(distribute_dir
      ${REMAKE_DISTRIBUTE_DIR}/debian/${distribute_alias})
    remake_file_mkdir(${distribute_dir})

    remake_set(distribute_control_release ${distribute_control_source})
    foreach(distribute_package ${distribute_packages})
      include(${distribute_package})

      if(NOT ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE} STREQUAL "all")
        remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${distribute_arch})
      endif(NOT ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE} STREQUAL "all")
      get_filename_component(distribute_component
        ${distribute_package} NAME_WE)
      remake_set(distribute_install "obj-$(DEB_BUILD_GNU_TYPE)")

      remake_unset(distribute_binary_depends)
      if(CPACK_DEBIAN_PACKAGE_DEPENDS)
        string(REGEX REPLACE "[,][ ]*" ";" distribute_dependencies
          ${CPACK_DEBIAN_PACKAGE_DEPENDS})

        foreach(distribute_dependency ${distribute_dependencies})
          remake_debian_resolve_package("${distribute_dependency}"
            OUTPUT distribute_component_dep)

          if(distribute_component_dep)
            remake_debian_decompose_package("${distribute_dependency}"
              OUTPUT_NAME distribute_name_dep
              OUTPUT_VERSION distribute_version_dep)

            remake_set(distribute_version_dep
              "${distribute_version_dep}~${distribute_alias}")
            remake_set(distribute_dependency
              "${distribute_name_dep} (${distribute_version_dep})")
          endif(distribute_component_dep)
          remake_list_push(distribute_binary_depends ${distribute_dependency})
        endforeach(distribute_dependency)
      endif(CPACK_DEBIAN_PACKAGE_DEPENDS)

      remake_unset(distribute_binary_predepends)
      if(CPACK_DEBIAN_PACKAGE_PREDEPENDS)
        string(REGEX REPLACE "[,][ ]*" ";" distribute_dependencies
          ${CPACK_DEBIAN_PACKAGE_PREDEPENDS})

        foreach(distribute_dependency ${distribute_dependencies})
          remake_debian_resolve_package("${distribute_dependency}"
            OUTPUT distribute_component_dep)

          if(distribute_component_dep)
            remake_debian_decompose_package("${distribute_dependency}"
              OUTPUT_NAME distribute_name_dep
              OUTPUT_VERSION distribute_version_dep)

            remake_set(distribute_version_dep
              "${distribute_version_dep}~${distribute_alias}")
            remake_set(distribute_dependency
              "${distribute_name_dep} (${distribute_version_dep})")
          endif(distribute_component_dep)
          remake_list_push(distribute_binary_predepends
            ${distribute_dependency})
        endforeach(distribute_dependency)
      endif(CPACK_DEBIAN_PACKAGE_PREDEPENDS)

      string(REPLACE ";" ", " distribute_recommends
        "${CPACK_DEBIAN_PACKAGE_RECOMMENDS}")
      string(REPLACE ";" ", " distribute_suggests
        "${CPACK_DEBIAN_PACKAGE_SUGGESTS}")
      string(REPLACE ";" ", " distribute_enhances
        "${CPACK_DEBIAN_PACKAGE_ENHANCES}")
      string(REPLACE ";" ", " distribute_breaks
        "${CPACK_DEBIAN_PACKAGE_BREAKS}")
      string(REPLACE ";" ", " distribute_conflicts
        "${CPACK_DEBIAN_PACKAGE_CONFLICTS}")
      string(REPLACE ";" ", " distribute_replaces
        "${CPACK_DEBIAN_PACKAGE_REPLACES}")
      string(REPLACE ";" ", " distribute_provides
        "${CPACK_DEBIAN_PACKAGE_PROVIDES}")
      remake_set(distribute_control_common
        "Recommends: ${distribute_recommends}"
        "Suggests: ${distribute_suggests}"
        "Enhances: ${distribute_enhances}"
        "Breaks: ${distribute_breaks}"
        "Conflicts: ${distribute_conflicts}"
        "Replaces: ${distribute_replaces}"
        "Provides: ${distribute_provides}"
        "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")

      remake_list_push(distribute_control_source
        "\nPackage: ${CPACK_PACKAGE_NAME}"
        "Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}"
        "Depends: # Determined by build system"
        "Pre-Depends: # Determined by build system"
        ${distribute_control_common})
      string(REPLACE ";" ", " distribute_binary_depends
        "${distribute_binary_depends}")
      string(REPLACE ";" ", " distribute_binary_predepends
        "${distribute_binary_predepends}")
      remake_list_push(distribute_control_release
        "\nPackage: ${CPACK_PACKAGE_NAME}"
        "Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}"
        "Depends: ${distribute_binary_depends}"
        "Pre-Depends: ${distribute_binary_predepends}"
        ${distribute_control_common})

      list(LENGTH CPACK_INSTALL_CMAKE_PROJECTS distribute_install_length)
      remake_set(distribute_install_index 2)
      while(${distribute_install_index} LESS ${distribute_install_length})
        list(GET CPACK_INSTALL_CMAKE_PROJECTS ${distribute_install_index}
          distribute_extra_component)
        remake_set(distribute_rule "\tDESTDIR=debian/${CPACK_PACKAGE_NAME}")
        remake_set(distribute_rule
          "${distribute_rule} cmake -DCOMPONENT=${distribute_extra_component}")
        remake_set(distribute_rule
          "${distribute_rule} -P ${distribute_install}/cmake_install.cmake")
        remake_list_push(distribute_rules "${distribute_rule}")
        math(EXPR distribute_install_index "${distribute_install_index}+4")
      endwhile(${distribute_install_index} LESS ${distribute_install_length})

      remake_unset(distribute_extra_names)
      foreach(distribute_extra ${CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA})
        get_filename_component(distribute_extra_name ${distribute_extra} NAME)
        file(COPY ${distribute_extra} DESTINATION ${distribute_dir}
          FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
        file(RENAME ${distribute_dir}/${distribute_extra_name}
          ${distribute_dir}/${CPACK_PACKAGE_NAME}.${distribute_extra_name})
      endforeach(distribute_extra ${CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA})

      remake_var_regex(pack_variables "^CPACK_")
      foreach(pack_var ${pack_variables})
        remake_set(${pack_var})
      endforeach(pack_var)
    endforeach(distribute_package)

    remake_file_write(${distribute_dir}/control
      LINES ${distribute_control_source})
    remake_file_write(${distribute_dir}/rules LINES ${distribute_rules})
    remake_file_permissions(${distribute_dir}/rules
      OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ)
    remake_file_write(${distribute_dir}/compat ${distribute_compatibility})
    remake_file_write(${distribute_dir}/changelog
      ${distribute_changelog_content})
    remake_file_name(distribute_build_dir ${distribute_alias})
    remake_set(distribute_build_path
      ${CMAKE_BINARY_DIR}/debian/${distribute_build_dir})
    remake_file_mkdir(${distribute_build_path})

    remake_unset(distribute_release_build OFF)
    if(${distribute_alias} STREQUAL ${REMAKE_DISTRIBUTE_ALIAS})
      if(EXISTS ${CMAKE_SOURCE_DIR}/debian/control)
        remake_file_create(${CMAKE_SOURCE_DIR}/debian/control)
        remake_file_write(${CMAKE_SOURCE_DIR}/debian/control
          LINES ${distribute_control_release})
        remake_set(distribute_release_build ON)
      endif(EXISTS ${CMAKE_SOURCE_DIR}/debian/control)
    endif(${distribute_alias} STREQUAL ${REMAKE_DISTRIBUTE_ALIAS})

    remake_pack_source_archive(GENERATOR TGZ EXCLUDE ${distribute_exclude})
    add_dependencies(${distribute_target} ${REMAKE_PACK_ALL_SOURCE_TARGET})

    if(distribute_release_build)
      message(STATUS "Distribution: ${distribute_alias} (Debian) *")
    else(distribute_release_build)
      message(STATUS "Distribution: ${distribute_alias} (Debian)")
    endif(distribute_release_build)

    remake_file_name(distribute_archive
      ${REMAKE_PROJECT_FILENAME}-${REMAKE_PROJECT_FILENAME_VERSION})
    remake_target_add_command(${distribute_target}
      COMMAND tar -xzf ${distribute_archive}.tar.gz -C ${distribute_build_path}
      COMMENT "Extracting ${REMAKE_PROJECT_NAME} source package")

    remake_set(distribute_archive_path
      ${distribute_build_path}/${distribute_archive})
    remake_target_add_command(${distribute_target}
      COMMAND cp -aT ${distribute_dir} ${distribute_archive_path}/debian)

    remake_target_add_command(${distribute_target}
      COMMAND dpkg-buildpackage -S
      WORKING_DIRECTORY ${distribute_archive_path}
      COMMENT "Building ${REMAKE_PROJECT_NAME} distribution")

    if(distribute_upload)
      remake_set(distribute_prompt
        "Upload distribution to ${distribute_upload} (y/n)?")
      remake_target_add_command(${distribute_target}
        COMMAND echo -n "${distribute_prompt} " && read REPLY &&
          eval test \$REPLY = y VERBATIM)
      remake_file_name(distribute_file ${REMAKE_PROJECT_FILENAME}
        ${REMAKE_PROJECT_FILENAME_VERSION}~${distribute_alias}
        source.changes)
      remake_target_add_command(${distribute_target}
        COMMAND dput ${distribute_upload}
          ${distribute_build_path}/${distribute_file}
        COMMENT "Uploading ${REMAKE_PROJECT_NAME} distribution")
    endif(distribute_upload)
  endif(distribute_packages)
endmacro(remake_distribute_deb)
