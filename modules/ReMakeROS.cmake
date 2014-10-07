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

include(ReMakeProject)
include(ReMakeFind)
include(ReMakeFile)
include(ReMakeComponent)
include(ReMakePython)
include(ReMakePack)
include(ReMakeDistribute)
include(ReMakeDebian)
include(ReMakePkgConfig)

include(ReMakePrivate)

include(FindPkgConfig)

### \brief ReMake ROS build macros
#   The ReMake ROS build macros provide access to the ROS build system
#   configuration without requirement for the ROS CMake API. Note that
#   all ROS environment variables should be initialized by sourcing the
#   corresponding ROS setup script prior to calling CMake.

if(NOT DEFINED REMAKE_ROS_CMAKE)
  remake_set(REMAKE_ROS_CMAKE ON)

  remake_set(REMAKE_ROS_DIR ReMakeROS)
  remake_set(REMAKE_ROS_STACK_DIR ${REMAKE_ROS_DIR}/stacks)
  remake_set(REMAKE_ROS_PACKAGE_DIR ${REMAKE_ROS_DIR}/packages)
  remake_set(REMAKE_ROS_FILENAME_PREFIX ros)
  remake_set(REMAKE_ROS_ALL_MANIFESTS_TARGET ros_manifests)
  remake_set(REMAKE_ROS_STACK_MANIFEST_TARGET_SUFFIX ros_stack_manifest)
  remake_set(REMAKE_ROS_PACKAGE_MANIFEST_TARGET_SUFFIX ros_package_manifest)
  remake_set(REMAKE_ROS_PACKAGE_MESSAGES_TARGET_SUFFIX ros_messages)
  remake_set(REMAKE_ROS_PACKAGE_SERVICES_TARGET_SUFFIX ros_services)

  remake_file_rmdir(${REMAKE_ROS_STACK_DIR} TOPLEVEL)
  remake_file_rmdir(${REMAKE_ROS_PACKAGE_DIR} TOPLEVEL)

  remake_project_unset(ROS_STACKS CACHE)
  remake_project_unset(ROS_PACKAGES CACHE)
endif(NOT DEFINED REMAKE_ROS_CMAKE)

### \brief Configure the ROS build system.
#   This macro discovers ROS from its environment variables, initializes
#   ${ROS_PATH}, ${ROS_DISTRIBUTION}, and ${ROS_PACKAGE_PATH}. Note that the
#   macro automatically gets invoked by the macros defined in this module.
#   It needs not be called directly from a CMakeLists.txt file. When
#   cross-compiling, two installations of the targeted ROS distribution
#   along with the required packages must exists, one under the host
#   and one under the target system's root. The ReMakeROS macros will
#   then take care of providing correct path hints for finding the ROS
#   binaries and packages.
macro(remake_ros)
  if(NOT ROS_FOUND)
    remake_set(ros_paths PATHS)
    if(DEFINED ENV{ROS_ROOT})
      remake_list_push(ros_paths "$ENV{ROS_ROOT}/../..")
    elseif(ROS_DISTRIBUTION)
      remake_list_push(ros_paths "/opt/ros/${ROS_DISTRIBUTION}")
    endif(DEFINED ENV{ROS_ROOT})

    remake_find_executable(env.sh PACKAGE ROS ${ros_paths})
    
    if(ROS_FOUND)
      get_filename_component(ros_path ${ROS_EXECUTABLE} PATH)
      remake_set(ROS_PATH ${ros_path} CACHE STRING
        "Path to the ROS distribution." FORCE)

      if(DEFINED ENV{ROS_DISTRO})
        remake_set(ros_distribution $ENV{ROS_DISTRO})
      else(DEFINED ENV{ROS_DISTRO})
        remake_ros_command(
          echo $ROS_DISTRO
          OUTPUT ros_command)
        execute_process(
          COMMAND ${ros_command}
          OUTPUT_VARIABLE ros_distribution
          ERROR_VARIABLE ros_error
          ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
      endif(DEFINED ENV{ROS_DISTRO})
      remake_set(ROS_DISTRIBUTION ${ros_distribution} CACHE STRING
        "Name of the ROS distribution." FORCE)
      if(NOT ROS_DISTRIBUTION)
        remake_unset(ROS_FOUND CACHE)
        message(FATAL_ERROR "ROS distribution is undefined.")
      endif(NOT ROS_DISTRIBUTION)

      if(DEFINED ENV{ROS_PACKAGE_PATH})
        remake_set(ros_package_path $ENV{ROS_PACKAGE_PATH})
      else(DEFINED ENV{ROS_PACKAGE_PATH})
        remake_ros_command(
          echo $ROS_PACKAGE_PATH
          OUTPUT ros_command)
        execute_process(
          COMMAND ${ros_command}
          OUTPUT_VARIABLE ros_package_path
          ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(CMAKE_CROSSCOMPILING AND CMAKE_FIND_ROOT_PATH)
          string(REGEX REPLACE ":" ":${CMAKE_FIND_ROOT_PATH}"
          ros_package_path ${CMAKE_FIND_ROOT_PATH}${ros_package_path})
        endif(CMAKE_CROSSCOMPILING AND CMAKE_FIND_ROOT_PATH)
      endif(DEFINED ENV{ROS_PACKAGE_PATH})
      if(ros_package_path)
        string(REGEX REPLACE ":" ";" ros_package_path ${ros_package_path})
      endif(ros_package_path)
      remake_set(ROS_PACKAGE_PATH ${ros_package_path} CACHE STRING
        "Paths to the ROS packages." FORCE)

      remake_set(ros_path_valid OFF)
      foreach(ros_path ${ROS_PACKAGE_PATH})
        if(IS_DIRECTORY ${ros_path})
          remake_set(ros_path_valid ON)
        endif(IS_DIRECTORY ${ros_path})
      endforeach(ros_path)

      if(NOT ros_path_valid)
        message(FATAL_ERROR "ROS package path is invalid.")
      endif(NOT ros_path_valid)
    endif(ROS_FOUND)
  endif(NOT ROS_FOUND)

  if(ROS_FOUND)
    if(${ROS_DISTRIBUTION} STRLESS groovy)
      remake_file_mkdir(${REMAKE_ROS_STACK_DIR} TOPLEVEL)
      remake_set(REMAKE_ROS_STACK_MANIFEST "stack.xml")
      remake_set(REMAKE_ROS_PACKAGE_MANIFEST "manifest.xml")
    else(${ROS_DISTRIBUTION} STRLESS groovy)
      remake_set(REMAKE_ROS_PACKAGE_MANIFEST "package.xml")
    endif(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_file_mkdir(${REMAKE_ROS_PACKAGE_DIR} TOPLEVEL)
  endif(ROS_FOUND)
endmacro(remake_ros)

### \brief Construct a ROS command.
#   This macro constructs a ROS command to be executed within the ROS
#   environment. It embeds the provided verbatim command into a shell
#   command and passes this shell command as command line arguments to the
#   ROS executable env.sh. The resulting command may then be provided to
#   CMake's execute_process() or add_custom_command() macros. See the CMake
#   documentation for details.
#   \required[value] cmd The ROS command to be executed.
#   \optional[list] arg An optional list of arguments which shall be passed
#     to the ROS command.
#   \required[value] OUTPUT:variable The name of an output variable that will
#     be assigned the constructed ROS command.
macro(remake_ros_command)
  remake_arguments(PREFIX ros_command_ VAR OUTPUT ARGN args ${ARGN})

  string(REGEX REPLACE ";" " " ros_shell_command "${ros_command_args}")
  remake_set(${ros_command_output}
    ${ROS_EXECUTABLE} sh -c "${ros_shell_command}"  VERBATIM)
endmacro(remake_ros_command)

### \brief Find a ROS stack.
#   Depending on the indicated ROS distribution, this macro discovers a
#   ROS stack or meta-package in the distribution under ${ROS_PATH} or the
#   project. Regarding future portability, its use should however be avoided
#   in favor of remake_ros_find_package(). For ROS "groovy" and later
#   distributions, remake_ros_find_stack() is silently diverted to
#   remake_ros_find_package(). The macro calls rosstack to search all stacks
#   installed on the build system. If the corresponding ROS stack was found,
#   it sets the variable name conversion of ROS_${NAME}_FOUND to TRUE and
#   initializes ROS_${NAME}_PATH accordingly. All packages contained in the
#   ROS stack are further searched by remake_ros_find_package(), and the
#   corresponding package-specific result variables are concatenated to
#   initialize ROS_${NAME}_INCLUDE_DIRS, ROS_${NAME}_LIBRARIES, and
#   ROS_${STACK}_LIBRARY_DIRS.
#   \required[value] name The name of the ROS stack to be discovered.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_ros_find_stack ros_name)
  remake_arguments(PREFIX ros_ OPTION OPTIONAL ${ARGN})
  remake_set(ros_optional ${OPTIONAL})

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_var_name(ros_stack_result_var ROS ${ros_name} FOUND)
    
    if(NOT ${ros_stack_result_var})
      remake_find_executable(rosstack PATHS "${ROS_PATH}/bin")

      remake_var_name(ros_stack_path_var ROS ${ros_name} PATH)
      remake_var_name(ros_stack_include_dirs_var ROS ${ros_name} INCLUDE_DIRS)
      remake_var_name(ros_stack_libraries_var ROS ${ros_name} LIBRARIES)
      remake_var_name(ros_stack_library_dirs_var ROS ${ros_name} LIBRARY_DIRS)
      remake_unset(ros_stack_include_dirs ros_stack_libraries
        ros_stack_library_dirs)

      string(REGEX REPLACE ";" ":" ros_pkg_path "${ROS_PACKAGE_PATH}")
      remake_ros_command(
        ROS_PACKAGE_PATH=${ros_pkg_path} &&
        ${ROSSTACK_EXECUTABLE} find ${ros_name}
        OUTPUT ros_command)
      execute_process(
        COMMAND ${ros_command}
        RESULT_VARIABLE ros_result
        OUTPUT_VARIABLE ${ros_stack_path_var}
        ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

      if(ros_result)
        remake_set(${ros_stack_path_var} ${ros_stack_path_var}-NOTFOUND)
      else(ros_result)
        remake_ros_command(
          ROS_PACKAGE_PATH=${ros_pkg_path} &&
          ${ROSSTACK_EXECUTABLE} contents ${ros_name}
          OUTPUT ros_command)
        execute_process(
          COMMAND ${ros_command}
          OUTPUT_VARIABLE ros_packages
          ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(ros_packages)
          string(REGEX REPLACE "[ \n]+" ";" ros_packages ${ros_packages})
        endif(ros_packages)

        foreach(ros_package ${ros_packages})
          remake_var_name(ros_pkg_include_dirs_var ROS ${ros_package}
            INCLUDE_DIRS)
          remake_var_name(ros_pkg_libraries_var ROS ${ros_package} LIBRARIES)
          remake_var_name(ros_pkg_library_dirs_var ROS ${ros_package}
            LIBRARY_DIRS)

          remake_ros_find_package(${ros_package} ${ros_optional})

          remake_list_push(ros_stack_include_dirs
            ${${ros_pkg_include_dirs_var}})
          remake_list_push(ros_stack_libraries ${${ros_pkg_libraries_var}})
          remake_list_push(ros_stack_library_dirs
            ${${ros_pkg_library_dirs_var}})
        endforeach(ros_package ${ros_packages})

        remake_set(${ros_stack_path_var} ${${ros_stack_path_var}}
          CACHE PATH "Path to ROS stack ${ros_name}.")
        remake_set(${ros_stack_include_dirs_var} ${ros_stack_include_dirs}
          CACHE INTERNAL "Include directories of ROS stack ${ros_name}.")
        remake_set(${ros_stack_libraries_var} ${ros_stack_libraries}
          CACHE INTERNAL "Libraries of ROS stack ${ros_name}.")
        remake_set(${ros_stack_library_dirs_var} ${ros_stack_library_dirs}
          CACHE INTERNAL "Library directories of ROS stack ${ros_name}.")
      endif(ros_result)

      remake_find_result("ROS ${ros_name}" ${${ros_stack_path_var}}
        NAME ${ros_name} TYPE "ROS stack" ${ros_optional})
    endif(NOT ${ros_stack_result_var})
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_find_package(${ros_name} ${ros_optional})
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_find_stack)

### \brief Define a ROS stack or meta-package.
#   Depending on the indicated ROS distribution, this macro defines a ROS
#   stack or meta-package. Regarding future portability, its use should
#   however be avoided in favor of remake_ros_package(). For ROS "groovy"
#   and later distributions, remake_ros_stack() is silently diverted to
#   remake_ros_package(). Otherwise, the macro initializes the required
#   stack variables and defines a rule for generating the stack manifest.
#   \required[value] name The name of the ROS stack to be defined. Note
#     that, in order for the stack name to be valid, it may not contain
#     certain characters. See the ROS documentation for details.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that will be assigned the stack build and install rules.
#     If no component name is provided, it will default to component name
#     conversion of the provided stack name. See ReMakeComponent for details.
#   \optional[value] DESCRIPTION:string An optional description of the ROS
#     stack which is appended to the project summary when inscribed into the
#     stack manifest, defaulting to "${NAME} stack".
#   \optional[list] SOURCES:dir The name of a directory containing the
#     sources of the ROS stack and defaulting to the stack name. The
#     directory will be recursed by remake_add_directories() with the
#     respective component set.
#   \optional[list] DEPENDS:stack A list naming the dependencies of the
#     defined ROS stack, defaulting to ros and ros_comm. This list will be
#     passed to remake_ros_stack_add_dependencies(). Note that, for
#     ROS "fuerte" and earlier distributions, stacks may only specify
#     dependencies on other stacks.
macro(remake_ros_stack ros_name)
  remake_arguments(PREFIX ros_ VAR COMPONENT VAR DESCRIPTION VAR SOURCES
    LIST DEPENDS ${ARGN})
  string(REGEX REPLACE "_" "-" ros_default_component ${ros_name})
  remake_set(ros_component SELF DEFAULT ${ros_default_component})
  remake_set(ros_description SELF DEFAULT "${ros_name} stack")
  remake_set(ros_sources SELF DEFAULT ${ros_name})
  remake_set(ros_depends SELF DEFAULT ros ros_comm)

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_project_get(ROS_STACKS OUTPUT ros_stacks)
    list(FIND ros_stacks ${ros_name} ros_index)
    if(NOT ros_index LESS 0)
      message(FATAL_ERROR "ROS stack ${ros_name} multiply defined!")
    endif(NOT ros_index LESS 0)
    remake_project_set(ROS_STACKS ${ros_stacks} ${ros_name}
      CACHE INTERNAL "ROS stacks defined by the project.")

    remake_file(ros_stack_dir ${REMAKE_ROS_STACK_DIR}/${ros_name} TOPLEVEL)
    remake_file_mkdir(${ros_stack_dir})
    remake_file_name(ros_filename
      ${REMAKE_ROS_FILENAME_PREFIX}-${ROS_DISTRIBUTION}-${ros_name})
    remake_file_name(ros_dest_dir ${ros_name})
    remake_set(ros_dest_root share/${ros_dest_dir})

    string(REGEX REPLACE "[.]$" "" ros_summary ${REMAKE_PROJECT_SUMMARY})
    remake_set(ros_summary "${ros_summary} (${ros_description})")

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

    remake_set(ros_manifest ${ros_stack_dir}/${REMAKE_ROS_STACK_MANIFEST})
    remake_ros_stack_set(${ros_name} MANIFEST ${ros_manifest}
      CACHE INTERNAL "Manifest file of ROS stack ${ros_name}.")
    remake_file_mkdir(${ros_manifest}.d)
    remake_file_write(${ros_manifest}.d/00-head
      LINES ${ros_manifest_head})
    remake_file_write(${ros_manifest}.d/99-tail
      LINES ${ros_manifest_tail})

    remake_set(ros_manifest_script
      "include(ReMakeFile)"
      "remake_file_cat(${ros_manifest} ${ros_manifest}.d/*)")
    remake_file_write(${ros_manifest}.cmake LINES ${ros_manifest_script})
    remake_target_name(ros_manifest_target ${ros_name}
      ${REMAKE_ROS_STACK_MANIFEST_TARGET_SUFFIX})
    remake_component(${ros_component}
      FILENAME ${ros_filename}
      PREFIX OFF
      INSTALL ${ROS_PATH}
      FILE_DESTINATION ${ros_dest_root}
      CONFIGURATION_DESTINATION ${ros_dest_root}/etc)
    remake_component_name(ros_dev_component ${ros_component}
      ${REMAKE_COMPONENT_DEVEL_SUFFIX})
    remake_component(${ros_dev_component}
      FILENAME ${ros_filename}-${REMAKE_COMPONENT_DEVEL_SUFFIX}
      PREFIX OFF
      INSTALL ${ROS_PATH}
      HEADER_DESTINATION include/${ros_name})
    remake_component_name(ros_python_component ${ros_component}
      ${REMAKE_PYTHON_COMPONENT_SUFFIX})
    remake_component(${ros_python_component}
      FILENAME ${ros_filename}-${REMAKE_PYTHON_COMPONENT_SUFFIX}
      PREFIX OFF
      INSTALL ${ROS_PATH})
    remake_component_add_command(
      OUTPUT ${ros_manifest} AS ${ros_manifest_target}
      COMMAND ${CMAKE_COMMAND} -P ${ros_manifest}.cmake
      COMMENT "Generating ${ros_name} stack manifest"
      COMPONENT ${ros_component})
    remake_component_install(
      FILES ${ros_manifest}
      DESTINATION ${ros_dest_root}
      COMPONENT ${ros_component})
    if(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
      remake_target(${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    endif(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    add_dependencies(${REMAKE_ROS_ALL_MANIFESTS_TARGET} ${ros_manifest_target})

    remake_ros_stack_set(${ros_name} COMPONENT ${ros_component}
      CACHE INTERNAL "Component of ${ros_name} ROS stack.")
    remake_ros_stack_set(${ros_name} DESCRIPTION ${ros_description}
      CACHE INTERNAL "Description of ${ros_name} ROS stack.")
    remake_ros_stack_add_dependencies(${ros_name} DEPENDS ${ros_depends})

    message(STATUS "ROS stack: ${ros_name}")

    remake_add_directories(${ros_sources} COMPONENT ${ros_component})
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_ros_package(
      ${ros_name} META
      COMPONENT ${ros_component}
      DESCRIPTION "${ros_description}"
      SOURCES ${ros_sources}
      RUN_DEPENDS ${ros_depends})
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_stack)

### \brief Define the value of a ROS stack variable.
#   This macro defines a ROS stack variable matching the ReMake naming
#   conventions. The variable name is automatically prefixed with an
#   upper-case conversion of the stack name. Thus, variables may
#   appear in the cache as project variables named after
#   ${STACK_NAME}_ROS_STACK_${VAR_NAME}. Additional arguments are
#   passed on to remake_project_set(). Note that the ROS stack needs
#   to be defined.
#   \required[value] name The name of the ROS stack for which the
#     variable shall be defined.
#   \required[value] variable The name of the stack variable to be
#     defined.
#   \optional[list] arg The arguments to be passed on to remake_project_set().
#      See ReMakeProject for details.
macro(remake_ros_stack_set ros_name ros_var)
  remake_project_get(ROS_STACKS OUTPUT ros_stacks)
  list(FIND ros_stacks ${ros_name} ros_index)

  if(ros_index GREATER -1)
    remake_var_name(ros_stack_var ${ros_name} ROS_STACK ${ros_var})
    remake_project_set(${ros_stack_var} ${ARGN})
  else(ros_index GREATER -1)
    message(FATAL_ERROR "ROS stack ${ros_name} undefined!")
  endif(ros_index GREATER -1)
endmacro(remake_ros_stack_set)

### \brief Retrieve the value of a ROS stack variable.
#   This macro retrieves a ROS stack variable matching the ReMake
#   naming conventions. Specifically, project variables named after
#   ${STACK_NAME}_ROS_STACK_${VAR_NAME} can be found by passing ${VAR_NAME}
#   to this macro. Note that the ROS stack needs to be defined.
#   \required[value] name The name of the ROS stack to retrieve the
#     variable value for.
#   \required[value] variable The name of the stack variable to retrieve
#     the value for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried stack variable.
macro(remake_ros_stack_get ros_name ros_var)
  remake_arguments(PREFIX ros_ VAR OUTPUT ${ARGN})

  remake_project_get(ROS_STACKS OUTPUT ros_stacks)
  list(FIND ros_stacks ${ros_name} ros_index)

  if(ros_index GREATER -1)
    remake_var_name(ros_stack_var ${ros_name} ROS_STACK ${ros_var})
    remake_set(ros_output SELF DEFAULT ${ros_var})

    remake_project_get(${ros_stack_var} OUTPUT ${ros_output})
  else(ros_index GREATER -1)
    message(FATAL_ERROR "ROS stack ${ros_name} undefined!")
  endif(ros_index GREATER -1)
endmacro(remake_ros_stack_get)

### \brief Add dependencies to a ROS stack or meta-package.
#   Depending on the indicated ROS distribution, this macro adds dependencies
#   to an already defined ROS stack or meta-package. Regarding future
#   portability, its use should however be avoided in favor of
#   remake_ros_package_add_dependencies(). For ROS "groovy" and later
#   distributions, remake_ros_stack_add_dependencies() is silently diverted
#   to remake_ros_package_add_dependencies(). Otherwise, only stack-level
#   dependencies should be contained in the argument list. Essentially,
#   the macro calls remake_ros_find_stack() to discover the required stack.
#   All directories in ROS_${NAME}_INCLUDE_DIRS are then added to the include
#   path by calling remake_include(). In addition, the directories in which
#   the linker will look for the stack libraries is specified by passing
#   ROS_${NAME}_LIBRARY_DIRS to CMake's link_directories().
#   \required[value] name The name of an already defined ROS stack to which
#     the stack-level dependencies should be added.
#   \required[list] DEPENDS:stack A list of stack-level dependencies that
#     are inscribed into the ROS stack manifest.
#   \required[list] DEPLOYS:pkg A list of ROS packages that are to be deployed
#     by the ROS stack. Note that these packages will not be enlisted in the
#     stack manifest.
macro(remake_ros_stack_add_dependencies ros_name)
  remake_arguments(PREFIX ros_ LIST DEPENDS LIST DEPLOYS ${ARGN})

  remake_ros()

  if(${ROS_DISTRIBUTION} STRLESS groovy)
    if(ros_depends)
      remake_project_get(ROS_STACKS OUTPUT ros_stacks)
      remake_ros_stack_get(${ros_name} MANIFEST OUTPUT ros_manifest)
      remake_ros_stack_get(${ros_name} INTERNAL_RUN_DEPENDS
        OUTPUT ros_run_deps_int)
      remake_ros_stack_get(${ros_name} EXTERNAL_RUN_DEPENDS
        OUTPUT ros_run_deps_ext)

      remake_unset(ros_manifest_depends)
      foreach(ros_dependency ${ros_depends})
        list(FIND ros_stacks ${ros_dependency} ros_index)

        if(ros_index LESS 0)
          remake_ros_find_stack(${ros_dependency})
          remake_var_name(ros_include_dirs_var ROS ${ros_dependency}
            INCLUDE_DIRS)
          remake_var_name(ros_library_dirs_var ROS ${ros_dependency}
            LIBRARY_DIRS)

          if(${ros_include_dirs_var})
            remake_include(${ros_include_dirs_var})
          endif(${ros_include_dirs_var})
          if(${ros_library_dirs_var})
            link_directories(${ros_library_dirs_var})
          endif(${ros_library_dirs_var})
          remake_list_push(ros_run_deps_ext ${ros_dependency})
        else(ros_index LESS 0)
          remake_ros_stack_get(${ros_dependency} INCLUDE_DIRS
            OUTPUT ros_include_dirs)
          remake_include(${ros_include_dirs})
          remake_list_push(ros_run_deps_int ${ros_dependency})
        endif(ros_index LESS 0)

        remake_list_push(ros_manifest_depends
          "  <depend stack=\"${ros_dependency}\"/>")
      endforeach(ros_dependency)

      remake_file_write(${ros_manifest}.d/50-depends LINES
        ${ros_manifest_depends})
      remake_list_remove_duplicates(ros_run_deps_int)
      remake_ros_stack_set(${ros_name} INTERNAL_RUN_DEPENDS
        ${ros_run_deps_int} CACHE INTERNAL
        "Internal runtime dependencies of ROS stack ${ros_name}.")
      remake_list_remove_duplicates(ros_run_deps_ext)
      remake_ros_stack_set(${ros_name} EXTERNAL_RUN_DEPENDS
        ${ros_run_deps_ext} CACHE INTERNAL
        "External runtime dependencies of ROS stack ${ros_name}.")
    endif(ros_depends)

    if(ros_deploys)
      remake_ros_stack_get(${ros_name} DEPLOYS OUTPUT ros_stack_deploys)
      remake_list_push(ros_stack_deploys ${ros_deploys})
      remake_list_remove_duplicates(ros_stack_deploys)
      remake_ros_stack_set(${ros_name} DEPLOYS ${ros_stack_deploys}
        CACHE INTERNAL "Packages deployed by ROS stack ${ros_name}.")
    endif(ros_deploys)
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    if(ros_deploys)
      remake_ros_package_add_dependencies(${ros_name} ${DEPENDS}
        RUN_DEPENDS ${ros_deploys})
    else(ros_deploys)
      remake_ros_package_add_dependencies(${ros_name} ${DEPENDS})
    endif(ros_deploys)
  endif(${ROS_DISTRIBUTION} STRLESS groovy)
endmacro(remake_ros_stack_add_dependencies)

### \brief Find a ROS package.
#   Depending on the indicated ROS distribution and the provided arguments,
#   this macro discovers a ROS package, meta-package, or stack in the
#   distribution under ${ROS_PATH}. Regarding future portability, its use is
#   strongly encouraged over remake_ros_find_stack(). For ROS "fuerte" and
#   earlier distributions, remake_ros_find_package() is silently diverted to
#   remake_ros_find_stack() if the META option is present. The macro calls
#   rospack to search all packages installed on the build system. If the
#   corresponding ROS package was found, the variable name conversion of
#   ROS_${NAME}_FOUND is set to TRUE, and ROS_${NAME}_PATH,
#   ROS_${NAME}_INCLUDE_DIRS, ROS_${NAME}_LIBRARIES, ROS_${NAME}_LIBRARY_DIRS,
#   and ROS_${NAME}_LDFLAGS_OTHER are initialized accordingly.
#   \required[value] name The name of the ROS package to be discovered.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
#   \optional[option] META If provided, the macro will be aware that the
#     package is a meta-package. For ROS "groovy" and later distributions,
#     the option is meaningless, whereas it ensures portability for ROS
#     "fuerte" and earlier distributions.
macro(remake_ros_find_package ros_name)
  remake_arguments(PREFIX ros_ OPTION OPTIONAL OPTION META ${ARGN})
  remake_set(ros_optional ${OPTIONAL})

  remake_ros()

  if(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
    remake_var_name(ros_pkg_result_var ROS ${ros_name} FOUND)
  
    if(NOT ${ros_pkg_result_var})
      remake_find_executable(rospack PATHS "${ROS_PATH}/bin")

      remake_var_name(ros_pkg_path_var ROS ${ros_name} PATH)
      string(REGEX REPLACE ";" ":" ros_pkg_path "${ROS_PACKAGE_PATH}")
      remake_set(ros_pkg_env ROS_PACKAGE_PATH=${ros_pkg_path})
      string(REGEX REPLACE ";" " " ros_pkg_env "${ros_pkg_env}")
      
      remake_ros_command(
        ${ros_pkg_env}
        ${ROSPACK_EXECUTABLE} find ${ros_name}
        OUTPUT ros_command)
      execute_process(
        COMMAND ${ros_command}
        RESULT_VARIABLE ros_result
        OUTPUT_VARIABLE ${ros_pkg_path_var}
        ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

      if(ros_result)
        remake_set(${ros_pkg_path_var} ${ros_pkg_path_var}-NOTFOUND)
      else(ros_result)
        remake_set(${ros_pkg_path_var} ${${ros_pkg_path_var}}
          CACHE PATH "Path to ROS package ${ros_name}.")
          
        if(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR)
          remake_set(ENV{PKG_CONFIG_SYSROOT_DIR}
            ${REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR})
        endif(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR)
        if(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_DIR)
          remake_set(ros_pkg_config_dirs ${REMAKE_FIND_PKG_CONFIG_DIR})
          remake_list_push(ros_pkg_config_dirs
            ${CMAKE_FIND_ROOT_PATH}${ROS_PATH}/lib/pkgconfig)
        else(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_DIR)
          remake_set(ros_pkg_config_dirs ${ROS_PATH}/lib/pkgconfig)
        endif(CMAKE_CROSSCOMPILING AND REMAKE_FIND_PKG_CONFIG_DIR)
        string(REGEX REPLACE ";" ":" PKG_CONFIG_PATH
          "${ros_pkg_config_dirs}")
        string(REGEX REPLACE ";" ":" PKG_CONFIG_LIBDIR
          "${ros_pkg_config_dirs}")

        remake_set(ENV{PKG_CONFIG_PATH} ${PKG_CONFIG_PATH})
        remake_set(ENV{PKG_CONFIG_LIBDIR} ${PKG_CONFIG_LIBDIR})
        remake_var_name(ros_pkg_prefix ROS ${ros_name})
        pkg_check_modules(${ros_pkg_prefix} ${ros_name} QUIET)
        remake_unset(ENV{PKG_CONFIG_PATH} ENV{PKG_CONFIG_LIBDIR})
        
        if(NOT ${ros_pkg_prefix}_FOUND)        
          remake_var_name(ros_pkg_include_dirs_var ROS ${ros_name}
            INCLUDE_DIRS)
          remake_var_name(ros_pkg_libraries_var ROS ${ros_name} LIBRARIES)
          remake_var_name(ros_pkg_library_dirs_var ROS ${ros_name}
            LIBRARY_DIRS)
          remake_var_name(ros_pkg_link_flags_var ROS ${ros_name} LDFLAGS_OTHER)
          
          remake_ros_command(
            ${ros_pkg_env}
            ${ROSPACK_EXECUTABLE} cflags-only-I ${ros_name}
            OUTPUT ros_command)
          execute_process(
            COMMAND ${ros_command}
            OUTPUT_VARIABLE ros_pkg_include_dirs
            ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
          remake_ros_command(
            ${ros_pkg_env}
            ${ROSPACK_EXECUTABLE} libs-only-l ${ros_name}
            OUTPUT ros_command)
          execute_process(
            COMMAND ${ros_command}
            OUTPUT_VARIABLE ros_pkg_libraries
            ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
          remake_ros_command(
            ${ros_pkg_env}
            ${ROSPACK_EXECUTABLE} libs-only-L ${ros_name}
            OUTPUT ros_command)
          execute_process(
            COMMAND ${ros_command}
            OUTPUT_VARIABLE ros_pkg_library_dirs
            ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
          remake_ros_command(
            ${ros_pkg_env}
            ${ROSPACK_EXECUTABLE} libs-only-other ${ros_name}
            OUTPUT ros_command)
          execute_process(
            COMMAND ${ros_command}
            OUTPUT_VARIABLE ros_pkg_link_flags
            ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

          if(ros_pkg_include_dirs)
            string(REGEX REPLACE "[ ]+" ";" ros_pkg_include_dirs
              ${ros_pkg_include_dirs})
            remake_include(${${ros_include_dirs_var}})
          endif(ros_pkg_include_dirs)
          if(ros_pkg_libraries)
            string(REGEX REPLACE "[ ]+" ";" ros_pkg_libraries
              ${ros_pkg_libraries})
          endif(ros_pkg_libraries)
          if(ros_pkg_library_dirs)
            string(REGEX REPLACE "[ ]+" ";" ros_pkg_library_dirs
              ${ros_pkg_library_dirs})
            link_directories(${ros_pkg_library_dirs})
          endif(ros_pkg_library_dirs)
          if(ros_pkg_link_flags)
            string(REGEX REPLACE "[ ]+" ";" ros_pkg_link_flags
              ${ros_pkg_link_flags})
          endif(ros_pkg_link_flags)

          remake_set(${ros_pkg_include_dirs_var} ${ros_pkg_include_dirs}
            CACHE INTERNAL "Include directories of ROS package ${ros_name}.")
          remake_set(${ros_pkg_libraries_var} ${ros_pkg_libraries}
            CACHE INTERNAL "Libraries of ROS package ${ros_name}.")
          remake_set(${ros_pkg_library_dirs_var} ${ros_pkg_library_dirs}
            CACHE INTERNAL "Library directories of ROS package ${ros_name}.")
          remake_set(${ros_pkg_link_flags_var} ${ros_pkg_link_flags}
            CACHE INTERNAL "Linker flags of ROS package ${ros_name}.")
        endif(NOT ${ros_pkg_prefix}_FOUND)        
      endif(ros_result)

      remake_find_result("ROS ${ros_name}" ${${ros_pkg_path_var}}
        NAME ${ros_name} TYPE "ROS package" ${ros_optional})
    endif(NOT ${ros_pkg_result_var})
  else(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
    remake_ros_find_stack(${ros_name} ${ros_optional})
  endif(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
endmacro(remake_ros_find_package)

### \brief Define a ROS package, meta-package, or stack.
#   Depending on the indicated ROS distribution and the provided arguments,
#   this macro defines a ROS package, meta-package, or stack.
#   Regarding future portability, its use is strongly encouraged over
#   remake_ros_stack(). For ROS "fuerte" and earlier distributions,
#   remake_ros_package() is silently diverted to remake_ros_stack() if the
#   META option is present. Otherwise, the macro initializes the required
#   package variables and defines a rule for generating the package manifest.
#   \required[value] name The name of the ROS package to be defined. Note
#     that, in order for the package name to be valid, it may not contain
#     certain characters. See the ROS documentation for details.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that will be assigned the package build and install rules.
#     If no component name is provided, it will default to component name
#     conversion of the provided package name. See ReMakeComponent for details.
#   \optional[value] DESCRIPTION:string An optional description of the ROS
#     package which is appended to the project summary when inscribed into the
#     package manifest, defaulting to "${NAME} package".
#   \optional[list] SOURCES:dir The name of a directory containing the
#     sources of the ROS package and defaulting to the package name. The
#     directory will be recursed by remake_add_directories() with the
#     respective component set.
#   \optional[list] DEPENDS:pkg An optional list naming both build and runtime
#     dependencies of the defined ROS package. This list will be passed to
#     remake_ros_package_add_dependencies().
#   \optional[list] BUILD_DEPENDS:pkg A list naming ROS build dependencies
#     of the defined ROS package. If the META option is not provided, this
#     list is initialized to the default ROS packages roscpp and rospy.
#     It will be passed to remake_ros_package_add_dependencies().
#   \optional[list] RUN_DEPENDS:pkg A list naming ROS runtime dependencies
#     of the defined ROS package. For ROS "fuerte" and earlier distributions
#     and with the META option being present, this list defaults to the ROS
#     stacks ros and ros_comm. In all other cases, it contains the default
#     ROS packages roscpp and rospy. The list will be passed to
#     remake_ros_package_add_dependencies().
#   \optional[list] EXTRA_BUILD_DEPENDS:pkg A list naming external build
#     dependencies of the defined ROS package. This list will be passed to
#     remake_ros_package_add_dependencies().
#   \optional[list] EXTRA_RUN_DEPENDS:pkg A list naming external runtime
#     dependencies of the defined ROS package. This list will be passed to
#     remake_ros_package_add_dependencies().
#   \optional[var] REVERSE_DEPENDS:meta_pkg The defined ROS meta-package or
#     stack the ROS package reversly depends on. If the META option is not
#     provided, the default name of the meta-package or stack is inferred by
#     converting ${REMAKE_COMPONENT} into a ROS-compliant package or stack
#     name. To indicate that the ROS package does not reversely depend on
#     any other ROS meta-package or stack, the special value OFF may be
#     passed. In particular, if the component name equals
#     ${REMAKE_DEFAULT_COMPONENT}, the default value of this argument will
#     resolve to OFF.
#   \optional[option] META If provided, this option entails definition
#     of a ROS meta-package or stack. Such meta-packages or stacks should
#     not contain any build targets, but may depend on other ROS packages
#     through the REVERSE_DEPENDS argument. However, ReMake does not actually
#     enforce this particular constraint.
macro(remake_ros_package ros_name)
  remake_arguments(PREFIX ros_ VAR COMPONENT VAR DESCRIPTION VAR SOURCES
    LIST DEPENDS LIST BUILD_DEPENDS LIST RUN_DEPENDS LIST EXTRA_BUILD_DEPENDS
    LIST EXTRA_RUN_DEPENDS VAR REVERSE_DEPENDS OPTION META ${ARGN})
  string(REGEX REPLACE "_" "-" ros_default_component ${ros_name})
  remake_set(ros_component SELF DEFAULT ${ros_default_component})
  remake_set(ros_sources SELF DEFAULT ${ros_name})

  remake_ros()

  if(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
    remake_set(ros_description SELF DEFAULT "${ros_name} package")
    remake_set(ros_run_depends SELF DEFAULT roscpp rospy)
    if(NOT ros_meta)
      remake_set(ros_build_depends SELF DEFAULT roscpp rospy)
      if(NOT REMAKE_COMPONENT STREQUAL REMAKE_DEFAULT_COMPONENT)
        string(REGEX REPLACE "-" "_" ros_default_reverse_depends
          ${REMAKE_COMPONENT})
      else(NOT REMAKE_COMPONENT STREQUAL REMAKE_DEFAULT_COMPONENT)
        remake_set(ros_default_reverse_depends OFF)
      endif(NOT REMAKE_COMPONENT STREQUAL REMAKE_DEFAULT_COMPONENT)
      remake_set(ros_reverse_depends SELF DEFAULT
        ${ros_default_reverse_depends})
    endif(NOT ros_meta)

    remake_file_name(ros_dest_dir ${ros_name})
    if(ros_reverse_depends)
      if(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_stack_get(${ros_reverse_depends} COMPONENT
          OUTPUT ros_dest_component)
        remake_component_get(${ros_dest_component} FILE_DESTINATION
          OUTPUT ros_dest_file_destination)
        remake_set(ros_dest_root ${ros_dest_file_destination}/${ros_dest_dir})
      else(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_package_get(${ros_reverse_depends} META
          OUTPUT ros_dest_meta)
        if(NOT ros_dest_meta)
          message(FATAL_ERROR
            "ROS package ${ros_name} reversely depends on non-meta package!")
        endif(NOT ros_dest_meta)
        remake_set(ros_dest_root share/${ros_dest_dir})
      endif(${ROS_DISTRIBUTION} STRLESS groovy)
    else(ros_reverse_depends)
      remake_set(ros_dest_root share/${ros_dest_dir})
    endif(ros_reverse_depends)
    remake_file_name(ros_filename
      ${REMAKE_ROS_FILENAME_PREFIX}-${ROS_DISTRIBUTION}-${ros_name})
    string(REGEX REPLACE "_" "-" ros_filename ${ros_filename})

    remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
    list(FIND ros_packages ${ros_name} ros_index)
    if(NOT ros_index LESS 0)
      message(FATAL_ERROR "ROS package ${ros_name} multiply defined!")
    endif(NOT ros_index LESS 0)
    remake_project_set(ROS_PACKAGES ${ros_packages} ${ros_name}
      CACHE INTERNAL "ROS packages defined by the project.")

    remake_file(ros_pkg_dir ${REMAKE_ROS_PACKAGE_DIR}/${ros_name} TOPLEVEL)
    remake_file_mkdir(${ros_pkg_dir})

    string(REGEX REPLACE "[.]$" "" ros_summary ${REMAKE_PROJECT_SUMMARY})
    remake_set(ros_summary "${ros_summary} (${ros_description})")

    remake_set(ros_manifest_head "<package>")
    if(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
      remake_set(ros_version "${REMAKE_PROJECT_MAJOR}.${REMAKE_PROJECT_MINOR}")
      remake_set(ros_version "${ros_version}.${REMAKE_PROJECT_PATCH}")
      remake_list_push(ros_manifest_head
        "  <name>${ros_name}</name>"
        "  <version>${ros_version}</version>"
        "  <description>"
        "    ${ros_summary}"
        "  </description>")
    else(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
      remake_list_push(ros_manifest_head
        "  <description brief=\"${ros_summary}\"/>")
    endif(NOT ${ROS_DISTRIBUTION} STRLESS groovy)
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

    remake_set(ros_manifest ${ros_pkg_dir}/${REMAKE_ROS_PACKAGE_MANIFEST})
    remake_ros_package_set(${ros_name} MANIFEST ${ros_manifest}
      CACHE INTERNAL "Manifest file of ROS package ${ros_name}.")
    remake_file_mkdir(${ros_manifest}.d)
    remake_file_write(${ros_manifest}.d/00-head
      LINES ${ros_manifest_head})
    remake_file_write(${ros_manifest}.d/99-tail
      LINES ${ros_manifest_tail})

    remake_set(ros_manifest_script
      "include(ReMakeFile)"
      "remake_file_cat(${ros_manifest} ${ros_manifest}.d/*)")
    remake_file_write(${ros_manifest}.cmake LINES ${ros_manifest_script})
    remake_target_name(ros_manifest_target ${ros_name}
      ${REMAKE_ROS_PACKAGE_MANIFEST_TARGET_SUFFIX})
    remake_component(${ros_component}
      FILENAME ${ros_filename}
      PREFIX OFF
      INSTALL ${ROS_PATH}
      EXECUTABLE_DESTINATION ${ros_dest_root}/bin
      SCRIPT_DESTINATION ${ros_dest_root}/bin
      FILE_DESTINATION ${ros_dest_root}
      CONFIGURATION_DESTINATION ${ros_dest_root}/etc)
    remake_component_name(ros_dev_component ${ros_component}
      ${REMAKE_COMPONENT_DEVEL_SUFFIX})
    remake_component(${ros_dev_component}
      FILENAME ${ros_filename}-${REMAKE_COMPONENT_DEVEL_SUFFIX}
      PREFIX OFF
      INSTALL ${ROS_PATH}
      HEADER_DESTINATION include/${ros_name})
    remake_component_name(ros_python_component ${ros_component}
      ${REMAKE_PYTHON_COMPONENT_SUFFIX})
    remake_component(${ros_python_component}
      FILENAME ${ros_filename}-${REMAKE_PYTHON_COMPONENT_SUFFIX}
      PREFIX OFF
      INSTALL ${ROS_PATH})
    remake_component_add_command(
      OUTPUT ${ros_manifest} AS ${ros_manifest_target}
      COMMAND ${CMAKE_COMMAND} -P ${ros_manifest}.cmake
      COMMENT "Generating ${ros_name} package manifest"
      COMPONENT ${ros_component})
    remake_component_install(
      FILES ${ros_manifest}
      DESTINATION ${ros_dest_root}
      COMPONENT ${ros_component})
    if(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
      remake_target(${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    endif(NOT TARGET ${REMAKE_ROS_ALL_MANIFESTS_TARGET})
    add_dependencies(${REMAKE_ROS_ALL_MANIFESTS_TARGET} ${ros_manifest_target})

    remake_ros_package_set(${ros_name} COMPONENT ${ros_component}
      CACHE INTERNAL "Component of ROS package ${ros_name}.")
    remake_ros_package_set(${ros_name} DESCRIPTION ${ros_description}
      CACHE INTERNAL "Description of ${ros_name} ROS package.")
    remake_ros_package_set(${ros_name} META ${ros_meta}
      CACHE INTERNAL "ROS package ${ros_name} is a meta-package.")
    remake_set(ros_build_depends ${ros_depends} ${ros_build_depends})
    remake_set(ros_run_depends ${ros_depends} ${ros_run_depends})
    remake_ros_package_add_dependencies(
      ${ros_name}
      BUILD_DEPENDS ${ros_build_depends}
      RUN_DEPENDS ${ros_run_depends}
      EXTRA_BUILD_DEPENDS ${ros_extra_build_depends}
      EXTRA_RUN_DEPENDS ${ros_extra_run_depends})
    if(ros_reverse_depends)
      if(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_stack_add_dependencies(${ros_reverse_depends}
          DEPLOYS ${ros_name})
      else(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_ros_package_add_dependencies(${ros_reverse_depends}
          RUN_DEPENDS ${ros_name})
      endif(${ROS_DISTRIBUTION} STRLESS groovy)
    endif(ros_reverse_depends)

    if(ros_meta)
      message(STATUS "ROS meta-package: ${ros_name}")
    else(ros_meta)
      if(ros_reverse_depends)
        message(STATUS "ROS package: ${ros_name} (${ros_reverse_depends})")
      else(ros_reverse_depends)
        message(STATUS "ROS package: ${ros_name}")
      endif(ros_reverse_depends)
    endif(ros_meta)

    remake_add_directories(${ros_sources} COMPONENT ${ros_component})
  else(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
    remake_set(ros_run_depends SELF DEFAULT ros ros_comm)
    remake_ros_stack(
      ${ros_name}
      COMPONENT ${ros_component}
      ${DESCRIPTION}
      SOURCES ${ros_sources}
      DEPENDS ${ros_depends} ${ros_run_depends})
  endif(NOT ${ROS_DISTRIBUTION} STRLESS groovy OR NOT ros_meta)
endmacro(remake_ros_package)

### \brief Define the value of a ROS package variable.
#   This macro defines a ROS package variable matching the ReMake naming
#   conventions. The variable name is automatically prefixed with an
#   upper-case conversion of the package name. Thus, variables may
#   appear in the cache as project variables named after
#   ${PACKAGE_NAME}_ROS_PACKAGE_${VAR_NAME}. Additional arguments are
#   passed on to remake_project_set(). Note that the ROS package needs
#   to be defined.
#   \required[value] name The name of the ROS package for which the
#     variable shall be defined.
#   \required[value] variable The name of the package variable to be
#     defined.
#   \optional[list] arg The arguments to be passed on to remake_project_set().
#      See ReMakeProject for details.
macro(remake_ros_package_set ros_name ros_var)
  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  list(FIND ros_packages ${ros_name} ros_index)

  if(ros_index GREATER -1)
    remake_var_name(ros_package_var ${ros_name} ROS_PACKAGE ${ros_var})
    remake_project_set(${ros_package_var} ${ARGN})
  else(ros_index GREATER -1)
    message(FATAL_ERROR "ROS package ${ros_name} undefined!")
  endif(ros_index GREATER -1)
endmacro(remake_ros_package_set)

### \brief Retrieve the value of a ROS package variable.
#   This macro retrieves a ROS package variable matching the ReMake
#   naming conventions. Specifically, project variables named after
#   ${PACKAGE_NAME}_ROS_PACKAGE_${VAR_NAME} can be found by passing
#   ${VAR_NAME} to this macro. Note that the component needs to be defined.
#   \required[value] name The name of the ROS package to retrieve the
#     variable value for.
#   \required[value] variable The name of the package variable to retrieve
#     the value for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried package variable.
macro(remake_ros_package_get ros_name ros_var)
  remake_arguments(PREFIX ros_ VAR OUTPUT ${ARGN})

  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  list(FIND ros_packages ${ros_name} ros_index)

  if(ros_index GREATER -1)
    remake_var_name(ros_package_var ${ros_name} ROS_PACKAGE ${ros_var})
    remake_set(ros_output SELF DEFAULT ${ros_var})

    remake_project_get(${ros_package_var} OUTPUT ${ros_output})
  else(ros_index GREATER -1)
    message(FATAL_ERROR "ROS package ${ros_name} undefined!")
  endif(ros_index GREATER -1)
endmacro(remake_ros_package_get)

### \brief Add dependencies to a ROS package, meta-package, or stack.
#   Depending on the indicated ROS distribution, this macro adds dependencies
#   to an already defined ROS package, meta-package, or stack. Regarding
#   future portability, its use is strongly encouraged over
#   remake_ros_stack_add_dependencies(). For ROS "fuerte" and earlier
#   distributions, remake_ros_package_add_dependencies() is silently diverted
#   to remake_ros_stack_add_dependencies() if no package with the given name
#   is defined. Essentially, the macro calls remake_ros_find_package() to
#   discover the packages required during build. All directories in
#   ROS_${NAME}_INCLUDE_DIRS are then added to the include path by calling
#   remake_include(). In addition, the directories in which the linker will
#   look for the package libraries is specified by passing
#   ROS_${NAME}_LIBRARY_DIRS to CMake's link_directories().
#   \required[value] name The name of an already defined ROS package or
#     meta-package to which the package dependencies should be added.
#   \optional[list] DEPENDS:pkg A list of both package build and runtime 
#     dependencies that are inscribed into the ROS package manifest.
#   \optional[list] BUILD_DEPENDS:pkg A list of ROS build dependencies
#     that are inscribed into the ROS package manifest. Note that a ROS
#     meta-package may only define runtime dependencies on other ROS packages.
#   \optional[list] RUN_DEPENDS:pkg A list of ROS runtime dependencies
#     that are inscribed into the ROS package manifest.
#   \optional[list] EXTRA_BUILD_DEPENDS:pkg A list of external build
#     dependencies that are inscribed into the ROS package manifest. Note
#     that a ROS meta-package may only define runtime dependencies on other
#     external packages.
#   \optional[list] EXTRA_RUN_DEPENDS:pkg A list of external runtime
#     dependencies that are inscribed into the ROS package manifest.
macro(remake_ros_package_add_dependencies ros_name)
  remake_arguments(PREFIX ros_ LIST DEPENDS LIST BUILD_DEPENDS LIST RUN_DEPENDS
    LIST EXTRA_BUILD_DEPENDS LIST EXTRA_RUN_DEPENDS ${ARGN})

  remake_ros()

  remake_list_push(ros_build_depends ${ros_depends})
  remake_list_remove_duplicates(ros_build_depends)
  remake_list_push(ros_run_depends ${ros_depends})
  remake_list_remove_duplicates(ros_run_depends)

  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  if(${ROS_DISTRIBUTION} STRLESS groovy)
    list(FIND ros_packages ${ros_name} ros_index)
  else(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_set(ros_index 0)
  endif(${ROS_DISTRIBUTION} STRLESS groovy)

  if(NOT ros_index LESS 0)
    remake_ros_package_get(${ros_name} MANIFEST OUTPUT ros_manifest)

    if(ros_build_depends OR ros_extra_build_depends)
      remake_ros_package_get(${ros_name} META OUTPUT ros_meta)
      if(ros_meta)
        message(FATAL_ERROR
          "ROS meta-package ${ros_name} defines build dependencies!")
      endif(ros_meta)
    endif(ros_build_depends OR ros_extra_build_depends)

    if(ros_build_depends)
      remake_ros_package_get(${ros_name} INTERNAL_BUILD_DEPENDS
        OUTPUT ros_build_deps_int)
      remake_ros_package_get(${ros_name} EXTERNAL_BUILD_DEPENDS
        OUTPUT ros_build_deps_ext)
      remake_ros_package_get(${ros_name} LINK_LIBRARIES OUTPUT ros_link_libs)
      remake_ros_package_get(${ros_name} LDFLAGS_OTHER OUTPUT ros_link_flags)

      remake_unset(ros_manifest_build_depends)
      foreach(ros_dependency ${ros_build_depends})
        list(FIND ros_packages ${ros_dependency} ros_index)

        if(ros_index LESS 0)
          remake_ros_find_package(${ros_dependency})
          remake_var_name(ros_include_dirs_var ROS ${ros_dependency}
            INCLUDE_DIRS)
          remake_var_name(ros_link_libraries_var ROS ${ros_dependency}
            LIBRARIES)
          remake_var_name(ros_library_dirs_var ROS ${ros_dependency}
            LIBRARY_DIRS)
          remake_var_name(ros_link_flags_var ROS ${ros_dependency}
            LDFLAGS_OTHER)

          if(${ros_include_dirs_var})
            remake_include(${${ros_include_dirs_var}})
          endif(${ros_include_dirs_var})
          remake_list_push(ros_link_libs ${${ros_link_libraries_var}})
          if(${ros_library_dirs_var})
            link_directories(${${ros_library_dirs_var}})
          endif(${ros_library_dirs_var})
          remake_list_push(ros_link_flags ${${ros_link_flags_var}})
          remake_list_push(ros_build_deps_ext ${ros_dependency})
        else(ros_index LESS 0)
          remake_ros_package_get(${ros_dependency} INCLUDE_DIRS
            OUTPUT ros_include_dirs)
          include_directories(${ros_include_dirs})
          remake_list_push(ros_build_deps_int ${ros_dependency})
        endif(ros_index LESS 0)

        if(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_build_depends
            "  <depend package=\"${ros_dependency}\"/>")
        else(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_build_depends
            "  <build_depend>${ros_dependency}</build_depend>")
        endif(${ROS_DISTRIBUTION} STRLESS groovy)
      endforeach(ros_dependency)

      remake_file_write(${ros_manifest}.d/50-build_depends LINES
        ${ros_manifest_build_depends})
      remake_list_remove_duplicates(ros_build_deps_int)
      remake_ros_package_set(${ros_name} INTERNAL_BUILD_DEPENDS
        ${ros_build_deps_int} CACHE INTERNAL
        "Internal build dependencies of ROS package ${ros_name}.")
      remake_list_remove_duplicates(ros_build_deps_ext)
      remake_ros_package_set(${ros_name} EXTERNAL_BUILD_DEPENDS
        ${ros_build_deps_ext} CACHE INTERNAL
        "External build dependencies of ROS package ${ros_name}.")
      remake_list_remove_duplicates(ros_link_libraries)
      remake_ros_package_set(${ros_name} LINK_LIBRARIES ${ros_link_libs}
        CACHE INTERNAL "Link libraries of ROS package ${ros_name}.")
      remake_ros_package_set(${ros_name} LDFLAGS_OTHER ${ros_link_flags}
        CACHE INTERNAL "Linker flags of ROS package ${ros_name}.")
    endif(ros_build_depends)

    if(ros_extra_build_depends)
      remake_ros_package_get(${ros_name} EXTRA_BUILD_DEPENDS
        OUTPUT ros_extra_build_deps)

      remake_unset(ros_manifest_extra_build_depends)
      foreach(ros_dependency ${ros_extra_build_depends})
        if(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_extra_build_depends
            "  <rosdep name=\"${ros_dependency}\"/>")
        else(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_extra_build_depends
            "  <build_depend>${ros_dependency}</build_depend>")
        endif(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_list_push(ros_extra_build_deps ${ros_dependency})
      endforeach(ros_dependency)

      remake_file_write(${ros_manifest}.d/51-extra_build_depends LINES
        ${ros_manifest_extra_build_depends})
      remake_list_remove_duplicates(ros_extra_build_deps)
      remake_ros_package_set(${ros_name} EXTRA_BUILD_DEPENDS
        ${ros_extra_build_deps}
        CACHE INTERNAL "Extra build dependencies of ROS package ${ros_name}.")
    endif(ros_extra_build_depends)

    if(ros_run_depends)
      remake_ros_package_get(${ros_name} INTERNAL_RUN_DEPENDS
        OUTPUT ros_run_deps_int)
      remake_ros_package_get(${ros_name} EXTERNAL_RUN_DEPENDS
        OUTPUT ros_run_deps_ext)

      remake_unset(ros_manifest_run_depends)
      foreach(ros_dependency ${ros_run_depends})
        list(FIND ros_packages ${ros_dependency} ros_index)

        if(ros_index LESS 0)
          remake_list_push(ros_run_deps_ext ${ros_dependency})
        else(ros_index LESS 0)
          remake_list_push(ros_run_deps_int ${ros_dependency})
        endif(ros_index LESS 0)

        if(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_run_depends
            "  <depend package=\"${ros_dependency}\"/>")
        else(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_run_depends
            "  <run_depend>${ros_dependency}</run_depend>")
        endif(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_list_push(ros_run_deps ${ros_dependency})
      endforeach(ros_dependency)

      remake_file_write(${ros_manifest}.d/52-run_depends LINES
        ${ros_manifest_run_depends})
      remake_list_remove_duplicates(ros_run_deps_int)
      remake_ros_package_set(${ros_name} INTERNAL_RUN_DEPENDS
        ${ros_run_deps_int} CACHE INTERNAL
        "Internal runtime dependencies of ROS package ${ros_name}.")
      remake_list_remove_duplicates(ros_run_deps_ext)
      remake_ros_package_set(${ros_name} EXTERNAL_RUN_DEPENDS
        ${ros_run_deps_ext} CACHE INTERNAL
        "External runtime dependencies of ROS package ${ros_name}.")
    endif(ros_run_depends)

    if(ros_extra_run_depends)
      remake_ros_package_get(${ros_name} EXTRA_RUN_DEPENDS
        OUTPUT ros_extra_run_deps)

      remake_unset(ros_manifest_extra_run_depends)
      foreach(ros_dependency ${ros_extra_run_depends})
        if(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_extra_run_depends
            "  <rosdep name=\"${ros_dependency}\"/>")
        else(${ROS_DISTRIBUTION} STRLESS groovy)
          remake_list_push(ros_manifest_extra_run_depends
            "  <run_depend>${ros_dependency}</run_depend>")
        endif(${ROS_DISTRIBUTION} STRLESS groovy)
        remake_list_push(ros_extra_run_deps ${ros_dependency})
      endforeach(ros_dependency)

      remake_file_write(${ros_manifest}.d/54-extra_run_depends LINES
        ${ros_manifest_extra_run_depends})
      remake_list_remove_duplicates(ros_extra_run_deps)
      remake_ros_package_set(${ros_name} EXTRA_RUN_DEPENDS
        ${ros_extra_run_deps} CACHE INTERNAL
        "Extra runtime dependencies of ROS package ${ros_name}.")
    endif(ros_extra_run_depends)
  else(NOT ros_index LESS 0)
    remake_ros_stack_add_dependencies(${ros_name} ${DEPENDS})
  endif(NOT ros_index LESS 0)
endmacro(remake_ros_package_add_dependencies)

### \brief Add a code generation target to a ROS package.
#   This macro adds a code generation target to an already defined ROS
#   package. It is a helper macro which is responsible for generating
#   C++ headers and Python modules from a list of ROS message or service
#   definitions. Usually, there is no need for calling it directly.
#   Instead, use of the wrapper macros remake_ros_package_add_messages()
#   and remake_ros_package_add_services() is strongly encouraged.
#   \required[value] name The name of the generator to be used for
#     code generation, usually message or service.
#   \optional[value] PACKAGE:package The name of the already defined
#     ROS package to which the code generation target shall be added,
#     defaulting to the package name conversion of ${REMAKE_COMPONENT}.
#   \optional[list] glob A list of glob expressions that are resolved
#     in order to find the input files of the generator commands,
#     defaulting to *.${EXT} and ${EXT}/*.${EXT}.
#   \required[value] EXT:extension The extension used by the input
#     definitions, usually msg or srv.
#   \optional[option] DISTRIBUTE If present, this option causes the
#     macro to distribute all generated Python packages for the ROS
#     package by calling remake_python_distribute().
macro(remake_ros_package_generate ros_name)
  remake_arguments(PREFIX ros_ VAR PACKAGE VAR EXT OPTION DISTRIBUTE
    ARGN globs ${ARGN})
  string(REGEX REPLACE "-" "_" ros_default_package ${REMAKE_COMPONENT})
  remake_set(ros_package SELF DEFAULT ${ros_default_package})
  remake_set(ros_globs SELF DEFAULT *.${ros_ext} ${ros_ext}/*.${ros_ext})

  remake_ros()

  remake_ros_package_get(${ros_package} COMPONENT OUTPUT ros_component)
  remake_file(ros_pkg_dir ${REMAKE_ROS_PACKAGE_DIR}/${ros_package} TOPLEVEL)
  remake_file_mkdir(${ros_pkg_dir}/${ros_ext})
  remake_file_configure(${ros_globs}
    DESTINATION ${ros_pkg_dir}/${ros_ext} STRIP_PATHS
    OUTPUT ros_${ros_name}s)

  remake_find_executable(rosrun PATHS "${ROS_PATH}/bin")

  if(ROSRUN_FOUND AND ros_${ros_name}s)
    remake_ros_package_add_dependencies(
      ${ros_package}
      BUILD_DEPENDS rosbash rosbuild)

    string(REGEX REPLACE ";" ":" ros_pkg_path "${ROS_PACKAGE_PATH}")
    if(CMAKE_CROSSCOMPILING AND CMAKE_FIND_ROOT_PATH)
      remake_set(ros_prefix_path ${CMAKE_FIND_ROOT_PATH}${ROS_PATH})
    else(CMAKE_CROSSCOMPILING AND CMAKE_FIND_ROOT_PATH)
      remake_set(ros_prefix_path ${ROS_PATH})
    endif(CMAKE_CROSSCOMPILING AND CMAKE_FIND_ROOT_PATH)
    
    remake_target_name(ros_manifest_targets
    ${ros_package} ${REMAKE_ROS_PACKAGE_MANIFEST_TARGET_SUFFIX})
    remake_var_name(ros_${ros_name}_target_suffix_var
      REMAKE_ROS_PACKAGE ${ros_name}s TARGET_SUFFIX)
    remake_target_name(ros_${ros_name}s_target
      ${ros_package} ${${ros_${ros_name}_target_suffix_var}})
    remake_set(ros_include_dir
      ${ros_pkg_dir}/${ros_ext}_gen/cpp/include)
    remake_set(ros_module_dir ${ros_pkg_dir}/src/${ros_package})

    remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
    remake_ros_package_get(${ros_package} INTERNAL_BUILD_DEPENDS
      OUTPUT ros_depends)
    foreach(ros_dependency ${ros_depends})
      remake_target_name(ros_manifest_target
        ${ros_dependency} ${REMAKE_ROS_PACKAGE_MANIFEST_TARGET_SUFFIX})
      remake_list_push(ros_manifest_targets ${ros_manifest_target})
    endforeach(ros_dependency)

    remake_unset(ros_${ros_name}_headers)
    remake_unset(ros_${ros_name}_modules)
    foreach(ros_${ros_name} ${ros_${ros_name}s})
      get_filename_component(ros_${ros_name}_name ${ros_${ros_name}} NAME)
      get_filename_component(ros_${ros_name}_name_we ${ros_${ros_name}}
        NAME_WE)

      remake_set(ros_${ros_name}_header
        ${ros_include_dir}/${ros_package}/${ros_${ros_name}_name_we}.h)
      remake_ros_command(
        CMAKE_PREFIX_PATH=${ros_prefix_path} &&
        ROS_PACKAGE_PATH=${ros_pkg_dir}/..:${ros_pkg_path} &&
        ${ROSRUN_EXECUTABLE} roscpp gen${ros_ext}_cpp.py
          ${ros_ext}/${ros_${ros_name}_name}
        OUTPUT ros_${ros_name}_command)
      add_custom_command(
        OUTPUT ${ros_${ros_name}_header}
        COMMAND ${ros_${ros_name}_command}
        WORKING_DIRECTORY ${ros_pkg_dir}
        DEPENDS ${ros_${ros_name}}
        COMMENT "Generating ${ros_${ros_name}_name_we} ${ros_name} (C++)")
      remake_list_push(ros_${ros_name}_headers ${ros_${ros_name}_header})

      remake_set(ros_${ros_name}_module
        ${ros_module_dir}/${ros_ext}/_${ros_${ros_name}_name_we}.py)
      remake_ros_command(
        CMAKE_PREFIX_PATH=${ros_prefix_path} &&
        ROS_PACKAGE_PATH=${ros_pkg_dir}/..:${ros_pkg_path} &&
        ${ROSRUN_EXECUTABLE} rospy gen${ros_ext}_py.py
          ${ros_ext}/${ros_${ros_name}_name}
        OUTPUT ros_${ros_name}_command)
      add_custom_command(
        OUTPUT ${ros_${ros_name}_module}
        COMMAND ${ros_${ros_name}_command}
        WORKING_DIRECTORY ${ros_pkg_dir}
        DEPENDS ${ros_${ros_name}}
        COMMENT "Generating ${ros_${ros_name}_name_we} ${ros_name} (Python)")
      remake_list_push(ros_${ros_name}_modules ${ros_${ros_name}_module})
    endforeach(ros_${ros_name})

    remake_ros_command(
      CMAKE_PREFIX_PATH=${ros_prefix_path} &&
      ROS_PACKAGE_PATH=${ros_pkg_dir}/..:${ros_pkg_path} &&
      ${ROSRUN_EXECUTABLE} rospy gen${ros_ext}_py.py --initpy ${ros_pkg_dir}
      OUTPUT ros_${ros_name}_command)
    add_custom_command(
      OUTPUT ${ros_module_dir}/${ros_ext}/__init__.py
      COMMAND ${ros_${ros_name}_command}
      WORKING_DIRECTORY ${ros_pkg_dir}
      DEPENDS ${ros_${ros_name}_modules}
      COMMENT "Generating ${ros_package} ${ros_name}s package (Python)")
    remake_list_push(ros_${ros_name}_modules
      ${ros_module_dir}/${ros_ext}/__init__.py)

    remake_project_get(PYTHON_PACKAGES OUTPUT ros_python_packages)
    list(FIND ros_python_packages ${ros_package} ros_index)
    if(NOT ros_index GREATER -1)
      add_custom_command(
        OUTPUT ${ros_module_dir}/__init__.py
        COMMAND ${ros_${ros_name}_command}
        WORKING_DIRECTORY ${ros_pkg_dir}
        DEPENDS ${ros_${ros_name}_modules}
        COMMENT "Finalizing ${ros_package} package (Python)")
      remake_list_push(ros_${ros_name}_modules ${ros_module_dir}/__init__.py)
      remake_python_package(
        NAME ${ros_package}
        DIRECTORY ${ros_module_dir}
        ${ros_${ros_name}_modules} GENERATED)
    else(NOT ros_index GREATER -1)
      remake_python_add_modules(
        PACKAGE ${ros_package}
        ${ros_${ros_name}_modules} GENERATED)
    endif(NOT ros_index GREATER -1)

    remake_target(${ros_${ros_name}s_target}
      DEPENDS ${ros_${ros_name}_headers} ${ros_${ros_name}_modules})
    remake_component_add_dependencies(COMPONENT ${ros_component}
      DEPENDS ${ros_${ros_name}s_target})
    remake_component_name(ros_dev_component ${ros_component}
      ${REMAKE_COMPONENT_DEVEL_SUFFIX})
    remake_component_add_dependencies(COMPONENT ${ros_dev_component}
      DEPENDS ${ros_${ros_name}s_target})
    add_dependencies(${ros_${ros_name}s_target} ${ros_manifest_targets})

    remake_add_headers(${ros_${ros_name}_headers}
      COMPONENT ${ros_dev_component} GENERATED)
    include_directories(${ros_include_dir} BEFORE)

    if(ros_distribute)
      remake_component_name(ros_python_component ${ros_component}
        ${REMAKE_PYTHON_COMPONENT_SUFFIX})
      remake_ros_package_get(${ros_package} DESCRIPTION OUTPUT ros_description)
      remake_python_distribute(
        NAME ${ros_package}
        PACKAGES ${ros_package}
        DESCRIPTION "${ros_description}"
        COMPONENT ${ros_python_component})

      remake_target_name(ros_python_target
        ${ros_package} ${REMAKE_PYTHON_TARGET_SUFFIX})
      add_dependencies(${ros_python_target} ${ros_manifest_targets})
    endif(ros_distribute)

    remake_ros_package_get(${ros_package} INCLUDE_DIRS OUTPUT ros_include_dirs)
    remake_set(ros_include_dirs ${ros_include_dir} ${ros_include_dirs})
    remake_list_remove_duplicates(ros_include_dirs)
    remake_ros_package_set(${ros_package} INCLUDE_DIRS ${ros_include_dirs}
      CACHE INTERNAL "Include directories of ROS package ${ros_package}.")
  endif(ROSRUN_FOUND AND ros_${ros_name}s)

  remake_component_get(${ros_component} FILE_DESTINATION OUTPUT ros_dest)
  remake_component_install(
    FILES ${ros_${ros_name}s}
    DESTINATION ${ros_dest}/${ros_ext}
    COMPONENT ${ros_component})
endmacro(remake_ros_package_generate)

### \brief Add ROS messages to a ROS package.
#   This macro adds ROS messages to an already defined ROS package containing
#   only message definitions. It invokes remake_ros_package_generate() to
#   define a target and the corresponding commands for generating C++ headers
#   and Python modules from a list of glob expressions.
#   \optional[value] PACKAGE:package The name of the already defined
#     ROS package for which the message definitions shall be processed,
#     defaulting to the package name conversion of ${REMAKE_COMPONENT}.
#   \optional[list] glob A list of glob expressions that are resolved
#     in order to find the message definitions, defaulting to *.msg and
#     msg/*.msg.
macro(remake_ros_package_add_messages)
  remake_ros_package_generate(message ${ARGN} EXT msg DISTRIBUTE)
endmacro(remake_ros_package_add_messages)

### \brief Add ROS services to a ROS package.
#   This macro adds ROS services to an already defined ROS package containing
#   only service definitions. It invokes remake_ros_package_generate() to
#   define a target and the corresponding commands for generating C++ headers
#   and Python modules from a list of glob expressions.
#   \optional[value] PACKAGE:package The name of the already defined
#     ROS package for which the service definitions shall be processed,
#     defaulting to the package name conversion of ${REMAKE_COMPONENT}.
#   \optional[list] glob A list of glob expressions that are resolved
#     in order to find the service definitions, defaulting to *.srv and
#     srv/*.srv.
macro(remake_ros_package_add_services)
  remake_ros_package_generate(service ${ARGN} EXT srv DISTRIBUTE)
endmacro(remake_ros_package_add_services)

### \brief Add ROS messages and services to a ROS package.
#   This macro adds ROS messages and services to an already defined ROS
#   package containing both message and service definitions. It invokes
#   remake_ros_package_generate() to define the targets and corresponding
#   commands for generating C++ headers and Python modules from a list of
#   glob expressions.
#   \optional[value] PACKAGE:package The name of the already defined
#     ROS package for which the message and service definitions shall be
#     processed, defaulting to the package name conversion of
#     ${REMAKE_COMPONENT}.
#   \optional[list] glob A list of glob expressions that are resolved
#     in order to find the message and service definitions, defaulting to
#     *.msg and msg/*.msg, and *.srv and srv/*.srv, respectively.
macro(remake_ros_package_add_generated)
  remake_ros_package_generate(message ${ARGN} EXT msg)
  remake_ros_package_generate(service ${ARGN} EXT srv DISTRIBUTE)
endmacro(remake_ros_package_add_generated)

### \brief Add an executable to a ROS package.
#   This macro adds an executable target to an already defined ROS package.
#   Its primary advantage over remake_add_executable() is the automated
#   resolution of dependencies on ROS messages or services generated
#   by the enlisted ROS packages. Moreover, the macro will add all ROS
#   libraries which need to be linked into the executable target from the
#   build dependencies defined for its ROS package.
#   \required[value] name The name of the executable target to be defined.
#   \optional[value] PACKAGE:package The name of the already defined ROS
#     package which will be assigned the executable, defaulting to the
#     package name conversion of ${REMAKE_COMPONENT}.
#   \optional[list] SOURCES:glob A list of glob expressions resolving to
#     the source files associated with the executable target, defaulting
#     to ${TARGET_NAME}.cpp.
#   \optional[list] arg The list of additional arguments to be passed on to
#     remake_add_executable(). Note that this list should not contain
#     a COMPONENT specifier as the component name will be inferred from the
#     ROS package name. Similarly, it is not necessary to provide a glob
#     expression for the source files. See ReMake for details.
macro(remake_ros_package_add_executable ros_name)
  remake_arguments(PREFIX ros_ VAR PACKAGE LIST SOURCES ARGN args ${ARGN})
  string(REGEX REPLACE "-" "_" ros_default_package ${REMAKE_COMPONENT})
  remake_set(ros_package SELF DEFAULT ${ros_default_package})
  remake_set(ros_sources SELF DEFAULT ${ros_name}.cpp)

  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  remake_ros_package_get(${ros_package} COMPONENT OUTPUT ros_component)
  remake_ros_package_get(${ros_package} INTERNAL_BUILD_DEPENDS
    OUTPUT ros_build_deps)
  remake_ros_package_get(${ros_package} LINK_LIBRARIES OUTPUT ros_link_libs)
  remake_ros_package_get(${ros_package} LDFLAGS_OTHER OUTPUT ros_link_flags)

  remake_unset(ros_generated ros_depends)
  foreach(ros_dependency ${ros_package} ${ros_build_deps})
    remake_target_name(ros_messages_target
      ${ros_dependency} ${REMAKE_ROS_PACKAGE_MESSAGES_TARGET_SUFFIX})
    remake_target_name(ros_services_target
      ${ros_dependency} ${REMAKE_ROS_PACKAGE_SERVICES_TARGET_SUFFIX})

    if(TARGET ${ros_messages_target})
      remake_list_push(ros_depends ${ros_messages_target})
    endif(TARGET ${ros_messages_target})
    if(TARGET ${ros_services_target})
      remake_list_push(ros_depends ${ros_services_target})
    endif(TARGET ${ros_services_target})
  endforeach(ros_dependency)

  if(ros_depends)
    remake_add_executable(
      ${ros_name} ${ros_sources} ${ros_args}
      DEPENDS ${ros_depends}
      LINK ${ros_link_libs}
      COMPONENT ${ros_component})
  else(ros_depends)
    remake_add_executable(
      ${ros_name} ${ros_sources} ${ros_args}
      LINK ${ros_link_libs}
      COMPONENT ${ros_component})
  endif(ros_depends)

  if(ros_link_flags)
    set_target_properties(${ros_name} PROPERTIES LINK_FLAGS
      "${ros_link_flags}" INSTALL_RPATH_USE_LINK_PATH ON)
  endif(ros_link_flags)
endmacro(remake_ros_package_add_executable)

### \brief Add a library to a ROS package.
#   This macro adds a library target to an already defined ROS package.
#   Its primary advantage over remake_add_library() is the automated
#   resolution of dependencies on ROS messages or services generated
#   by the enlisted ROS packages. Moreover, the macro will add all ROS
#   libraries which need to be linked into the library target from the
#   build dependencies defined for its ROS package.
#   \required[value] name The name of the library target to be defined.
#   \optional[value] PACKAGE:package The name of the already defined ROS
#     package which will be assigned the library, defaulting to the
#     package name conversion of ${REMAKE_COMPONENT}.
#   \optional[list] arg The list of additional arguments to be passed on to
#     remake_add_library(). Note that this list should not contain
#     a COMPONENT specifier as the component name will be inferred from the
#     ROS package name. See ReMake for details.
macro(remake_ros_package_add_library ros_name)
  remake_arguments(PREFIX ros_ VAR PACKAGE LIST SOURCES ARGN args ${ARGN})
  string(REGEX REPLACE "-" "_" ros_default_package ${REMAKE_COMPONENT})
  remake_set(ros_package SELF DEFAULT ${ros_default_package})

  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  remake_ros_package_get(${ros_package} COMPONENT OUTPUT ros_component)
  remake_ros_package_get(${ros_package} INTERNAL_BUILD_DEPENDS
    OUTPUT ros_build_deps)
  remake_ros_package_get(${ros_package} LINK_LIBRARIES OUTPUT ros_link_libs)
  remake_ros_package_get(${ros_package} LDFLAGS_OTHER OUTPUT ros_link_flags)

  remake_unset(ros_generated ros_depends)
  foreach(ros_dependency ${ros_package} ${ros_build_deps})
    remake_target_name(ros_messages_target
      ${ros_dependency} ${REMAKE_ROS_PACKAGE_MESSAGES_TARGET_SUFFIX})
    remake_target_name(ros_services_target
      ${ros_dependency} ${REMAKE_ROS_PACKAGE_SERVICES_TARGET_SUFFIX})

    if(TARGET ${ros_messages_target})
      remake_list_push(ros_depends ${ros_messages_target})
    endif(TARGET ${ros_messages_target})
    if(TARGET ${ros_services_target})
      remake_list_push(ros_depends ${ros_services_target})
    endif(TARGET ${ros_services_target})
  endforeach(ros_dependency)

  if(ros_depends)
    remake_add_library(
      ${ros_name} ${ros_args}
      DEPENDS ${ros_depends}
      LINK ${ros_link_libs}
      COMPONENT ${ros_component})
  else(ros_depends)
    remake_add_library(
      ${ros_name} ${ros_args}
      LINK ${ros_link_libs}
      COMPONENT ${ros_component})
  endif(ros_depends)

  if(ros_link_flags)
    set_target_properties(${ros_name} PROPERTIES LINK_FLAGS
      "${ros_link_flags}" INSTALL_RPATH_USE_LINK_PATH ON)
  endif(ros_link_flags)
endmacro(remake_ros_package_add_library)

### \brief Generate a ROS package's pkg-config file.
#   This macro generates a pkg-config file for an already defined ROS
#   package by calling remake_pkg_config_generate(). The name of the
#   pkg-config file is constructed by appending the .pc extension to
#   ${PACKAGE_NAME}. Furthermore, the ROS package's build dependencies are
#   evaluated and passed as requirements into remake_pkg_config_generate().
#   Note that only ROS expects its pkg-config files to be named after the
#   package. Therefore, external build dependencies will not be enlisted
#   automatically by the macro and must instead be specified explicitly
#   through the REQUIRES arguments. See ReMakePkgConfig for additional
#   information.
#   \optional[value] PACKAGE:package The name of the already defined ROS
#     package from which to generate the pkg-config file, defaulting to
#     the package name conversion of ${REMAKE_COMPONENT}.
#   \optional[list] arg The list of additional arguments to be passed on to
#     remake_pkg_config_generate(). See ReMakePkgConfig for details.
macro(remake_ros_package_config_generate)
  remake_arguments(PREFIX ros_ VAR PACKAGE ARGN args ${ARGN})
  string(REGEX REPLACE "-" "_" ros_default_package ${REMAKE_COMPONENT})
  remake_set(ros_package SELF DEFAULT ${ros_default_package})

  string(REGEX REPLACE "_" "-" ros_component ${ros_package})
  remake_ros_package_get(${ros_package} INTERNAL_BUILD_DEPENDS
    OUTPUT ros_dependencies)
  remake_ros_package_get(${ros_package} EXTERNAL_BUILD_DEPENDS
    OUTPUT ros_depends)
  remake_list_push(ros_dependencies ${ros_depends})
  
  remake_pkg_config_generate(
    COMPONENT ${ros_component}
    FILENAME ${ros_package}.pc
    NAME ${ros_package}
    REQUIRES ${ros_dependencies}
    ${ros_args})
endmacro(remake_ros_package_config_generate)

### \brief Generate binary Debian packages from a ReMakeROS project.
#   This macro configures package generation for a ReMakeROS project
#   using the ReMakePack module. It acquires all the information necessary
#   from the defined ROS packages, meta-packages, or stacks. For each
#   of them, Debian package generators will be defined. The macro breaks
#   with some of the conventional ROS packaging strategies. Firstly, it
#   defines Debian packages for non-meta ROS packages instead of including
#   these non-meta packages in a Debian package of the reversely dependent
#   ROS meta package or stack. It however installs dependencies between
#   the Debian packages such as to ensure the correct deployment of all ROS
#   packages belonging to a ROS meta-package or stack. Secondly, the macro
#   defines an additional Debian packages named after the ReMake project.
#   This package installs the project's default component which usually
#   contains the license file, the changelog, and similar distribution-relevant
#   files. The macro does however follow the ROS packaging conventions in
#   not separating runtime and development files. It combines all install
#   components associated with a ROS package into one monolithic Debian
#   package for that ROS package. Thus, the development headers and Python 
#   modules may be deployed together with the runtime.
#   \optional[list] EXTRA:glob An optional list of glob expressions matching
#     extra control information files such as preinst, postinst, prerm, and
#     postrm to be included in the control section of the Debian package
#     named after the ReMake project. See ReMakePack for details.
macro(remake_ros_pack_deb)
  remake_arguments(PREFIX ros_ LIST EXTRA ${ARGN})
  
  remake_ros()

  remake_unset(ros_pkg_components)
  if(${ROS_DISTRIBUTION} STRLESS groovy)
    remake_project_get(ROS_STACKS OUTPUT ros_stacks)
    foreach(ros_stack ${ros_stacks})
      remake_ros_stack_get(${ros_stack} COMPONENT OUTPUT ros_component)
      remake_var_name(ros_var ${ros_component} DESCRIPTION)
      remake_ros_stack_get(${ros_stack} DESCRIPTION OUTPUT ${ros_var})
      remake_var_name(ros_var ${ros_component} EXTERNAL_RUN_DEPENDS)
      remake_ros_stack_get(${ros_stack} EXTERNAL_RUN_DEPENDS OUTPUT ${ros_var})
      remake_var_name(ros_var ${ros_component} INTERNAL_RUN_DEPENDS)
      remake_ros_stack_get(${ros_stack} INTERNAL_RUN_DEPENDS OUTPUT ${ros_var})
      remake_ros_stack_get(${ros_stack} DEPLOYS OUTPUT ros_deploys)
      remake_list_push(${ros_var} ${ros_deploys})
      remake_var_name(ros_var ${ros_component} INTERNAL_BUILD_DEPENDS)
      remake_set(${ros_var} FROM ${ros_var})
      remake_var_name(ros_var ${ros_component} META)
      remake_set(${ros_var} ON)
      remake_var_name(ros_var ${ros_component} MANIFEST)
      remake_set(${ros_var} ${REMAKE_ROS_STACK_MANIFEST})
      remake_list_push(ros_pkg_components ${ros_component})
    endforeach(ros_stack)
  endif(${ROS_DISTRIBUTION} STRLESS groovy)

  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  foreach(ros_package ${ros_packages})
    remake_ros_package_get(${ros_package} COMPONENT OUTPUT ros_component)
    remake_var_name(ros_var ${ros_component} DESCRIPTION)
    remake_ros_package_get(${ros_package} DESCRIPTION OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} INTERNAL_BUILD_DEPENDS)
    remake_ros_package_get(${ros_package} INTERNAL_BUILD_DEPENDS
      OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} EXTERNAL_BUILD_DEPENDS)
    remake_ros_package_get(${ros_package} EXTERNAL_BUILD_DEPENDS
      OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} INTERNAL_RUN_DEPENDS)
    remake_ros_package_get(${ros_package} INTERNAL_RUN_DEPENDS
      OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} EXTERNAL_RUN_DEPENDS)
    remake_ros_package_get(${ros_package} EXTERNAL_RUN_DEPENDS
      OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} EXTRA_BUILD_DEPENDS)
    remake_ros_package_get(${ros_package} EXTRA_BUILD_DEPENDS
      OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} EXTRA_RUN_DEPENDS)
    remake_ros_package_get(${ros_package} EXTRA_RUN_DEPENDS
      OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} META)
    remake_ros_package_get(${ros_package} META OUTPUT ${ros_var})
    remake_var_name(ros_var ${ros_component} MANIFEST)
    remake_set(${ros_var} ${REMAKE_ROS_PACKAGE_MANIFEST})
    remake_list_push(ros_pkg_components ${ros_component})
  endforeach(ros_package)

  remake_unset(ros_pkg_main_deps)
  foreach(ros_pkg_component ${ros_pkg_components})
    remake_var_name(ros_var ${ros_pkg_component} INTERNAL_BUILD_DEPENDS)
    remake_set(ros_build_deps_int FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} EXTERNAL_BUILD_DEPENDS)
    remake_set(ros_build_deps_ext FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} INTERNAL_RUN_DEPENDS)
    remake_set(ros_run_deps_int FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} EXTERNAL_RUN_DEPENDS)
    remake_set(ros_run_deps_ext FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} EXTRA_RUN_DEPENDS)
    remake_set(ros_pkg_deps FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} EXTRA_BUILD_DEPENDS)
    remake_list_push(ros_pkg_deps ${${ros_var}})
    remake_var_name(ros_var ${ros_pkg_component} DESCRIPTION)
    remake_set(ros_pkg_description FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} META)
    remake_set(ros_pkg_meta FROM ${ros_var})
    remake_var_name(ros_var ${ros_pkg_component} MANIFEST)
    remake_set(ros_pkg_manifest FROM ${ros_var})

    foreach(ros_dep_int ${ros_run_deps_int} ${ros_build_dep_int})
      remake_ros_package_get(${ros_dep_int} COMPONENT
        OUTPUT ros_dep_component)
      remake_component_get(${ros_dep_component} FILENAME
        OUTPUT ros_dep_filename)
      remake_list_push(ros_pkg_deps ${ros_dep_filename})
    endforeach(ros_dep_int)

    foreach(ros_dep_ext ${ros_run_deps_ext} ${ros_build_deps_ext})
      remake_var_name(ros_var ROS ${ros_dep_ext} PATH)
      remake_set(ros_manifest ${${ros_var}}/${ros_pkg_manifest})

      string(REGEX REPLACE "_" "-" ros_dep_ext ${ros_dep_ext})
      remake_debian_find_package(
        ros-${ROS_DISTRIBUTION}-${ros_dep_ext}
        CONTAINS ${ros_manifest}
        OUTPUT ros_dep_ext)
      remake_list_push(ros_pkg_deps ${ros_dep_ext})
    endforeach(ros_dep_ext)

    remake_component_name(ros_pkg_python_component ${ros_pkg_component}
      ${REMAKE_PYTHON_COMPONENT_SUFFIX})
    remake_component_name(ros_pkg_dev_component ${ros_pkg_component}
      ${REMAKE_COMPONENT_DEVEL_SUFFIX})
    if(ros_pkg_meta)
      remake_set(ros_pkg_python_component_empty ON)
      remake_set(ros_pkg_dev_component_empty ON)
    else(ros_pkg_meta)
      remake_component_get(${ros_pkg_python_component} EMPTY OUTPUT
        ros_pkg_python_component_empty)
      remake_component_get(${ros_pkg_dev_component} EMPTY OUTPUT
        ros_pkg_dev_component_empty)
    endif(ros_pkg_meta)
    
    remake_unset(ros_pkg_extra_components)
    if(NOT ros_pkg_python_component_empty)
      remake_list_push(ros_pkg_extra_components ${ros_pkg_python_component})
    endif(NOT ros_pkg_python_component_empty)
    if(NOT ros_pkg_dev_component_empty)
      remake_list_push(ros_pkg_extra_components ${ros_pkg_dev_component})
    endif(NOT ros_pkg_dev_component_empty)
    
    remake_list_remove_duplicates(ros_pkg_deps)
    if(ros_pkg_extra_components)
      remake_pack_deb(
        COMPONENT ${ros_pkg_component}
        EXTRA_COMPONENTS ${ros_pkg_extra_components}
        DESCRIPTION "${ros_pkg_description}"
        DEPENDS ${ros_pkg_deps})
    else(ros_pkg_extra_components)
      remake_pack_deb(
        COMPONENT ${ros_pkg_component}
        DESCRIPTION "${ros_pkg_description}"
        DEPENDS ${ros_pkg_deps})
    endif(ros_pkg_extra_components)
    remake_component_get(${ros_pkg_component} FILENAME
      OUTPUT ros_pkg_filename)
    remake_list_push(ros_pkg_main_deps ${ros_pkg_filename})
  endforeach(ros_pkg_component)

  if(ros_extra)
    remake_pack_deb(
      DEPENDS ${ros_pkg_main_deps}
      EXTRA ${ros_extra})
  else(ros_extra)
    remake_pack_deb(
      DEPENDS ${ros_pkg_main_deps})
  endif(ros_extra)  
endmacro(remake_ros_pack_deb)

### \brief Distribute a ReMakeROS project according to the Debian standards.
#   This macro configures source package generation for a ReMakeROS project
#   under the Debian standards. It acquires all the information necessary
#   from the defined ROS packages, meta-packages, or stacks. For each of
#   them, the build dependencies are evaluated and passed into the Debian
#   source packaging macro remake_distribute_deb(). The distribution name
#   itself is obtained by combining ${ROS_DISTRIBUTION} and the specified
#   name of the Debian distribution. Further, the macro takes care of passing
#   ${ROS_DISTRIBUTION} along with the default variables to the configuration
#   stage of the source package distribution. See ReMakeDistribute for
#   further information.
#   \optional[value] DISTRIBUTION:distribution The name of the Debian
#     distribution for which the packages should be built, defaults to the
#     output of lsb_release.
#   \optional[list] arg An optional list of additional arguments which shall
#     be passed to remake_distribute_deb().
macro(remake_ros_distribute_deb)
  remake_arguments(PREFIX ros_ VAR DISTRIBUTION ARGN args ${ARGN})
  execute_process(COMMAND lsb_release -c -s
    OUTPUT_VARIABLE ros_release OUTPUT_STRIP_TRAILING_WHITESPACE)
  remake_set(ros_distribution SELF DEFAULT ${ros_release})

  remake_ros()

  remake_project_get(ROS_PACKAGES OUTPUT ros_packages)
  remake_unset(ros_dependencies ros_extra_build_deps)
  foreach(ros_package ${ros_packages})
    remake_ros_package_get(${ros_package} EXTERNAL_BUILD_DEPENDS
      OUTPUT ros_depends)
    remake_list_push(ros_dependencies ${ros_depends})
    remake_ros_package_get(${ros_package} EXTERNAL_RUN_DEPENDS
      OUTPUT ros_depends)
    remake_list_push(ros_dependencies ${ros_depends})
    remake_ros_package_get(${ros_package} EXTRA_BUILD_DEPENDS
      OUTPUT ros_extra_depends)
    remake_list_push(ros_extra_build_deps ${ros_extra_depends})
    remake_ros_package_get(${ros_package} EXTRA_RUN_DEPENDS
      OUTPUT ros_extra_depends)
    remake_list_push(ros_extra_build_deps ${ros_extra_depends})
  endforeach(ros_package)

  remake_list_remove_duplicates(ros_dependencies)
  remake_list_remove_duplicates(ros_extra_build_deps)

  remake_unset(ros_build_deps)
  foreach(ros_build_dep ${ros_dependencies})
    remake_var_name(ros_var ROS ${ros_build_dep} PATH)
    remake_set(ros_manifest ${${ros_var}}/${REMAKE_ROS_PACKAGE_MANIFEST})

    string(REGEX REPLACE "_" "-" ros_build_dep ${ros_build_dep})
    remake_debian_find_package(
      ros-${ROS_DISTRIBUTION}-${ros_build_dep}
      CONTAINS ${ros_manifest}
      OUTPUT ros_build_dep)

    remake_list_push(ros_build_deps ${ros_build_dep})
  endforeach(ros_build_dep)

  remake_list_remove_duplicates(ros_build_deps)

  remake_distribute_deb(
    DISTRIBUTION ${ros_distribution}
    ALIAS ${ros_distribution}+${ROS_DISTRIBUTION}
    DEPENDS ${ros_build_deps} ${ros_extra_build_deps}
    PASS CMAKE_BUILD_TYPE CMAKE_INSTALL_PREFIX CMAKE_INSTALL_RPATH
      ROS_DISTRIBUTION
    ${ros_args})
endmacro(remake_ros_distribute_deb)
