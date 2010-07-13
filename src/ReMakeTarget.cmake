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

### \brief ReMake target macros
#   The ReMake target module provides useful workarounds addressing some 
#   grave CMake limitations. In CMake, top-level target definition only
#   behaves correctly in the top-level source directory. The ReMake target 
#   macros are specifically designed to also work in directories below the
#   top-level.

remake_set(REMAKE_TARGET_DIR ReMakeTargets)

### \brief Define a new top-level target.
#   The macro creates a top-level target by calling CMake's add_custom_target()
#   with the provided target name and all additional arguments.
#   If any commands have been stored for that target, these commands will 
#   automatically be added as custom build rules.
#   \required[value] name The name of the target to be created.
#   \optional[option] NON_EMPTY With this option being present, the target will
#     not be defined if it is empty, i.e. if no commands have been added to
#     this target by a previous call to remake_target_add_command().
#   \optional[list] arg The arguments to be passed on to CMake's 
#     add_custom_target() macro.
macro(remake_target target_name)
  remake_arguments(PREFIX target_ OPTION NON_EMPTY ARGN args ${ARGN})

  remake_file_read(target_cmds ${REMAKE_TARGET_DIR}/${target_name}.commands
    TOPLEVEL)
  if(target_cmds)
    if(NOT TARGET ${target_name})
      add_custom_target(${target_name} ${target_args})
    endif(NOT TARGET ${target_name})

    while(target_cmds)
      remake_list_pop(target_cmds target_command SPLIT \n)
      remake_target_add_command(TARGET ${target_name} ${target_command})
    endwhile(target_cmds)
  else(target_cmds)
    if(NOT target_non_empty)
      if(NOT TARGET ${target_name})
        add_custom_target(${target_name} ${target_args})
      endif(NOT TARGET ${target_name})
    endif(NOT target_non_empty)
  endif(target_cmds)
endmacro(remake_target)

### \brief Output a valid target name from a set of strings.
#   This macro is a helper macro to generate valid target names from arbitrary
#   strings. It replaces whitespace characters, periods, and CMake list
#   separators by underscores and performs a lower-case conversion of the
#   result.
#   \required[value] variable The name of a variable to be assigned the
#     generated target name.
#   \required[list] string A list of strings to be concatenated to the
#     target name.
macro(remake_target_name target_var)
  string(TOLOWER "${ARGN}" target_lower)
  string(REGEX REPLACE "[ ;.]" "_" ${target_var} "${target_lower}")
endmacro(remake_target_name)

### \brief Add custom build command to a top-level target.
#   This macro adds a custom build command to a target. Whereas CMake's
#   add_custom_command() only behaves correctly in the top-level source 
#   directory, this macro is designed to also work in directories below the 
#   top-level. Therefore, build rules are stored for later collection in a
#   temporary file ${TARGET_NAME}.commands in 
#   ${REMAKE_FILE_DIR}/${REMAKE_TARGET_DIR}. A subsequent call to
#   remake_target() will automatically collect and add these rules.
#   Note that CMake currently does not support the definition of file-level
#   dependencies for already defined targets. If this case is detected, the
#   macro will create a corresponding top-level output target with a custom
#   command driving the build.
#   \required[value] name The name of the top-level target to add the build
#     rule to. 
#   \required[list] args The arguments to be passed to CMake's
#     add_custom_command() during collection.
#   \optional[list] OUTPUT:filename The optional list of output files created
#     by the build command.
#   \optional[value] AS:target A target name that will be used as top-level
#     output target with file-level dependencies to the command's output files.
#     Note that the failure to provide an output target with a list of
#     output filenames will result in a fatal error.
macro(remake_target_add_command target_name)
  remake_arguments(PREFIX target_ LIST OUTPUT VAR AS VAR WORKING_DIRECTORY
    ARGN args ${ARGN})
  remake_set(target_working_directory SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  if(TARGET ${target_name})
    if(target_output)
      if(target_as)
        add_custom_command(
          OUTPUT ${target_output}
          WORKING_DIRECTORY ${target_working_directory}
          ${target_args})
        remake_target(${target_as} DEPENDS ${target_output})
        add_dependencies(${target_name} ${target_as})
      else(target_as)
        message(FATAL_ERROR
          "Command output specified, but no output target given!")
      endif(target_as)
    else(target_as)
      add_custom_command(
        TARGET ${target_name}
        WORKING_DIRECTORY ${target_working_directory}
        ${ARGN})
    endif(target_output)
  else(TARGET ${target_name})
    remake_file_create(
      ${REMAKE_TARGET_DIR}/${target_name}.commands TOPLEVEL
      OUTDATED)
    remake_file_write(
      ${REMAKE_TARGET_DIR}/${target_name}.commands TOPLEVEL
      ${OUTPUT} ${AS}
      WORKING_DIRECTORY ${target_working_directory}
      ${target_args}\n)
  endif(TARGET ${target_name})
endmacro(remake_target_add_command)

### \brief Add sources to a target.
#   This macro does not actually add sources to an already defined top-level
#   target, but appends a list of source files to a variable named 
#   ${TARGET}_SOURCES. Thus, the macro may be used to circumnavigate CMake's
#   deficiency on modifying an existing target's SOURCES property. Note that
#   the list of sources needs to be defined before the actual top-level
#   target and can later be recovered by calling remake_target_get_sources().
#   Also, be aware of the scope of the ${TARGET}_SOURCES variable.
#   \required[value] name The name of the target to add the sources to. 
#   \required[list] source A list of source filenames to be appended to
#     the target's sources.
macro(remake_target_add_sources target_name)
  remake_arguments(PREFIX target_ ARGN sources ${ARGN})
  remake_var_name(target_global_var ${target_name} SOURCES)
  remake_list_push(${target_global_var} ${target_sources})
endmacro(remake_target_add_sources)

### \brief Retrieve sources for a target.
#   This macro retrieves a list of source files from a variable named 
#   ${TARGET}_SOURCES, usually defined by remake_target_add_sources().
#   \required[value] variable The name of a variable to be assigned the list
#     of sources for the target.
#   \required[value] name The name of the target to retrieve the sources for.
macro(remake_target_get_sources target_var target_name)
  remake_var_name(target_global_var ${target_name} SOURCES)
  remake_set(${target_var} ${${target_global_var}})
endmacro(remake_target_get_sources)

remake_file_rmdir(${REMAKE_TARGET_DIR} TOPLEVEL)
