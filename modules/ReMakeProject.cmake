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

include(ReMakeFile)
include(ReMakeComponent)

include(ReMakePrivate)

### \brief ReMake project macros
#   The ReMake project macros are required by most processing macros in
#   ReMake. They maintain the environment necessary for initializing default
#   values throughout the modules, thus introducing convenience and
#   conventions into ReMake's naming schemes.
#
#   \variable REMAKE_PROJECT_NAME The descriptive name of the project.
#   \variable REMAKE_PROJECT_FILENAME The filename representation of the
#     project name as used by ReMakePack, for instance.
#   \variable REMAKE_PROJECT_EPOCH The epoch version number of the project.
#   \variable REMAKE_PROJECT_MAJOR The major version number of the project.
#   \variable REMAKE_PROJECT_MINOR The minor version number of the project.
#   \variable REMAKE_PROJECT_PATCH The patch version number of the project.
#   \variable REMAKE_PROJECT_REVISION The revision string of the project,
#     for instance, alpha, beta, unstable, or stable.
#   \variable REMAKE_PROJECT_VERSION The fully qualified version string
#     of the project, concatenated from epoch, major, minor, and patch version.
#   \variable REMAKE_PROJECT_FILENAME_VERSION The version string of the
#     project in filename format, concatenated from major, minor, and patch
#     version.
#   \variable REMAKE_PROJECT_SUMMARY The short project summary.
#   \variable REMAKE_PROJECT_ADMIN The name of the project administrator,
#     i.e., the project author named first.
#   \variable REMAKE_PROJECT_AUTHORS The comma-separated list of project
#     authors.
#   \variable REMAKE_PROJECT_CONTACT The contact to the project maintainer,
#     usually a valid e-mail address.
#   \variable REMAKE_PROJECT_HOME The URL pointing to the project homepage,
#     where users may find further documentation and bug tracking facilities.
#   \variable REMAKE_PROJECT_LICENSE The license specified in the project's
#     copyleft/copyright agreement.
#   \variable REMAKE_PROJECT_COMPONENT The project's default install component.
#     See ReMakeComponent for details.
#   \variable REMAKE_PROJECT_README The name of the readme file that will be
#     shipped with the packaged project.
#   \variable REMAKE_PROJECT_COPYRIGHT The name of the copyright file that will
#     be shipped with the packaged project.
#   \variable REMAKE_PROJECT_TODO The name of the TODO file that will be
#     shipped with the packaged project.
#   \variable REMAKE_PROJECT_CHANGELOG The name of the changelog file that will
#     be shipped with the packaged project.
#   \variable REMAKE_PROJECT_BUILD_SYSTEM The name of the system building the
#     project as indicated by ${CMAKE_SYSTEM_NAME}.
#   \variable REMAKE_PROJECT_BUILD_ARCH The architecture of the system building
#     the project as indicated by ${CMAKE_SYSTEM_PROCESSOR}.
#   \variable REMAKE_PROJECT_BUILD_TYPE The type of build for the project as
#     indicated by ${CMAKE_BUILD_TYPE}.
#   \variable REMAKE_PROJECT_SOURCE_DIR The directory containing the project
#     source tree.
#   \variable REMAKE_PROJECT_CONFIGURATION_DIR The directory containing the
#     project configuration files.
#   \variable REMAKE_PROJECT_MODULE_DIR The directory containing the project's
#     custom CMake modules.

if(NOT DEFINED REMAKE_PROJECT_CMAKE)
  remake_set(REMAKE_PROJECT_CMAKE ON)

  remake_set(REMAKE_PROJECT_CHANGELOG_TARGET project_changelog)
endif(NOT DEFINED REMAKE_PROJECT_CMAKE)

### \brief Define a ReMake project.
#   This macro initializes all the ReMake project variables from the
#   arguments provided or from default values. It should be the first ReMake
#   macro called in the project root's CMakeLists.txt file.
#   \required[value] name The name of the project to be defined,
#     a string value.
#   \optional[value] VERSION:version The version of the project, defaults to
#     0.1. Here, the macro expects a string value that reflects standard
#     versioning conventions, i.e. the version string is of the form
#     ${EPOCH}:${MAJOR}.${MINOR}.${PATCH}-${REVISION}. If the revision is
#     omitted from the string, the project's Subversion or Git revision is
#     used instead.
#   \optional[value] RELEASE:release The release of the project, defaults to
#     alpha. This value may contain a string describing the release status,
#     such as alpha, beta, unstable, or stable.
#   \required[value] SUMMARY:summary A short but descriptive project summary.
#     This summary is used in several places, including the packaging module.
#   \required[value] AUTHOR:name The name of the project author(s). Note that
#     several authors may be specified by providing several AUTHOR arguments.
#   \required[value] CONTACT:contact A contact to the project maintainer,
#     usually a valid e-mail address.
#   \optional[value] HOME:home A URL pointing to the project homepage, where
#     users may find further documentation and bug tracking facilities.
#   \optional[value] LICENSE:license The license specified in the project's
#     copyleft/copyright agreement, defaults to LGPL. Common values are GPL,
#     LGPL, MIT, BSD, naming just a few.
#   \optional[value] COMPONENT:component An optional and valid name of
#     the project's default install component for targets, defaults to
#     default. See ReMakeComponent for details.
#   \optional[value] FILENAME:name An optional and valid filename that is
#     used to initialize ${REMAKE_PROJECT_FILENAME}, defaults to the filename
#     conversion of the project name.
#   \optional[value] PREFIX:prefix The optional target prefix that is passed
#     to remake_project_prefix(), defaults to ${REMAKE_PROJECT_FILENAME}-.
#   \optional[value] INSTALL:dir The directory that shall be used as the
#     project's preset install prefix, defaults to /usr/local.
#   \optional[value] SOURCES:dir The directory containing the project
#     source tree, defaults to src.
#   \optional[value] CONFIGURATIONS:dir The directory containing the project
#     configuration files, defaults to conf.
#   \optional[value] MODULES:dir The directory containing the project's
#     custom CMake modules, defaults to modules.
#   \optional[value] README:file The name of the readme file that will be
#     shipped with the packaged project, defaults to README.
#   \optional[value] COPYRIGHT:file The name of the copyright file that will
#     be shipped with the packaged project, defaults to copyright.
#   \optional[value] TODO:file The name of the TODO file that will
#     be shipped with the project package, defaults to TODO.
#   \optional[value] CHANGELOG:file The optional name of the changelog
#     file that will be shipped with the packaged project, defaulting to
#     changelog. Note that if the changelog file does not exist, the macro
#     will attempt to define a target that automatically creates the
#     changelog from the project's Subversion or Git log. See ReMakeSVN
#     and ReMakeGit for details.
#   \optional[value] LIBRARY_DESTINATION:dir The destination directory of
#     the project libraries, defaulting to lib.
#   \optional[value] EXECUTABLE_DESTINATION:dir The destination directory of
#     the project executables, defaulting to bin.
#   \optional[value] PLUGIN_DESTINATION:dir The destination directory of
#     the project plugins, defaulting to lib/${REMAKE_PROJECT_FILENAME}.
#   \optional[value] SCRIPT_DESTINATION:dir The destination directory of
#     the project scripts, defaulting to bin.
#   \optional[value] FILE_DESTINATION:dir The destination directory of
#     the project files, defaulting to share/${REMAKE_PROJECT_FILENAME}.
#   \optional[value] CONFIGURATION_DESTINATION:dir The destination
#     directory of the project configuration files, defaulting to
#     /etc/${REMAKE_PROJECT_FILENAME}.
#   \optional[value] HEADER_DESTINATION:dir The destination
#     directory of the project development headers, defaulting to
#     include/${REMAKE_PROJECT_FILENAME}.
#   \optional[value] DOCUMENTATION_DESTINATION:dir The destination
#     directory of the project documentation, defaulting to
#     share/doc/${REMAKE_PROJECT_FILENAME}.
#   \optional[list] NOTES:glob An optional list of glob expressions that
#     are resolved in order to find additional notes to be installed
#     with the project manifest files.
#   \optional[value] EXTRA_C_FLAGS:flags An optional string containing
#     project-specific C-compiler flags which will be used to initialize
#     the cache variable ${CMAKE_C_FLAGS}.
#   \optional[value] EXTRA_CXX_FLAGS:flags An optional string containing
#     project-specific C++-compiler flags which will be used to initialize
#     the cache variable ${CMAKE_CXX_FLAGS}.
#   \optional[value] EXTRA_SHARED_LINKER_FLAGS:flags An optional string
#     containing project-specific shared library linker flags which will be
#     used to initialize the cache variable ${CMAKE_SHARED_LINKER_FLAGS}.
#   \optional[value] EXTRA_MODULE_LINKER_FLAGS:flags An optional string
#     containing project-specific module linker flags which will be
#     used to initialize the cache variable ${CMAKE_MODULE_LINKER_FLAGS}.
#   \optional[value] EXTRA_EXE_LINKER_FLAGS:flags An optional string
#     containing project-specific executable linker flags which will be
#     used to initialize the cache variable ${CMAKE_EXE_LINKER_FLAGS}.
macro(remake_project project_name)
  remake_arguments(PREFIX project_ VAR VERSION VAR RELEASE VAR SUMMARY
    VAR AUTHOR VAR CONTACT VAR HOME VAR LICENSE VAR FILENAME VAR PREFIX
    VAR COMPONENT VAR INSTALL VAR SOURCES VAR CONFIGURATIONS VAR MODULES
    VAR README VAR COPYRIGHT VAR TODO VAR CHANGELOG VAR LIBRARY_DESTINATION
    VAR EXECUTABLE_DESTINATION VAR PLUGIN_DESTINATION VAR SCRIPT_DESTINATION
    VAR FILE_DESTINATION VAR CONFIGURATION_DESTINATION VAR HEADER_DESTINATION
    VAR DOCUMENTATION_DESTINATION LIST NOTES LIST EXTRA_C_FLAGS
    LIST EXTRA_CXX_FLAGS LIST EXTRA_SHARED_LINKER_FLAGS
    LIST EXTRA_MODULE_LINKER_FLAGS LIST EXTRA_EXE_LINKER_FLAGS ${ARGN})
  remake_set(project_version SELF DEFAULT 0.1)
  remake_set(project_release SELF DEFAULT alpha)
  remake_set(project_install SELF DEFAULT /usr/local)
  remake_set(project_sources SELF DEFAULT src)
  remake_set(project_configurations SELF DEFAULT conf)
  remake_set(project_modules SELF DEFAULT modules)
  remake_set(project_readme SELF DEFAULT README)
  remake_set(project_copyright SELF DEFAULT copyright)
  remake_set(project_todo SELF DEFAULT TODO)
  remake_set(project_changelog SELF DEFAULT changelog)

  if(NOT project_summary)
    message(FATAL_ERROR "The project definition requires a summary!")
  endif(NOT project_summary)
  if(NOT project_author)
    message(FATAL_ERROR "The project definition requires an author!")
  endif(NOT project_author)
  if(NOT project_contact)
    message(FATAL_ERROR "The project definition requires a contact!")
  endif(NOT project_contact)
  remake_set(project_lisence SELF DEFAULT
    "GNU Lesser General Public License (LGPL)")

  remake_set(REMAKE_PROJECT_NAME ${project_name} CACHE INTERNAL
    "Name of the ReMake project.")

  remake_file_name(project_filename_conversion ${REMAKE_PROJECT_NAME})
  remake_set(project_filename SELF DEFAULT ${project_filename_conversion})
  remake_set(REMAKE_PROJECT_FILENAME ${project_filename})

  remake_set(project_library_destination SELF DEFAULT lib)
  remake_set(project_executable_destination SELF DEFAULT bin)
  remake_set(project_plugin_destination SELF
    DEFAULT lib/${REMAKE_PROJECT_FILENAME})
  remake_set(project_script_destination SELF DEFAULT bin)
  remake_set(project_file_destination SELF DEFAULT
    share/${REMAKE_PROJECT_FILENAME})
  remake_set(project_configuration_destination SELF DEFAULT
    /etc/${REMAKE_PROJECT_FILENAME})
  remake_set(project_header_destination SELF DEFAULT
    include/${REMAKE_PROJECT_FILENAME})
  remake_set(project_documentation_destination SELF DEFAULT
    share/doc/${REMAKE_PROJECT_FILENAME})

  remake_set(project_regex
    "^([0-9]*)[:]?([0-9]+)[.]?([0-9]*)[.]?([0-9]*)[-]?([0-9]*)$")
  string(REGEX REPLACE ${project_regex} "\\1" REMAKE_PROJECT_EPOCH
    ${project_version})
  string(REGEX REPLACE ${project_regex} "\\2" REMAKE_PROJECT_MAJOR
    ${project_version})
  string(REGEX REPLACE ${project_regex} "\\3" REMAKE_PROJECT_MINOR
    ${project_version})
  string(REGEX REPLACE ${project_regex} "\\4" REMAKE_PROJECT_PATCH
    ${project_version})
  string(REGEX REPLACE ${project_regex} "\\5" REMAKE_PROJECT_REVISION
    ${project_version})
  remake_set(REMAKE_PROJECT_EPOCH SELF DEFAULT 0)
  remake_set(REMAKE_PROJECT_MAJOR SELF DEFAULT 0)
  remake_set(REMAKE_PROJECT_MINOR SELF DEFAULT 0)
  remake_set(REMAKE_PROJECT_PATCH SELF DEFAULT 0)
  remake_svn_revision(project_svn_revision)
  remake_git_revision(project_git_revision)
  if(project_svn_revision)
    remake_set(REMAKE_PROJECT_REVISION SELF DEFAULT ${project_svn_revision})
  endif(project_svn_revision)
  if(project_git_revision)
    remake_set(REMAKE_PROJECT_REVISION SELF DEFAULT ${project_git_revision})
  endif(project_git_revision)
  remake_set(REMAKE_PROJECT_VERSION
    ${REMAKE_PROJECT_MAJOR}.${REMAKE_PROJECT_MINOR})
  if(REMAKE_PROJECT_PATCH)
    remake_set(REMAKE_PROJECT_VERSION
      ${REMAKE_PROJECT_VERSION}.${REMAKE_PROJECT_PATCH})
  endif(REMAKE_PROJECT_PATCH)
  if(REMAKE_PROJECT_REVISION)
    remake_set(REMAKE_PROJECT_VERSION
      ${REMAKE_PROJECT_VERSION}-${REMAKE_PROJECT_REVISION})
  endif(REMAKE_PROJECT_REVISION)
  remake_file_name(REMAKE_PROJECT_FILENAME_VERSION ${REMAKE_PROJECT_VERSION})
  if(REMAKE_PROJECT_EPOCH)
    remake_set(REMAKE_PROJECT_VERSION
      ${REMAKE_PROJECT_EPOCH}:${REMAKE_PROJECT_VERSION})
  endif(REMAKE_PROJECT_EPOCH)
  remake_set(REMAKE_PROJECT_RELEASE ${project_release})

  remake_set(REMAKE_PROJECT_SUMMARY ${project_summary})
  list(GET project_author 0 REMAKE_PROJECT_ADMIN)
  string(REPLACE ";" ", " REMAKE_PROJECT_AUTHORS "${project_author}")
  remake_set(REMAKE_PROJECT_CONTACT ${project_contact})
  remake_set(REMAKE_PROJECT_HOME ${project_home})
  remake_set(REMAKE_PROJECT_LICENSE ${project_license})
  remake_set(REMAKE_PROJECT_COMPONENT ${project_component} DEFAULT default)
  get_filename_component(REMAKE_PROJECT_README ${project_readme} ABSOLUTE)
  get_filename_component(REMAKE_PROJECT_COPYRIGHT ${project_copyright} ABSOLUTE)
  get_filename_component(REMAKE_PROJECT_TODO ${project_todo} ABSOLUTE)
  get_filename_component(REMAKE_PROJECT_CHANGELOG ${project_changelog} ABSOLUTE)

  remake_set(REMAKE_PROJECT_BUILD_SYSTEM ${CMAKE_SYSTEM_NAME})
  remake_set(REMAKE_PROJECT_BUILD_ARCH ${CMAKE_SYSTEM_PROCESSOR})
  remake_set(REMAKE_PROJECT_BUILD_TYPE ${CMAKE_BUILD_TYPE})

  get_filename_component(REMAKE_PROJECT_SOURCE_DIR ${project_sources} ABSOLUTE)
  get_filename_component(REMAKE_PROJECT_CONFIGURATION_DIR
    ${project_configurations} ABSOLUTE)
  get_filename_component(REMAKE_PROJECT_MODULE_DIR ${project_modules} ABSOLUTE)

  remake_set(CMAKE_INSTALL_PREFIX ${project_install} CACHE FORCE INIT)

  if(NOT DEFINED project_prefix)
    remake_set(project_prefix ${REMAKE_PROJECT_FILENAME}-)
  endif(NOT DEFINED project_prefix)
  remake_project_prefix(
    LIBRARY ${project_prefix}
    PLUGIN ${project_prefix}
    EXECUTABLE ${project_prefix}
    SCRIPT ${project_prefix})

  remake_project_set(COMPONENTS CACHE INTERNAL
    "List of install components defined by the project.")

  remake_project_set(FILENAME ${project_filename}
    CACHE INTERNAL "Filename defined for the entire project.")
  remake_project_set(PREFIX ${project_prefix}
    CACHE INTERNAL "Prefix defined for the entire project.")
  remake_project_set(INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}
    CACHE INTERNAL "Install path prefix of the entire project.")

  remake_project_set(LIBRARY_DESTINATION ${project_library_destination}
    CACHE STRING "Install destination of project libraries.")
  remake_project_set(EXECUTABLE_DESTINATION ${project_executable_destination}
    CACHE STRING "Install destination of project executables.")
  remake_project_set(PLUGIN_DESTINATION ${project_plugin_destination}
    CACHE STRING "Install destination of project plugins.")
  remake_project_set(SCRIPT_DESTINATION ${project_script_destination}
    CACHE STRING "Install destination of project scripts.")
  remake_project_set(FILE_DESTINATION ${project_file_destination}
    CACHE STRING "Install destination of project files.")
  remake_project_set(CONFIGURATION_DESTINATION
    ${project_configuration_destination}
    CACHE STRING "Install destination of configuration files.")
  remake_project_set(HEADER_DESTINATION ${project_header_destination}
    CACHE STRING "Install destination of project development headers.")
  remake_project_set(DOCUMENTATION_DESTINATION
    ${project_documentation_destination}
    CACHE STRING "Install destination of project documentation.")

  remake_project_set(EXTRA_C_FLAGS ${project_extra_c_flags}
    CACHE STRING "Extra flags used by the compiler to build the project.")
  remake_project_set(EXTRA_CXX_FLAGS ${project_extra_cxx_flags}
    CACHE STRING "Extra flags used by the compiler to build the project.")
  remake_project_set(EXTRA_SHARED_LINKER_FLAGS
    ${project_extra_shared_linker_flags} CACHE STRING
    "Extra flags used by the linker during the creation of project dll's.")
  remake_project_set(EXTRA_MODULE_LINKER_FLAGS
    ${project_extra_module_linker_flags} CACHE STRING
    "Extra flags used by the linker during the creation of project modules.")
  remake_project_set(EXTRA_EXE_LINKER_FLAGS
    ${project_extra_exe_linker_flags} CACHE STRING
    "Extra flags used by the linker during the creation of project executables.")

  message(STATUS "Project: ${REMAKE_PROJECT_NAME} "
    "version ${REMAKE_PROJECT_VERSION}, "
    "release ${REMAKE_PROJECT_RELEASE}")
  message(STATUS "Summary: ${REMAKE_PROJECT_SUMMARY}")
  message(STATUS "Author(s): ${REMAKE_PROJECT_AUTHORS}")
  message(STATUS "Contact: <${REMAKE_PROJECT_CONTACT}>")
  if(REMAKE_PROJECT_HOME)
    message(STATUS "Home: ${REMAKE_PROJECT_HOME}")
  endif(REMAKE_PROJECT_HOME)
  message(STATUS "License: ${REMAKE_PROJECT_LICENSE}")
  if(CMAKE_TOOLCHAIN_FILE)
    get_filename_component(project_toolchain ${CMAKE_TOOLCHAIN_FILE} NAME_WE)
    message(STATUS "Toolchain: ${project_toolchain}")
  endif(CMAKE_TOOLCHAIN_FILE)

  remake_component(${REMAKE_PROJECT_COMPONENT} DEFAULT)
  remake_component_switch(${REMAKE_PROJECT_COMPONENT})

  if(EXISTS ${REMAKE_PROJECT_CHANGELOG})
    remake_file_configure(${project_changelog} OUTPUT REMAKE_PROJECT_CHANGELOG)
  else(EXISTS ${REMAKE_PROJECT_CHANGELOG})
    if(project_svn_revision)
      remake_svn_log(${project_changelog} OUTPUT REMAKE_PROJECT_CHANGELOG
        TARGET ${REMAKE_PROJECT_CHANGELOG_TARGET})
    endif(project_svn_revision)
    if(project_git_revision)
      remake_git_log(${project_changelog} OUTPUT REMAKE_PROJECT_CHANGELOG
        TARGET ${REMAKE_PROJECT_CHANGELOG_TARGET})
    endif(project_git_revision)
  endif(EXISTS ${REMAKE_PROJECT_CHANGELOG})
  remake_set(project_changelog ${REMAKE_PROJECT_CHANGELOG})

  remake_file_configure(${REMAKE_PROJECT_README} OUTPUT project_readme)
  remake_file_configure(${REMAKE_PROJECT_COPYRIGHT} OUTPUT project_copyright)
  if(REMAKE_PROJECT_TODO)
    remake_file_configure(${REMAKE_PROJECT_TODO} OUTPUT project_todo)
  endif(REMAKE_PROJECT_TODO)
  if(project_notes)
    remake_file_configure(${project_notes} OUTPUT project_notes)
  endif(project_notes)
  remake_component_install(FILES ${project_readme} ${project_copyright}
      ${project_todo} ${project_changelog} ${project_notes}
    DESTINATION share/doc/${REMAKE_PROJECT_FILENAME})
  if(project_copyright)
    remake_file_read(REMAKE_PROJECT_LICENSE_TEXT ${project_copyright})
  endif(project_copyright)

  project(${REMAKE_PROJECT_NAME})

  if(EXISTS ${REMAKE_PROJECT_MODULE_DIR})
    remake_add_modules(${REMAKE_PROJECT_MODULE_DIR}/*.cmake)
  endif(EXISTS ${REMAKE_PROJECT_MODULE_DIR})
  if(EXISTS ${REMAKE_PROJECT_SOURCE_DIR})
    string(REGEX REPLACE "^${CMAKE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}"
      REMAKE_PROJECT_BINARY_DIR ${REMAKE_PROJECT_SOURCE_DIR})
    remake_add_directories(${REMAKE_PROJECT_SOURCE_DIR})
  endif(EXISTS ${REMAKE_PROJECT_SOURCE_DIR})
  if(EXISTS ${REMAKE_PROJECT_CONFIGURATION_DIR})
    remake_add_directories(${REMAKE_PROJECT_CONFIGURATION_DIR})
  endif(EXISTS ${REMAKE_PROJECT_CONFIGURATION_DIR})

  remake_project_get(EXTRA_C_FLAGS)
  if(EXTRA_C_FLAGS)
    remake_set(CMAKE_C_FLAGS "${EXTRA_C_FLAGS} ${CMAKE_C_FLAGS}"
      CACHE FORCE INIT)
  endif(EXTRA_C_FLAGS)
  remake_project_get(EXTRA_CXX_FLAGS)
  if(EXTRA_CXX_FLAGS)
    remake_set(CMAKE_CXX_FLAGS "${EXTRA_CXX_FLAGS} ${CMAKE_CXX_FLAGS}"
      CACHE FORCE INIT)
  endif(EXTRA_CXX_FLAGS)
  remake_project_get(EXTRA_SHARED_LINKER_FLAGS)
  if(EXTRA_SHARED_LINKER_FLAGS)
    remake_set(CMAKE_SHARED_LINKER_FLAGS
      "${EXTRA_SHARED_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS}"
      CACHE FORCE INIT)
  endif(EXTRA_SHARED_LINKER_FLAGS)
  remake_project_get(EXTRA_MODULE_LINKER_FLAGS)
  if(EXTRA_MODULE_LINKER_FLAGS)
    remake_set(CMAKE_MODULE_LINKER_FLAGS
      "${EXTRA_MODULE_LINKER_FLAGS} ${CMAKE_MODULE_LINKER_FLAGS}"
      CACHE FORCE INIT)
  endif(EXTRA_MODULE_LINKER_FLAGS)
  remake_project_get(EXTRA_EXE_LINKER_FLAGS)
  if(EXTRA_EXE_LINKER_FLAGS)
    remake_set(CMAKE_EXE_LINKER_FLAGS
      "${EXTRA_EXE_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}"
      CACHE FORCE INIT)
  endif(EXTRA_EXE_LINKER_FLAGS)
endmacro(remake_project)

### \brief Define the value of a ReMake project variable.
#   This macro defines a project variable matching the ReMake naming
#   conventions. The variable name is automatically prefixed with an
#   upper-case conversion of the project name. Thus, variables may appear in
#   the cache as ${PROJECT_NAME}_${VAR_NAME}. Additional arguments are passed
#   on to remake_set().
#   \required[value] variable The name of the project variable to be defined.
#   \optional[list] arg The arguments to be passed on to remake_set(). See
#     ReMakePrivate for details.
macro(remake_project_set project_var)
  remake_var_name(project_global_var ${REMAKE_PROJECT_NAME} ${project_var})
  remake_set(${project_global_var} ${ARGN})
endmacro(remake_project_set)

### \brief Undefine the value of a ReMake project variable.
#   This macro undefines a project variable which has been defined by
#   remake_project_set(). The variable name is automatically prefixed with an
#   upper-case conversion of the project name found in the cache. Additional
#   arguments are passed on to remake_unset().
#   \required[value] variable The name of the project variable to be undefined.
#   \optional[list] arg The arguments to be passed on to remake_unset(). See
#     ReMakePrivate for details.
macro(remake_project_unset project_var)
  remake_var_name(project_global_var ${REMAKE_PROJECT_NAME} ${project_var})
  remake_unset(${project_global_var} ${ARGN})
endmacro(remake_project_unset)

### \brief Retrieve the value of a ReMake project variable.
#   This macro retrieves a project variable matching the ReMake naming
#   conventions. Specifically, variables named ${PROJECT_NAME}_${VAR_NAME}
#   can be found by passing ${VAR_NAME} to this macro. By default, the macro
#   defines an output variable named ${VAR_NAME} which will be assigned the
#   value of the queried project variable.
#   \required[value] variable The name of the project variable to be retrieved.
#   \optional[option] DESTINATION This option tells the macro to treat the
#     project variable as install destination. If the destination contains
#     a relative install path, it will be automatically prefixed by
#     ${CMAKE_INSTALL_PREFIX}. See the CMake documentation for details.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried project variable.
macro(remake_project_get project_var)
  remake_arguments(PREFIX project_ OPTION DESTINATION VAR OUTPUT ${ARGN})

  remake_var_name(project_global_var ${REMAKE_PROJECT_NAME} ${project_var})
  remake_set(project_global ${${project_global_var}})
  remake_set(project_output SELF DEFAULT ${project_var})

  if(project_destination)
    if(project_global)
      if(NOT IS_ABSOLUTE ${project_global})
        get_filename_component(project_global
          ${CMAKE_INSTALL_PREFIX}/${project_global} ABSOLUTE)
      endif(NOT IS_ABSOLUTE ${project_global})
    else(project_global)
      remake_set(project_global ${CMAKE_INSTALL_PREFIX})
    endif(project_global)
  endif(project_destination)

  remake_set(${project_output} ${project_global})
endmacro(remake_project_get)

### \brief Define a ReMake project option.
#   This macro provides a ReMake project option for the user to select as ON
#   or OFF. The option name is automatically converted into a ReMake project
#   variable.
#   \required[value] variable The name of the option variable that is
#     converted to match ReMake naming conventions for variables.
#   \required[value] description A description string that explains the
#     purpose of this option.
#   \required[value] default The default value of the project option, will
#     be used for initialization.
macro(remake_project_option project_option project_description project_default)
  remake_project_set(${project_option} ${project_default} CACHE BOOL
    "Compile with ${project_description}.")

  remake_project_get(${project_option})
  if(${project_option})
    message(STATUS "Compiling with ${project_description}.")
  else(${project_option})
    message(STATUS "NOT compiling with ${project_description}.")
  endif(${project_option})
endmacro(remake_project_option)

### \brief Define the ReMake project prefix for target output.
#   This macro initializes the ReMake project prefix for libraries, plugins,
#   and executables produced by all targets. It gets invoked by
#   remake_project() and needs not be called directly from a CMakeLists.txt
#   file. Note that undefined prefixes default to ${REMAKE_PROJECT_FILENAME}-.
#   \optional[value] LIBRARY:prefix The prefix that is used for producing
#     libraries, extending library names to ${PREFIX}${LIB_NAME}.
#   \optional[value] PLUGIN:prefix The prefix that is used for producing
#     plugins, extending plugin names to ${PREFIX}${PLUGIN_NAME}.
#   \optional[value] EXECUTABLE:prefix The prefix that is used for producing
#     executables, extending executable names to ${PREFIX}${EXECUTABLE_NAME}.
#   \optional[value] SCRIPT:prefix The prefix that is used for producing
#     scripts, extending script names to ${PREFIX}${SCRIPT_NAME}.
macro(remake_project_prefix)
  remake_arguments(PREFIX project_ VAR LIBRARY VAR PLUGIN VAR EXECUTABLE
    VAR SCRIPT ${ARGN})

  remake_project_set(LIBRARY_PREFIX FROM project_library
    DEFAULT ${REMAKE_PROJECT_FILENAME}-
    CACHE STRING "Name prefix of project libraries.")
  remake_project_set(PLUGIN_PREFIX FROM project_plugin
    DEFAULT ${REMAKE_PROJECT_FILENAME}-
    CACHE STRING "Name prefix of project plugins.")
  remake_project_set(EXECUTABLE_PREFIX FROM project_executable
    DEFAULT ${REMAKE_PROJECT_FILENAME}-
    CACHE STRING "Name prefix of project executables.")
  remake_project_set(SCRIPT_PREFIX FROM project_script
    DEFAULT ${REMAKE_PROJECT_FILENAME}-
    CACHE STRING "Name prefix of project scripts.")
endmacro(remake_project_prefix)

### \brief Create the ReMake project configuration header.
#   This macro creates the project configuration header, commonly named
#   config.h, by modifying the contents of a given header template based on
#   ReMake project settings through remake_file_configure(). In addition,
#   the macro initializes ${REMAKE_PROJECT_HEADER} with the configuration
#   output file and adds the header's location to the include path of all
#   project targets. See ReMakeFile for the correct usage of file
#   configuration.
#   \required[value] source The source template of the header to be configured
#     with the ReMake project settings.
#   \optional[option] INSTALL This option tells the macro to invoke
#     remake_add_headers() for the generated project configuration header.
macro(remake_project_header project_source)
  remake_arguments(PREFIX project_ OPTION INSTALL ${ARGN})

  if(NOT REMAKE_PROJECT_HEADER)
    remake_file_configure(${project_source} OUTPUT REMAKE_PROJECT_HEADER
      ESCAPE_QUOTES ESCAPE_NEWLINES)
    if(project_install)
      remake_add_headers(${REMAKE_PROJECT_HEADER})
    endif(project_install)

    get_filename_component(project_path ${REMAKE_PROJECT_HEADER} PATH)
    include_directories(${project_path})
  else(NOT REMAKE_PROJECT_HEADER)
    message(FATAL_ERROR "Duplicate project configuration header!")
  endif(NOT REMAKE_PROJECT_HEADER)
endmacro(remake_project_header)
