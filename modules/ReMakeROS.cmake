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

include(ReMakeProject)
include(ReMakeFind)
include(ReMakeFile)
include(ReMakeComponent)

include(ReMakePrivate)

### \brief ReMake ROS build macros
#   The ReMake ROS build macros provide access to the ROS build system
#   configuration without requirement for the ROS CMake API. Note that
#   all ROS environment variables should be initialized by sourcing the
#   corresponding ROS setup script prior to calling CMake.

remake_set(REMAKE_ROS_DIR ReMakeROS)
remake_set(REMAKE_ROS_STACK_DIR ${REMAKE_ROS_DIR}/stacks)
remake_set(REMAKE_ROS_PACKAGE_DIR ${REMAKE_ROS_DIR}/packages)
remake_set(REMAKE_ROS_ALL_MANIFESTS_TARGET ros_manifests)
remake_set(REMAKE_ROS_STACK_MANIFEST_TARGET_SUFFIX ros_stack_manifest)
remake_set(REMAKE_ROS_PACKAGE_MANIFEST_TARGET_SUFFIX ros_package_manifest)

### \brief Configure the ROS build system.
#   This macro discovers ROS from its environment variables, initializes
#   ${ROS_PATH} and ${ROS_DISTRIBUTION}. Note that the macro automatically
#   gets invoked by the macros defined in this module. It needs not be called
#   directly from a CMakeLists.txt file.
macro(remake_ros)
  if(NOT ROS_FOUND)
    remake_find_file(include/ros/ros.h PACKAGE ROS PATHS "$ENV{ROS_ROOT}/..")
    remake_set(ROS_DISTRIBUTION $ENV{ROS_DISTRO} CACHE STRING
      "Name of the ROS distribution.")
  endif(NOT ROS_FOUND)

  if(NOT ROS_DISTRIBUTION)
    message(FATAL_ERROR "ROS distribution is undefined.")
  endif(NOT ROS_DISTRIBUTION)

  if(ROS_FOUND)
    if(${ROS_DISTRIBUTION} STRLESS groovy)
      remake_file_mkdir(${REMAKE_ROS_STACK_DIR} TOPLEVEL)
    endif(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_file_mkdir(${REMAKE_ROS_PACKAGE_DIR} TOPLEVEL)
  endif(ROS_FOUND)
endmacro(remake_ros)

### \brief Define a ReMake ROS project.
#   This macro initializes all the ReMake project variables according to the
#   ROS conventions by calling remake_project(). For naming compliance, the
#   provided project name is therefore prefixed with ros-${ROS_DISTRIBUTION}-
#   to obtain the default FILENAME argument for remake_project(). Further, the
#   default install prefix is initialized to ${ROS_PATH} as provided by the
#   indicated ROS distribution. In place of remake_project(), the macro should
#   appear first in the ROS project root's CMakeLists.txt file.
#   \required[value] name The name of the ROS project to be defined, a string
#     value which will receive the mandatory suffix -ros before being passed
#     to remake_project().
#   \optional[value] FILENAME:name An optional and valid filename that is
#     used as FILENAME argument to remake_project(), defaults to the filename
#     conversion of ros-${ROS_DISTRIBUTION}-${PROJECT_NAME}.
#   \optional[value] INSTALL:dir The directory that shall be used as the
#     ROS project's preset install prefix, defaults to the directory indicated
#     by ${ROS_PATH}.
#   \optional[list] arg A list of optional arguments to be forwarded to
#     remake_project(). See ReMakeProject for the correct usage.
macro(remake_ros_project ros_name)
  remake_arguments(PREFIX ros_ VAR INSTALL VAR FILENAME ARGN args ${ARGN})

  remake_ros()

  remake_set(ros_install SELF DEFAULT ${ROS_PATH})
  remake_file_name(ros_filename_conversion
    "ros-${ROS_DISTRIBUTION}-${ros_name}")
  remake_set(ros_filename SELF DEFAULT ${ros_filename_conversion})

  remake_project("${ros_name}-ros" FILENAME ${ros_filename}
    INSTALL ${ros_install} ${ros_args})
endmacro(remake_ros_project)

### \brief Find a ROS stack.
#   Depending on the indicated ROS distribution, this macro discovers a
#   ROS stack or meta-package in the distribution under ${ROS_PATH}.
#   Regarding future portability, its use should however be avoided in favor
#   of remake_ros_find_package(). For ROS "groovy" and later distributions,
#   remake_ros_find_stack() is silently diverted to remake_ros_find_package().
#   Otherwise, the macro calls rosstack and, if the ROS stack was found,
#   sets the variable name conversion of ROS_${STACK}_FOUND to TRUE and
#   initializes ROS_${STACK}_PATH accordingly. All packages contained in
#   the ROS stack are further searched by remake_ros_find_package(), and
#   the corresponding package-specificresult variables are concatenated to
#   initialize ROS_${STACK}_INCLUDE_DIRS, ROS_${STACK}_LIBRARIES, and
#   ROS_${STACK}_LIBRARY_DIRS.
#   \required[value] stack The name of the ROS stack to be discovered.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_ros_find_stack ros_stack)
  remake_arguments(PREFIX ros_ OPTION OPTIONAL ${ARGN})
  remake_set(ros_optional ${OPTIONAL})

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_find_executable(rosstack PATHS "${ROS_PATH}/bin")

    remake_var_name(ros_path_var ROS ${ros_stack} PATH)
    remake_var_name(ros_include_dirs_var ROS ${ros_stack} INCLUDE_DIRS)
    remake_var_name(ros_libraries_var ROS ${ros_stack} LIBRARIES)
    remake_var_name(ros_library_dirs_var ROS ${ros_stack} LIBRARY_DIRS)

    execute_process(
      COMMAND ${ROSSTACK_EXECUTABLE} find ${ros_stack}
      RESULT_VARIABLE ros_result
      OUTPUT_VARIABLE ${ros_path_var}
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET)

    if(ros_result)
      remake_set(${ros_path_var} ${ros_path_var}-NOTFOUND CACHE PATH
        "Path to ROS stack ${ros_stack}.")
    else(ros_result)
      execute_process(
        COMMAND ${ROSSTACK_EXECUTABLE} contents ${ros_stack}
        OUTPUT_VARIABLE ros_packages
        OUTPUT_STRIP_TRAILING_WHITESPACE)

      remake_set(${ros_path_var} ${${ros_path_var}} CACHE PATH
        "Path to ROS stack ${ros_stack}.")
      if(ros_packages)
        string(REGEX REPLACE "[ \n]+" ";" ros_packages ${ros_packages})
      endif(ros_packages)

      remake_unset(${ros_include_dirs_var} ${ros_libraries_var}
        ${ros_library_dirs_var})
      foreach(ros_package ${ros_packages})
        remake_var_name(ros_pkg_include_dirs_var ROS ${ros_package}
          INCLUDE_DIRS)
        remake_var_name(ros_pkg_libraries_var ROS ${ros_package} LIBRARIES)
        remake_var_name(ros_pkg_library_dirs_var ROS ${ros_package}
          LIBRARY_DIRS)

        remake_ros_find_package(${ros_package} ${ros_optional})

        remake_list_push(${ros_include_dirs_var}
          ${${ros_pkg_include_dirs_var}})
        remake_list_push(${ros_libraries_var} ${${ros_pkg_libraries_var}})
        remake_list_push(${ros_library_dirs_var}
          ${${ros_pkg_library_dirs_var}})
      endforeach(ros_package ${ros_packages})
    endif(ros_result)

    remake_find_result("ROS ${ros_stack}" ${${ros_path_var}} ${ros_optional})
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_find_package(${ros_stack} ${ros_optional})
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_find_stack)

### \brief Find a ROS package.
#   Depending on the indicated ROS distribution and the provided arguments,
#   this macro discovers a ROS package, meta-package, or stack in the
#   distribution under ${ROS_PATH}. Regarding future portability, its use is
#   strongly encouraged over remake_ros_find_stack(). For ROS "fuerte" and
#   earlier distributions, remake_ros_find_package() is silently diverted to
#   remake_ros_find_stack() if the META option is present. Otherwise, the macro
#   calls rospack and, if the ROS package or meta-package was found, the
#   variable name conversion of ROS_${PACKAGE}_FOUND is set to TRUE, and
#   ROS_${PACKAGE}_PATH, ROS_${PACKAGE}_INCLUDE_DIRS, ROS_${PACKAGE}_LIBRARIES,
#   and ROS_${PACKAGE}_LIBRARY_DIRS are initialized accordingly. All
#   directories in ROS_${PACKAGE}_INCLUDE_DIRS are then added to the include
#   path by calling remake_include(). In addition, the directories in which the
#   linker will look for the package libraries is specified by passing
#   ROS_${PACKAGE}_LIBRARY_DIRS to CMake's link_directories().
#   \required[value] package The name of the ROS package to be discovered.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
#   \optional[option] META If provided, the macro will be aware that the
#     package is a meta-package. For ROS "groovy" and later distributions,
#     the option is meaningless, whereas it ensures portability for ROS
#     "fuerte" and earlier distributions.
macro(remake_ros_find_package ros_package)
  remake_arguments(PREFIX ros_ OPTION OPTIONAL OPTION META ${ARGN})
  remake_set(ros_optional ${OPTIONAL})

  remake_ros()

  if(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
    remake_find_executable(rospack PATHS "${ROS_PATH}/bin")

    remake_var_name(ros_path_var ROS ${ros_package} PATH)
    remake_var_name(ros_include_dirs_var ROS ${ros_package} INCLUDE_DIRS)
    remake_var_name(ros_libraries_var ROS ${ros_package} LIBRARIES)
    remake_var_name(ros_library_dirs_var ROS ${ros_package} LIBRARY_DIRS)

    execute_process(
      COMMAND ${ROSPACK_EXECUTABLE} find ${ros_package}
      RESULT_VARIABLE ros_result
      OUTPUT_VARIABLE ${ros_path_var}
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET)

    if(ros_result)
      remake_set(${ros_path_var} ${ros_path_var}-NOTFOUND CACHE PATH
        "Path to ROS package ${ros_package}.")
    else(ros_result)
      execute_process(
        COMMAND ${ROSPACK_EXECUTABLE} cflags-only-I ${ros_package}
        OUTPUT_VARIABLE ros_include_dirs
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      execute_process(
        COMMAND ${ROSPACK_EXECUTABLE} libs-only-l ${ros_package}
        OUTPUT_VARIABLE ros_libraries
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      execute_process(
        COMMAND ${ROSPACK_EXECUTABLE} libs-only-L ${ros_package}
        OUTPUT_VARIABLE ros_library_dirs
        OUTPUT_STRIP_TRAILING_WHITESPACE)

      remake_set(${ros_path_var} ${${ros_path_var}} CACHE PATH
        "Path to ROS package ${ros_package}.")
      if(ros_include_dirs)
        string(REGEX REPLACE "[ ]+" ";" ${ros_include_dirs_var}
          ${ros_include_dirs})
        remake_include(${${ros_include_dirs_var}})
      else(ros_include_dirs)
        remake_unset(${ros_include_dirs_var})
      endif(ros_include_dirs)
      if(ros_libraries)
        string(REGEX REPLACE "[ ]+" ";" ${ros_libraries_var} ${ros_libraries})
      else(ros_libraries)
        remake_unset(${ros_libraries_var})
      endif(ros_libraries)
      if(ros_library_dirs)
        string(REGEX REPLACE "[ ]+" ";" ${ros_library_dirs_var}
          ${ros_library_dirs})
        link_directories(${${ros_library_dirs_var}})
      else(ros_library_dirs)
        remake_unset(${ros_library_dirs_var})
      endif(ros_library_dirs)
    endif(ros_result)

    remake_find_result("ROS ${ros_package}" ${${ros_path_var}}
      ${ros_optional})
  else(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
    remake_ros_find_stack(${ros_name} ${ros_optional})
  endif(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
endmacro(remake_ros_find_package)

### \brief Define the value of a ROS stack variable.
#   This macro is a helper macro that defines a variable for the specified
#   ROS stack.
#   \required[value] stack The name of the ROS stack for which the
#     variable shall be defined.
#   \required[value] variable The name of the stack variable to be
#     defined.
#   \optional[list] value The values to be set for the stack variable.
#   \optional[option] APPEND With this option being present, the arguments
#     will be appended to an already existing definition of the specified
#     stack variable.
macro(remake_ros_stack_set ros_stack ros_var)
  remake_arguments(PREFIX ros_ OPTION APPEND OPTION META ARGN args ${ARGN})

  remake_file(ros_stack_dir ${REMAKE_ROS_STACK_DIR}/${ros_stack} TOPLEVEL)
  remake_file_name(ros_file ${ros_var})

  if(IS_DIRECTORY ${ros_stack_dir})
    if(NOT ros_append)
      remake_file_create(${ros_stack_dir}/${ros_file} TOPLEVEL)
    endif(NOT ros_append)
    remake_file_write(${ros_stack_dir}/${ros_file} TOPLEVEL ${ros_args})
  else(IS_DIRECTORY ${ros_stack_dir})
    message(FATAL_ERROR "ROS stack ${ros_name} undefined!")
  endif(IS_DIRECTORY ${ros_stack_dir})
endmacro(remake_ros_stack_set)

### \brief Retrieve the value of a ROS stack variable.
#   This macro is a helper macro that retrieves the value of a stack variable
#   defined for the specified ROS stack.
#   \required[value] stack The name of the ROS stack to retrieve the
#     variable value for.
#   \required[value] variable The name of the stack variable to retrieve
#     the value for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried stack variable.
macro(remake_ros_stack_get ros_stack ros_var)
  remake_arguments(PREFIX ros_ VAR OUTPUT ${ARGN})

  remake_file(ros_stack_dir ${REMAKE_ROS_STACK_DIR}/${ros_stack} TOPLEVEL)
  remake_file_name(ros_file ${ros_var})

  if(IS_DIRECTORY ${ros_stack_dir})
    if(ros_output)
      remake_file_read(${ros_output} ${ros_stack_dir}/${ros_file} TOPLEVEL)
    else(ros_output)
      remake_file_read(${ros_var} ${ros_stack_dir}/${ros_file} TOPLEVEL)
    endif(ros_output)
  else(IS_DIRECTORY ${ros_stack_dir})
    message(FATAL_ERROR "ROS stack ${ros_name} undefined!")
  endif(IS_DIRECTORY ${ros_stack_dir})
endmacro(remake_ros_stack_get)

### \brief Define the value of a ROS package variable.
#   This macro is a helper macro that defines a variable for the specified
#   ROS package.
#   \required[value] package The name of the ROS package for which the
#     variable shall be defined.
#   \required[value] variable The name of the package variable to be
#     defined.
#   \optional[list] value The values to be set for the package variable.
#   \optional[option] APPEND With this option being present, the arguments
#     will be appended to an already existing definition of the specified
#     package variable.
macro(remake_ros_package_set ros_package ros_var)
  remake_arguments(PREFIX ros_ OPTION APPEND OPTION META ARGN args ${ARGN})

  remake_file(ros_pkg_dir ${REMAKE_ROS_PACKAGE_DIR}/${ros_package} TOPLEVEL)
  remake_file_name(ros_file ${ros_var})

  if(IS_DIRECTORY ${ros_pkg_dir})
    if(NOT ros_append)
      remake_file_create(${ros_pkg_dir}/${ros_file} TOPLEVEL)
    endif(NOT ros_append)
    remake_file_write(${ros_pkg_dir}/${ros_file} TOPLEVEL ${ros_args})
  else(IS_DIRECTORY ${ros_pkg_dir})
    message(FATAL_ERROR "ROS package ${ros_name} undefined!")
  endif(IS_DIRECTORY ${ros_pkg_dir})
endmacro(remake_ros_package_set)

### \brief Retrieve the value of a ROS package variable.
#   This macro is a helper macro that retrieves the value of a package variable
#   defined for the specified ROS package.
#   \required[value] package The name of the ROS package to retrieve the
#     variable value for.
#   \required[value] variable The name of the package variable to retrieve
#     the value for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried package variable.
macro(remake_ros_package_get ros_package ros_var)
  remake_arguments(PREFIX ros_ VAR OUTPUT ${ARGN})

  remake_file(ros_pkg_dir ${REMAKE_ROS_PACKAGE_DIR}/${ros_package} TOPLEVEL)
  remake_file_name(ros_file ${ros_var})

  if(IS_DIRECTORY ${ros_pkg_dir})
    if(ros_output)
      remake_file_read(${ros_output} ${ros_pkg_dir}/${ros_file} TOPLEVEL)
    else(ros_output)
      remake_file_read(${ros_var} ${ros_pkg_dir}/${ros_file} TOPLEVEL)
    endif(ros_output)
  else(IS_DIRECTORY ${ros_pkg_dir})
    message(FATAL_ERROR "ROS package ${ros_name} undefined!")
  endif(IS_DIRECTORY ${ros_pkg_dir})
endmacro(remake_ros_package_get)

### \brief Define a ROS stack or meta-package.
#   Depending on the indicated ROS distribution, this macro defines a ROS
#   stack or meta-package. Regarding future portability, its use should
#   however be avoided in favor of remake_ros_package().
macro(remake_ros_stack)
  remake_arguments(PREFIX ros_ VAR NAME VAR COMPONENT VAR DESCRIPTION
    VAR SOURCES LIST DEPENDS ${ARGN})
  remake_set(ros_component SELF DEFAULT ${REMAKE_COMPONENT})
  remake_set(ros_depends SELF DEFAULT ros ros_comm)

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_file(ros_stack_dir ${REMAKE_ROS_STACK_DIR}/${ros_name} TOPLEVEL)
    if(IS_DIRECTORY ${ros_stack_dir})
      message(FATAL_ERROR "ROS stack ${ros_name} multiply defined!")
    endif(IS_DIRECTORY ${ros_stack_dir})
    remake_file_mkdir(${ros_stack_dir})
    remake_file_name(ros_dest_dir ${ros_name})
    remake_set(ros_destination stacks/${ros_dest_dir})
    remake_ros_stack_set(${ros_name} destination ${ros_destination})

    string(REGEX REPLACE "[.]$" "" ros_summary ${REMAKE_PROJECT_SUMMARY})
    if(ros_description)
      remake_set(ros_summary "${ros_summary} (${ros_description})")
    endif(ros_description)

    remake_set(ros_manifest_head
      "<stack>"
      "  <description brief=\"${ros_summary}\"/>")
    string(REPLACE ", " ";" ros_authors "${REMAKE_PROJECT_AUTHORS}")
    foreach(ros_author ${ros_authors})
      remake_list_push(ros_manifest_head "  <author>${ros_author}</author>")
    endforeach(ros_author ${ros_authors})
    remake_set(ros_contact ${REMAKE_PROJECT_CONTACT})
    list(GET ros_authors 0 ros_maintainer)
    remake_list_push(ros_manifest_head
      "  <maintainer email=\"${ros_contact}\">${ros_maintainer}</maintainer>"
      "  <license>${REMAKE_PROJECT_LICENSE}</license>"
      "  <url>${REMAKE_PROJECT_HOME}</url>")
    remake_set(ros_manifest_tail "</stack>")

    remake_set(ros_manifest ${ros_stack_dir}/stack.xml)
    remake_ros_stack_set(${ros_name} manifest ${ros_manifest})
    remake_file_mkdir(${ros_manifest}.d)
    remake_file_write(${ros_manifest}.d/00-head
      LINES ${ros_manifest_head})
    remake_file_write(${ros_manifest}.d/99-tail
      LINES ${ros_manifest_tail})

    remake_set(ros_manifest_script
      "include(ReMake)"
      "remake_file_cat(${ros_manifest} ${ros_manifest}.d/*)")
    remake_file_write(${ros_manifest}.cmake LINES ${ros_manifest_script})
    remake_target_name(ros_manifest_target ${ros_name}
      ${REMAKE_ROS_STACK_MANIFEST_TARGET_SUFFIX})
    remake_component_add_command(
      OUTPUT ${ros_manifest} AS ${ros_manifest_target}
      COMMAND ${CMAKE_COMMAND} -P ${ros_manifest}.cmake
      COMMENT "Building ${ros_name} ROS stack manifest"
      COMPONENT ${ros_component})
    remake_component_install(
      FILES ${ros_manifest}
      DESTINATION ${ros_destination}
      COMPONENT ${ros_component})
    if(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
      remake_target(${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    endif(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    add_dependencies(${REMAKE_ROS_ALL_MANIFESTS_TARGET} ${ros_manifest_target})

    foreach(ros_dependency ${ros_depends})
      remake_ros_find_stack(${ros_dependency})
    endforeach(ros_dependency ${ros_depends})
    remake_ros_stack_add_dependencies(${ros_name} DEPENDS ${ros_depends})

    message(STATUS "ROS stack: ${ros_name}")

    if(ros_sources)
      remake_add_directories(${ros_sources} COMPONENT ${ros_component})
    endif(ros_sources)
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_package(NAME ${ros_name} DESCRIPTION "${ros_description}"
      META RUN_DEPENDS ${ros_depends})
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_stack)

### \brief Define a ROS package, meta-package, or stack.
#   Depending on the indicated ROS distribution and the provided arguments,
#   this macro defines a ROS package, meta-package, or stack.
#   Regarding future portability, its use is strongly encouraged over
#   remake_ros_stack().
macro(remake_ros_package)
  remake_arguments(PREFIX ros_ VAR NAME VAR COMPONENT VAR DESCRIPTION
    VAR SOURCES LIST DEPENDS LIST BUILD_DEPENDS LIST RUN_DEPENDS
    VAR REVERSE_DEPENDS OPTION META ${ARGN})
  remake_component_name(ros_default_component ${REMAKE_COMPONENT}
    ${ros_name})
  remake_set(ros_component SELF DEFAULT ${ros_default_component})
  remake_set(ros_depends SELF DEFAULT roscpp rospy)

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy AND NOT ros_meta)
    remake_file(ros_pkg_dir ${REMAKE_ROS_PACKAGE_DIR}/${ros_name} TOPLEVEL)
    if(IS_DIRECTORY ${ros_pkg_dir})
      message(FATAL_ERROR "ROS package ${ros_name} multiply defined!")
    endif(IS_DIRECTORY ${ros_pkg_dir})
    remake_file_mkdir(${ros_pkg_dir})
    remake_file_name(ros_dest_dir ${ros_name})
    if(ros_reverse_depends)
      if(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_stack_get(${ros_reverse_depends} destination
          OUTPUT ros_dest_root)
      else(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_package_get(${ros_reverse_depends} destination
          OUTPUT ros_dest_root)
      endif(${ROS_DISTRIBUTION} STRLESS groovy)
      remake_set(ros_destination ${ros_dest_root}/${ros_dest_dir})
    else(ros_reverse_depends)
      remake_set(ros_destination ${ros_dest_dir})
    endif(ros_reverse_depends)
    remake_ros_package_set(${ros_name} destination ${ros_destination})

    string(REGEX REPLACE "[.]$" "" ros_summary ${REMAKE_PROJECT_SUMMARY})
    if(ros_description)
      remake_set(ros_summary "${ros_summary} (${ros_description})")
    endif(ros_description)

    remake_set(ros_manifest_head "<package>")
    if(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
      remake_list_push(ros_manifest_head
        "  <name>${ros_name}</name>"
        "  <version>${REMAKE_PROJECT_VERSION}</version>")
    endif(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
    remake_list_push(ros_manifest_head
      "  <description brief=\"${ros_summary}\"/>")
    string(REPLACE ", " ";" ros_authors "${REMAKE_PROJECT_AUTHORS}")
    foreach(ros_author ${ros_authors})
      remake_list_push(ros_manifest_head "  <author>${ros_author}</author>")
    endforeach(ros_author ${ros_authors})
    remake_set(ros_contact ${REMAKE_PROJECT_CONTACT})
    list(GET ros_authors 0 ros_maintainer)
    remake_list_push(ros_manifest_head
      "  <maintainer email=\"${ros_contact}\">${ros_maintainer}</maintainer>"
      "  <license>${REMAKE_PROJECT_LICENSE}</license>"
      "  <url>${REMAKE_PROJECT_HOME}</url>")
    remake_unset(ros_manifest_tail)
    if(ros_meta)
      remake_list_push(ros_manifest_tail
        "  <export>"
        "    <metapackage/>"
        "  </export>")
    endif(ros_meta)
    remake_list_push(ros_manifest_tail "</package>")

    if(${ROS_DISTRIBUTION} STRLESS groovy)
      remake_set(ros_manifest ${ros_pkg_dir}/manifest.xml)
    else(${ROS_DISTRIBUTION} STRLESS groovy)
      remake_set(ros_manifest ${ros_pkg_dir}/package.xml)
    endif(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_package_set(${ros_name} manifest ${ros_manifest})
    remake_file_mkdir(${ros_manifest}.d)
    remake_file_write(${ros_manifest}.d/00-head
      LINES ${ros_manifest_head})
    remake_file_write(${ros_manifest}.d/99-tail
      LINES ${ros_manifest_tail})

    remake_set(ros_manifest_script
      "include(ReMake)"
      "remake_file_cat(${ros_manifest} ${ros_manifest}.d/*)")
    remake_file_write(${ros_manifest}.cmake LINES ${ros_manifest_script})
    remake_target_name(ros_manifest_target ${ros_name}
      ${REMAKE_ROS_PACKAGE_MANIFEST_TARGET_SUFFIX})
    remake_component_add_command(
      OUTPUT ${ros_manifest} AS ${ros_manifest_target}
      COMMAND ${CMAKE_COMMAND} -P ${ros_manifest}.cmake
      COMMENT "Building ${ros_name} ROS package manifest"
      COMPONENT ${ros_component})
    remake_component_install(
      FILES ${ros_manifest}
      DESTINATION ${ros_destination}
      COMPONENT ${ros_component})
    if(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
      remake_target(${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    endif(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    add_dependencies(${REMAKE_ROS_ALL_MANIFESTS_TARGET} ${ros_manifest_target})

    remake_ros_package_set(${ros_name} meta ${ros_meta})
    remake_set(ros_build_depends ${ros_depends} ${ros_build_depends})
    remake_set(ros_run_depends ${ros_depends} ${ros_run_depends})
    foreach(ros_dependency ${ros_build_depends})
      remake_ros_find_package(${ros_dependency})
    endforeach(ros_dependency ${ros_build_depends})
    remake_ros_package_add_dependencies(
      ${ros_name}
      BUILD_DEPENDS ${ros_build_depends}
      RUN_DEPENDS ${ros_run_depends})
    if(ros_reverse_depends)
      if(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_package_add_dependencies(${ros_reverse_depends}
          RUN_DEPENDS ${ros_name})
      endif(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
    endif(ros_reverse_depends)

    if(ros_meta)
      message(STATUS "ROS meta-package: ${ros_name}")
    else(ros_meta)
      message(STATUS "ROS package: ${ros_name}")
    endif(ros_meta)

    if(ros_sources)
      remake_add_directories(${ros_sources} COMPONENT ${ros_component})
    endif(ros_sources)
  else(${ROS_DISTRIBUTION} STRLESS groovy AND NOT ros_meta)
    remake_ros_stack(NAME ${ros_name} DESCRIPTION ${ros_description}
      DEPENDS ${ros_depends})
  endif(${ROS_DISTRIBUTION} STRLESS groovy AND NOT ros_meta)
endmacro(remake_ros_package)

### \brief Add dependencies to a ROS stack or meta-package.
#   Depending on the indicated ROS distribution, this macro adds dependencies
#   to an already defined ROS stack or meta-package. Regarding future
#   portability, its use should however be avoided in favor of
#   remake_ros_package_add_dependencies(). For ROS "groovy" and later
#   distributions, remake_ros_stack_add_dependencies() is silently diverted
#   to remake_ros_package_add_dependencies(). Otherwise, only stack-level
#   dependencies should be contained in the argument list.
#   \required[value] stack The name of an already defined ROS stack to which
#     the stack-level dependencies should be added.
#   \required[list] DEPENDS:stack A list of stack-level dependencies that
#     are inscribed into the ROS stack manifest.
macro(remake_ros_stack_add_dependencies ros_stack)
  remake_arguments(PREFIX ros_ LIST DEPENDS ${ARGN})

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_stack_get(${ros_stack} manifest OUTPUT ros_manifest)
    if(ros_depends)
      remake_unset(ros_manifest_depends)
      foreach(ros_dependency ${ros_depends})
        remake_list_push(ros_manifest_depends
          "  <depend stack=\"${ros_dependency}\"/>")
      endforeach(ros_dependency)
      remake_file_write(${ros_manifest}.d/50-depends LINES
        ${ros_manifest_depends})
    endif(ros_depends)
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_package_add_dependencies(${ros_stack}
      DEPENDS ${ros_depends})
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_stack_add_dependencies)

### \brief Add dependencies to a ROS package, meta-package, or stack.
#   Depending on the indicated ROS distribution, this macro adds dependencies
#   to an already defined ROS package, meta-package, or stack. Regarding
#   future portability, its use is strongly encouraged over
#   remake_ros_stack_add_dependencies(). For ROS "fuerte" and earlier
#   distributions, remake_ros_package_add_dependencies() is silently diverted
#   to remake_ros_stack_add_dependencies() if no package with the given name
#   is defined.
#   \required[value] pkg The name of an already defined ROS package or
#     meta-package to which the package dependencies should be added.
#   \optional[list] DEPENDS:pkg A list of both package build and runtime 
#     dependencies that are inscribed into the ROS package manifest.
#   \optional[list] BUILD_DEPENDS:pkg A list of package build dependencies
#     that are inscribed into the ROS package manifest. Note that a ROS
#     meta-package may only define runtime dependencies on other packages.
#   \optional[list] RUN_DEPENDS:pkg A list of package runtime dependencies
#     that are inscribed into the ROS package manifest.
macro(remake_ros_package_add_dependencies ros_package)
  remake_arguments(PREFIX ros_ LIST DEPENDS LIST BUILD_DEPENDS
    LIST RUN_DEPENDS ${ARGN})

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_list_push(ros_depends ${ros_build_depends} ${ros_run_depends})
    list(REMOVE_DUPLICATES ros_depends)
    remake_file(ros_pkg_dir ${REMAKE_ROS_PACKAGE_DIR}/${ros_package} TOPLEVEL)

    if(IS_DIRECTORY ${ros_pkg_dir})
      remake_ros_package_get(${ros_package} manifest OUTPUT ros_manifest)
      if(ros_depends)
        list(REMOVE_DUPLICATES ros_depends)
        remake_unset(ros_manifest_depends)
        foreach(ros_dependency ${ros_depends})
          remake_list_push(ros_manifest_depends
            "  <depend package=\"${ros_dependency}\"/>")
        endforeach(ros_dependency)
        remake_file_write(${ros_manifest}.d/50-depends LINES
          ${ros_manifest_depends})
      endif(ros_depends)
    else(IS_DIRECTORY ${ros_pkg_dir})
      remake_ros_stack_add_dependencies(${ros_package} DEPENDS ${ros_depends})
    endif(IS_DIRECTORY ${ros_pkg_dir})
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_set(ros_build_depends ${ros_depends} ${ros_build_depends})
    remake_set(ros_run_depends ${ros_depends} ${ros_run_depends})
    remake_ros_package_get(${ros_package} manifest OUTPUT ros_manifest)

    if(ros_build_depends)
      remake_ros_package_get(${ros_package} meta OUTPUT ros_meta)
      if(ros_meta)
        message(FATAL_ERROR
          "ROS meta-package ${ros_name} defines build dependencies!")
      endif(ros_meta)
      remake_unset(ros_manifest_build_depends)
      foreach(ros_dependency ${ros_manifest_build_depends})
        remake_list_push(ros_manifest_build_depends
          "  <build_depend>${ros_dependency}</build_depend>")
      endforeach(ros_dependency)
      remake_file_write(${ros_manifest}.d/50-build_depends LINES
        ${ros_manifest_build_depends})
    endif(ros_build_depends)
    if(ros_run_depends)
      remake_unset(ros_manifest_run_depends)
      foreach(ros_dependency ${ros_manifest_run_depends})
        remake_list_push(ros_manifest_run_depends
          "  <run_depend>${ros_dependency}</run_depend>")
      endforeach(ros_dependency)
      remake_file_write(${ros_manifest}.d/51-run_depends LINES
        ${ros_manifest_run_depends})
    endif(ros_run_depends)
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_package_add_dependencies)

remake_file_rmdir(${REMAKE_ROS_STACK_DIR} TOPLEVEL)
remake_file_rmdir(${REMAKE_ROS_PACKAGE_DIR} TOPLEVEL)
