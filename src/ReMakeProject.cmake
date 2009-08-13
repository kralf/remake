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

include(ReMakeFile)

include(ReMakePrivate)

### \brief ReMake project macros
#   The ReMake project macros are required by most processing macros in 
#   ReMake. They maintain the environment necessary for initializing default 
#   values throughout the modules, thus introducing convenience and
#   conventions into ReMake's naming schemes.

remake_set(REMAKE_PROJECT_CHANGELOG_TARGET project_changelog)

### \brief Define a ReMake project.
#   This macro initializes all the ReMake project variables from the
#   arguments provided or from default values. It should be the first ReMake
#   macro called in the project root's CMakeLists.txt file.
#   \required[value] name The name of the project to be defined,
#     a string value.
#   \required[value] version The version of the project. Here, the macro 
#     expects a string value that reflects standard versioning conventions, 
#     i.e. the version string is of the form ${MAJOR}.${MINOR}.${PATCH}.
#     If the patch version is omitted from the string, the project's Subversion
#     revision is used instead.
#   \required[value] release The release of the project. This value may
#     contain a string describing the release status, such as alpha or beta.
#   \required[value] summary A short but descriptive project summary. This
#     summary is used in several places, including the packaging module.
#   \required[value] author The name of the project author.
#   \required[value] contact A contact to the project responsibles, usually
#     a valid e-mail address.
#   \required[value] home A URL pointing to the project homepage, where
#     users may find further documentation and bug tracking facilities.
#   \required[value] license The license specified in the project's 
#     copyleft/copyright agreement. Common values are GPL, LGPL, MIT, BSD, 
#     naming just a few.
#   \optional[value] INSTALL:dir The directory that shall be used as the 
#     project's preset install prefix, defaults to /usr/local.
#   \optional[value] SOURCES:dir The directory containing the project
#     source tree, defaults to src.
#   \optional[value] README:file The name of the readme file that will be
#     shipped with the project package, defaults to README.
#   \optional[value] COPYRIGHT:file The name of the copyright file that will 
#     be shipped with the project package, defaults to copyright.
macro(remake_project project_name project_version project_release 
  project_summary project_author project_contact project_home project_license)
  remake_arguments(PREFIX project_ VAR INSTALL VAR SOURCES VAR CONFIGURATIONS 
    VAR README VAR COPYRIGHT ${ARGN})

  remake_set(REMAKE_PROJECT_NAME ${project_name})
  remake_file_name(REMAKE_PROJECT_FILENAME ${REMAKE_PROJECT_NAME})

  remake_set(project_regex "^([0-9]+)[.]?([0-9]*)[.]?([0-9]*)$")
  string(REGEX REPLACE ${project_regex} "\\1" REMAKE_PROJECT_MAJOR 
    ${project_version})
  string(REGEX REPLACE ${project_regex} "\\2" REMAKE_PROJECT_MINOR 
    ${project_version})
  string(REGEX REPLACE ${project_regex} "\\3" REMAKE_PROJECT_PATCH 
    ${project_version})
  remake_set(REMAKE_PROJECT_MAJOR SELF DEFAULT 0)
  remake_set(REMAKE_PROJECT_MINOR SELF DEFAULT 0)
  remake_svn_revision(project_revision)
  remake_set(REMAKE_PROJECT_PATCH SELF DEFAULT ${project_revision})
  remake_set(REMAKE_PROJECT_VERSION 
    ${REMAKE_PROJECT_MAJOR}.${REMAKE_PROJECT_MINOR}.${REMAKE_PROJECT_PATCH})
  remake_set(REMAKE_PROJECT_RELEASE ${project_release})

  remake_set(REMAKE_PROJECT_SUMMARY ${project_summary})
  remake_set(REMAKE_PROJECT_AUTHOR ${project_author})
  remake_set(REMAKE_PROJECT_CONTACT ${project_contact})
  remake_set(REMAKE_PROJECT_HOME ${project_home})
  remake_set(REMAKE_PROJECT_LICENSE ${project_license})
  remake_set(REMAKE_PROJECT_README ${project_readme} DEFAULT README)
  remake_set(REMAKE_PROJECT_COPYRIGHT ${project_copyright} DEFAULT copyright)
  remake_set(REMAKE_PROJECT_CHANGELOG changelog)

  remake_set(REMAKE_PROJECT_BUILD_SYSTEM ${CMAKE_SYSTEM_NAME})
  remake_set(REMAKE_PROJECT_BUILD_ARCH ${CMAKE_SYSTEM_PROCESSOR})
  remake_set(REMAKE_PROJECT_BUILD_TYPE ${CMAKE_BUILD_TYPE})

  if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    remake_set(CMAKE_INSTALL_PREFIX ${project_install} DEFAULT /usr/local 
      CACHE PATH "Install path prefix, prepended onto install directories."
      FORCE)
  endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

  remake_project_set(LIBRARY_DESTINATION lib CACHE PATH 
    "Install destination of project libraries.")
  remake_project_set(EXECUTABLE_DESTINATION bin CACHE PATH 
    "Install destination of project executables.")
  remake_project_set(PLUGIN_DESTINATION 
    lib/${REMAKE_PROJECT_FILENAME} CACHE PATH
    "Install destination of project plugins.")
  remake_project_set(SCRIPT_DESTINATION bin CACHE PATH
    "Install destination of project scripts.")
  remake_project_set(FILE_DESTINATION share/${REMAKE_PROJECT_FILENAME} 
    CACHE PATH "Install destination of project files.")
  remake_project_set(CONFIGURATION_DESTINATION /etc/${REMAKE_PROJECT_FILENAME}
    CACHE PATH "Install destination of configuration files.")
  remake_project_set(HEADER_DESTINATION include/${REMAKE_PROJECT_FILENAME} 
    CACHE PATH "Install destination of project development headers.")

  message(STATUS "Project: ${REMAKE_PROJECT_NAME} "
    "version ${REMAKE_PROJECT_VERSION}, "
    "release ${REMAKE_PROJECT_RELEASE}")
  message(STATUS "Summary: ${REMAKE_PROJECT_SUMMARY}")
  message(STATUS "Author: ${REMAKE_PROJECT_AUTHOR} (${REMAKE_PROJECT_CONTACT})")
  message(STATUS "Home: ${REMAKE_PROJECT_HOME}")
  message(STATUS "License: ${REMAKE_PROJECT_LICENSE}")

  project(${REMAKE_PROJECT_NAME})

  remake_set(REMAKE_PROJECT_SOURCE_DIR ${project_sources} DEFAULT src)
  if(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_SOURCE_DIR})
    add_subdirectory(${REMAKE_PROJECT_SOURCE_DIR})
  endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_SOURCE_DIR})

  remake_set(REMAKE_PROJECT_CONFIGURATION_DIR ${project_configurations}
    DEFAULT conf)
  if(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_CONFIGURATION_DIR})
    add_subdirectory(${REMAKE_PROJECT_CONFIGURATION_DIR})
  endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_CONFIGURATION_DIR})

  remake_svn_log(${REMAKE_PROJECT_CHANGELOG})
  remake_target(${REMAKE_PROJECT_CHANGELOG_TARGET} ALL
    DEPENDS ${REMAKE_PROJECT_CHANGELOG})

  remake_file_configure(${REMAKE_PROJECT_README} OUTPUT project_readme)
  remake_file_configure(${REMAKE_PROJECT_COPYRIGHT} OUTPUT project_copyright)
  install(FILES ${project_readme} ${project_copyright} ${project_changelog}
    DESTINATION share/doc/${REMAKE_PROJECT_FILENAME}
    COMPONENT default)
endmacro(remake_project)

### \brief Define the value of a ReMake project variable.
#   This macro defines a variable matching the ReMake naming conventions. 
#   The variable name is automatically prefixed with an upper-case 
#   conversion of the project name. Thus, variables may appear in the cache 
#   as ${PROJECT_NAME}_${VAR_NAME}. Additional arguments are passed on to 
#   CMake's set() macro.
#   \required[value] variable The name of the project variable to be defined.
#   \optional[list] arg The arguments to be passed on to CMake's set() macro.
macro(remake_project_set project_var)
  remake_var_name(project_global_var ${REMAKE_PROJECT_NAME} ${project_var})
  remake_set(${project_global_var} ${ARGN})
endmacro(remake_project_set)

### \brief Retrieve the value of a ReMake project variable.
#   This macro retrieves a variable matching the ReMake naming conventions.
#   Specifically, variables named ${PROJECT_NAME}_${VAR_NAME} can be found
#   by passing ${VAR_NAME} to this macro. By default, the macro defines an
#   output variable named ${VAR_NAME} which will be assigned the value of the
#   queried project variable.
#   \required[value] variable The name of the project variable to be retrieved.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried project variable.
macro(remake_project_get project_var)
  remake_arguments(PREFIX project_ VAR OUTPUT ${ARGN})

  remake_var_name(project_global_var ${REMAKE_PROJECT_NAME} ${project_var})
  if(project_output)
    remake_set(${project_output} FROM ${project_global_var})
  else(project_output)
    remake_set(${project_var} FROM ${project_global_var})
  endif(project_output)
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
#   The macro initializes the ReMake project prefix for libaries, plugins, 
#   executables, scripts, and regular files produced by all targets. 
#   With an empty argument list, this prefix defaults to the lower-case 
#   project name followed by a score.
#   \optional[value] LIBRARY:prefix The prefix that is used for producing
#     libraries, extending the library name to ${PREFIX}${LIB_NAME}.
#   \optional[value] PLUGIN:prefix The prefix that is used for producing
#     plugins, extending the plugin name to ${PREFIX}${PLUGIN_NAME}.
#   \optional[value] EXECUTABLE:prefix The prefix that is used for producing
#     executables, extending the executable name to ${PREFIX}${EXECUTABLE_NAME}.
#   \optional[value] SCRIPT:prefix The prefix that is used for producing
#     scripts, extending the script name to ${PREFIX}${SCRIPT_NAME}.
#   \optional[value] FILE:prefix The prefix that is used for producing regular
#     files, extending the file name to ${PREFIX}${FILE_NAME}.
macro(remake_project_prefix)
  remake_arguments(PREFIX project_ VAR LIBRARY VAR PLUGIN VAR EXECUTABLE 
    VAR SCRIPT VAR FILE ${ARGN})

  remake_set(REMAKE_LIBRARY_PREFIX ${project_library} 
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_PLUGIN_PREFIX ${project_plugin} 
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_EXECUTABLE_PREFIX ${project_executable}
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_SCRIPT_PREFIX ${project_script}
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_FILE_PREFIX ${project_file}
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
endmacro(remake_project_prefix)

### \brief Create the ReMake project configuration header.
#   This macro creates the project configuration header, commonly named 
#   config.h, by modifying the contents of a given header source based on
#   ReMake project settings. In addition, the macro adds the output location
#   of the project header to the include path of all project targets.
#   For detailed documentation on file configuration, see ReMakeFile.
#   \required[value] source The source of the header to be configured using
#     the ReMake project settings.
#   \optional[value] HEADER:header The optional name of the output header that 
#     is generated by this macro, defaults to config.h.
macro(remake_project_header project_source)
  remake_arguments(PREFIX project_ VAR HEADER ${ARGN})
  remake_assign(project_header SELF DEFAULT config.h)

  if(NOT REMAKE_PROJECT_HEADER)
    remake_set(REMAKE_PROJECT_HEADER 
      ${CMAKE_BINARY_DIR}/include/${project_header})
    remake_file_configure(${CMAKE_CURRENT_SOURCE_DIR}/${project_source} 
      ${REMAKE_PROJECT_HEADER})
    include_directories(${CMAKE_BINARY_DIR}/include)
  else(NOT REMAKE_PROJECT_HEADER)
    message(FATAL_ERROR "Duplicate project configuration header!") 
  endif(NOT REMAKE_PROJECT_HEADER)
endmacro(remake_project_header)
