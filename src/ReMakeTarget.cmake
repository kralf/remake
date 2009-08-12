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
#   \optional[list] arg The arguments to be passed on to CMake's 
#     add_custom_target() macro.
macro(remake_target target_name)
  if(NOT TARGET ${target_name})
    add_custom_target(${target_name} ${ARGN})
  endif(NOT TARGET ${target_name})

  remake_file_read(${REMAKE_TARGET_DIR}/${target_name}.commands 
    target_cmds LINES)
  while(target_cmds)
    remake_list_pop(target_cmds target_command SPLIT \n)
    add_custom_command(TARGET ${target_name} ${target_command})
  endwhile(target_cmds)
endmacro(remake_target)

### \brief Output a valid target name from a set of strings.
#   This macro is a helper macro to generate valid target names from arbitrary
#   strings. It replaces whitespace characters and CMake list separators by
#   underscores and performs an upper-case conversion of the result.
#   \required[value] variable The name of a variable to be assigned the
#     generated target name.
#   \required[list] string A list of strings to be concatenated to the
#     target name.
macro(remake_target_name target_var)
  string(TOLOWER "${ARGN}" target_lower)
  string(REGEX REPLACE "[ ;]" "_" ${target_var} "${target_lower}")
endmacro(remake_target_name)

### \brief Add custom build rule to a top-level target.
#   The macro adds a custom build rule to a target. Whereas CMake's
#   add_custom_command() only behaves correctly in the top-level source 
#   directory, this macro is designed to also work in directories below the 
#   top-level. Therefor, build rules are stored for later collection in a
#   temporary file ${TARGET_NAME}.commands in 
#   ${REMAKE_FILE_DIR}/${REMAKE_TARGET_DIR}. A subsequent call to 
#   remake_target() will automatically collect and add these rules.
#   \required[value] name The name of the top-level target to add the build
#     rule to. 
#   \required[list] args The arguments to be passed to CMake's
#     add_custom_command() during collection.
macro(remake_target_add_command target_name)
  remake_arguments(PREFIX target_ VAR WORKING_DIRECTORY ARGN args ${ARGN})
  remake_set(target_working_directory SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  if(${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    add_custom_command(TARGET ${target_name} ${ARGN})
  else(${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    remake_file_create(${REMAKE_TARGET_DIR}/${target_name}.commands OUTDATED)
    remake_file_write(${REMAKE_TARGET_DIR}/${target_name}.commands 
      ${target_args} WORKING_DIRECTORY ${target_working_directory} \n)
  endif(${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_BINARY_DIR})
endmacro(remake_target_add_command)
