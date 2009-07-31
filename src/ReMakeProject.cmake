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

# Define the ReMake project.
macro(remake_project name version release summary vendor contact home license)
  remake_arguments(VAR INSTALL VAR SOURCES ${ARGN})

  remake_set(REMAKE_PROJECT_NAME ${name})
  remake_file_name(${REMAKE_PROJECT_NAME} REMAKE_PROJECT_FILENAME)

  remake_set(regex_replace "^([0-9]+)[.]?([0-9]*)[.]?([0-9]*)$")
  string(REGEX REPLACE ${regex_replace} "\\1" REMAKE_PROJECT_MAJOR ${version})
  string(REGEX REPLACE ${regex_replace} "\\2" REMAKE_PROJECT_MINOR ${version})
  string(REGEX REPLACE ${regex_replace} "\\3" REMAKE_PROJECT_PATCH ${version})
  remake_set(REMAKE_PROJECT_MAJOR DEFAULT 0)
  remake_set(REMAKE_PROJECT_MINOR DEFAULT 0)
  remake_set(REMAKE_PROJECT_PATCH DEFAULT 0)
  remake_set(REMAKE_PROJECT_VERSION 
    ${REMAKE_PROJECT_MAJOR}.${REMAKE_PROJECT_MINOR}.${REMAKE_PROJECT_PATCH})
  remake_set(REMAKE_PROJECT_RELEASE ${release})

  remake_set(REMAKE_PROJECT_SUMMARY ${summary})
  remake_set(REMAKE_PROJECT_VENDOR ${vendor})
  remake_set(REMAKE_PROJECT_CONTACT ${contact})
  remake_set(REMAKE_PROJECT_HOME ${home})
  remake_set(REMAKE_PROJECT_LICENSE ${license})

  remake_set(REMAKE_PROJECT_BUILD_SYSTEM ${CMAKE_SYSTEM_NAME})
  remake_set(REMAKE_PROJECT_BUILD_ARCH ${CMAKE_SYSTEM_PROCESSOR})
  remake_set(REMAKE_PROJECT_BUILD_TYPE ${CMAKE_BUILD_TYPE})

  if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    remake_set(CMAKE_INSTALL_PREFIX FROM INSTALL DEFAULT /usr/local CACHE PATH 
      "Install path prefix, prepended onto install directories." FORCE)
  endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

  remake_project_set(LIBRARY_DESTINATION lib CACHE PATH 
    "Install destination of project libraries.")
  remake_project_set(EXECUTABLE_DESTINATION bin CACHE PATH 
    "Install destination of project executables.")
  remake_project_set(PROJECT_PLUGIN_DESTINATION 
    lib/${REMAKE_PROJECT_FILENAME} CACHE PATH
    "Install destination of project plugins.")
  remake_project_set(SCRIPT_DESTINATION bin CACHE PATH
    "Install destination of project scripts.")
  remake_project_set(FILE_DESTINATION share/${REMAKE_PROJECT_FILENAME} 
    CACHE PATH "Install destination of project files.")
  remake_project_set(HEADER_DESTINATION include/${REMAKE_PROJECT_FILENAME} 
    CACHE PATH "Install destination of project development headers.")

  message(STATUS "Project: ${REMAKE_PROJECT_NAME} "
    "version ${REMAKE_PROJECT_VERSION}, "
    "release ${REMAKE_PROJECT_RELEASE}")
  message(STATUS "Summary: ${REMAKE_PROJECT_SUMMARY}")
  message(STATUS "Vendor: ${REMAKE_PROJECT_VENDOR} (${REMAKE_PROJECT_CONTACT})")
  message(STATUS "Home: ${REMAKE_PROJECT_HOME}")
  message(STATUS "License: ${REMAKE_PROJECT_LICENSE}")

  project(${REMAKE_PROJECT_NAME})

  remake_set(REMAKE_PROJECT_SOURCE_DIR FROM SOURCES DEFAULT src)
  if(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_SOURCE_DIR})
    add_subdirectory(${REMAKE_PROJECT_SOURCE_DIR})
  endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_SOURCE_DIR})
endmacro(remake_project)

# Define the value of a ReMake project variable. The variable name will
# automatically be prefixed with an upper-case conversion of the project name.
# Thus, variables may appear in the cache as ${PROJECT_NAME}_${VAR_NAME}.
macro(remake_project_set var_name)
  remake_var_name(${REMAKE_PROJECT_NAME}_${var_name} project_var)
  remake_set(${project_var} ${ARGN})
endmacro(remake_project_set)

# Retrieve the value of a ReMake project variable.
macro(remake_project_get var_name)
  remake_arguments(VAR OUTPUT ${ARGN})

  remake_var_name(${REMAKE_PROJECT_NAME}_${var_name} project_var)
  if(OUTPUT)
    remake_set(${OUTPUT} FROM ${project_var})
  else(OUTPUT)
    remake_set(${var_name} FROM ${project_var})
  endif(OUTPUT)
endmacro(remake_project_get)

# Define a ReMake project option. The option name will be converted into
# a ReMake project variable.
macro(remake_project_option option_name description default_value)
  remake_project_set(${option_name} ${default_value} CACHE BOOL
    "Compile with ${description}.")

  remake_project_get(${option_name})
  if(${option_name})
    message(STATUS "Compiling with ${description}.")
  else(${option_name})
    message(STATUS "NOT compiling with ${description}.")
  endif(${option_name})
endmacro(remake_project_option)

# Define the ReMake project prefix for libary, plugin, executable, script,
# and file names. By an empty argument list, this prefix defaults to the
# lower-case project name followed by a score.
macro(remake_project_prefix)
  remake_arguments(VAR LIBRARY VAR PLUGIN VAR EXECUTABLE VAR SCRIPT 
    VAR FILE ARGN argn ${ARGN})

  remake_set(REMAKE_LIBRARY_PREFIX FROM LIBRARY 
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_PLUGIN_PREFIX FROM PLUGIN 
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_EXECUTABLE_PREFIX FROM EXECUTABLE 
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_SCRIPT_PREFIX FROM SCRIPT 
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
  remake_set(REMAKE_FILE_PREFIX FROM FILE
    DEFAULT ${REMAKE_PROJECT_FILENAME}-)
endmacro(remake_project_prefix)

# Define the ReMake project configuration header.
macro(remake_project_header source)
  remake_arguments(VAR HEADER ${ARGN})
  remake_assign(HEADER DEFAULT config.h)

  if(NOT REMAKE_PROJECT_HEADER)
    remake_set(REMAKE_PROJECT_HEADER ${CMAKE_BINARY_DIR}/include/${HEADER})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${source} 
      ${REMAKE_PROJECT_HEADER})
    include_directories(${CMAKE_BINARY_DIR}/include)
  else(NOT REMAKE_PROJECT_HEADER)
    message(FATAL_ERROR "Duplicate project configuration header!") 
  endif(NOT REMAKE_PROJECT_HEADER)
endmacro(remake_project_header)
