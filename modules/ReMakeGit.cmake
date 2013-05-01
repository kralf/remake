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

include(ReMakeComponent)
include(ReMakeProject)

include(ReMakePrivate)

### \brief ReMake Git macros
#   The ReMake Git module provides useful tools for Git-based projects.

if(NOT DEFINED REMAKE_GIT_CMAKE)
  remake_set(REMAKE_GIT_CMAKE ON)

  remake_set(REMAKE_GIT_DIR ReMakeGit)
  remake_find_executable(git PACKAGE Git QUIET OPTIONAL)
endif(NOT DEFINED REMAKE_GIT_CMAKE)

### \brief Generate a sequential revision number.
#   This macro attempts to generate a sequential revision number by counting
#   the commits reachable from HEAD. Its purpose is to contribute a consecutive
#   revision number to the version information maintained by projects. The
#   macro defines an output variable with the name provided and assigns the
#   revision number or 0 for non-versioned directories.
#   \required[value] variable The name of a variable to be assigned the
#     revision number.
macro(remake_git_revision git_var)
  if(DEFINED GIT_REVISION)
    remake_set(git_revision ${GIT_REVISION})
  else(DEFINED GIT_REVISION)
    remake_set(git_revision 0)
  endif(DEFINED GIT_REVISION)

  remake_project_set(GIT_REVISION ${git_revision} CACHE STRING
    "Git revision of project sources.")

  if(GIT_FOUND)
    execute_process(
      COMMAND ${GIT_EXECUTABLE} rev-parse --show-toplevel
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      RESULT_VARIABLE git_result
      OUTPUT_VARIABLE git_parse_toplevel
      ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

    remake_unset(git_toplevel)
    if(${git_result} EQUAL 0)
      if(IS_DIRECTORY ${git_parse_toplevel}/.git)
        remake_set(git_toplevel ${git_parse_toplevel})
      endif(IS_DIRECTORY ${git_parse_toplevel}/.git)
    endif(${git_result} EQUAL 0)

    remake_project_set(GIT_TOPLEVEL "${git_toplevel}" CACHE PATH
      "Git top-level directory containing the project sources.")
    remake_project_get(GIT_TOPLEVEL OUTPUT git_toplevel)

    if(git_toplevel)
      execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-list HEAD
        WORKING_DIRECTORY ${git_toplevel}
        RESULT_VARIABLE git_result
        OUTPUT_VARIABLE git_list)

      if(${git_result} EQUAL 0)
        string(REGEX REPLACE "\\\n" ";" git_list "${git_list}")
        string(REGEX REPLACE ";$" "" git_list "${git_list}")
        list(LENGTH git_list git_length)

        remake_project_set(GIT_REVISION ${git_length}
          CACHE STRING "Git revision of project sources." FORCE)
      endif(${git_result} EQUAL 0)
    endif(git_toplevel)
  endif(GIT_FOUND)

  remake_project_get(GIT_REVISION OUTPUT ${git_var})
endmacro(remake_git_revision)

### \brief Define Git log build rules.
#   This macro defines build rules for storing Git log messages of the
#   working directory into a file. Called in the top-level source directory,
#   it may be used to dump a project's changelog during build.
#   \required[value] filename The name of the file to write the Git
#     log messages to, relative to ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_add_command(). See
#     ReMakeComponent for details.
#   \optional[var] TARGET:target The optional name of a top-level target
#     to add the build commands to, defaults to git_log.
#   \optional[var] OUTPUT:variable The optional name of a variable to be
#     assigned the absolute-path output filename.
macro(remake_git_log git_file)
  remake_arguments(PREFIX git_ VAR COMPONENT VAR TARGET VAR OUTPUT ${ARGN})
  remake_set(git_target SELF DEFAULT git_log)

  if(git_output)
    remake_set(${git_output})
  endif(git_output)
  remake_project_get(GIT_TOPLEVEL OUTPUT git_toplevel)

  if(git_toplevel)
    if(NOT IS_ABSOLUTE ${git_file})
      remake_set(git_absolute ${git_toplevel}/${git_file})
    else(NOT IS_ABSOLUTE ${git_file})
      remake_set(git_absolute ${git_file})
    endif(NOT IS_ABSOLUTE ${git_file})

    remake_file_mkdir(${REMAKE_GIT_DIR})
    remake_file(git_head ${REMAKE_GIT_DIR}/head)
    add_custom_command(
      OUTPUT ${git_head}
      COMMAND ${GIT_EXECUTABLE} rev-list HEAD > ${git_head} VERBATIM
      WORKING_DIRECTORY ${git_toplevel}
      DEPENDS ${git_toplevel}/.git/HEAD
      COMMENT "Retrieving Git head commit")
    remake_component_add_command(
      OUTPUT ${git_absolute} AS ${git_target}
      COMMAND ${GIT_EXECUTABLE} log > ${git_absolute}
      WORKING_DIRECTORY ${git_toplevel}
      DEPENDS ${git_head}
      COMMENT "Retrieving Git log messages"
      ${COMPONENT})

    if(git_output)
      remake_set(${git_output} ${git_absolute})
    endif(git_output)
  endif(git_toplevel)
endmacro(remake_git_log)
