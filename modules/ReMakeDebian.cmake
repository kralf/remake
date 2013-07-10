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
include(ReMakeFind)

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
endif(NOT DEFINED REMAKE_DEBIAN_CMAKE)

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
      "^${debian_name}[:${REMAKE_DEBIAN_ARCHITECTURE}]*[\t].*$")
      string(REGEX REPLACE
        "^(${debian_name})[:${REMAKE_DEBIAN_ARCHITECTURE}]*[\t].*$"
        "\\1" debian_package_name ${debian_package})
      string(REGEX REPLACE
        "^${debian_name}[:${REMAKE_DEBIAN_ARCHITECTURE}]*[\t](.*)$"
        "\\1" debian_package_version ${debian_package})

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
      "^${debian_name}[:${REMAKE_DEBIAN_ARCHITECTURE}]*[\t].*$")
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

    if(NOT debian_result)
      string(REGEX REPLACE "\n" ";" debian_packages ${debian_packages})
      foreach(debian_package ${debian_packages})
        string(REGEX REPLACE "^([^:]+):.*$" "\\1" debian_package
          ${debian_package})
        remake_list_push(${debian_find_output} ${debian_package})
      endforeach(debian_package)
    endif(NOT debian_result)
  endif(APT_FILE_EXECUTABLE)
endmacro(remake_debian_find_file)
