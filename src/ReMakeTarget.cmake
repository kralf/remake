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

remake_set(REMAKE_TARGET_DIR ReMakeTargets)

# Define a top-level target. If commands have been stored for that target,
# they will be automatically added.
macro(remake_target target_name)
  add_custom_target(${target_name} ${ARGN})

  remake_file_read(${REMAKE_TARGET_DIR}/${target_name}.commands target_cmds)
  if(target_cmds)
    add_custom_command(TARGET ${target_name} ${target_cmds})
  endif(target_cmds)  
endmacro(remake_target)

# Output a valid target name from a string.
macro(remake_target_name target_var)
  string(TOLOWER "${ARGN}" target_lower)
  string(REGEX REPLACE "[ ;]" "_" ${target_var} "${target_lower}")
endmacro(remake_target_name)

# Add command to a top-level target. This macro also works in directories
# below the top-level directory. Commands will be stored for later collection
# in a file ${TARGET}.commands in ${REMAKE_FILE_DIR}/${REMAKE_TARGET_DIR}.
macro(remake_target_add_command target_name)
  if(${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    add_custom_command(TARGET ${target_name} ${ARGN})
  else(${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    remake_file_create(${REMAKE_TARGET_DIR}/${target_name}.commands OUTDATED)
    remake_file_write(${REMAKE_TARGET_DIR}/${target_name}.commands ${ARGN} 
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  endif(${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_BINARY_DIR})
endmacro(remake_target_add_command)
