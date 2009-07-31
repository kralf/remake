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
macro(remake_target target)
  add_custom_target(${target} ${ARGN})

  remake_file_read(${REMAKE_TARGET_DIR}/${target}.commands commands)
  if(commands)
    add_custom_command(TARGET ${target} ${commands})
  endif(commands)  
endmacro(remake_target)

# Add command to a top-level target. This macro also works in directories
# below the top-level directory. Commands will be stored for later collection
# in a file ${TARGET}.commands in ${REMAKE_FILE_DIR}/${REMAKE_TARGET_DIR}.
macro(remake_target_add_command target)
  remake_file_create(${REMAKE_TARGET_DIR}/${target}.commands OUTDATED)
  remake_file_write(${REMAKE_TARGET_DIR}/${target}.commands ${ARGN} 
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endmacro(remake_target_add_command)
