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

remake_set(REMAKE_FILE_DIR ${CMAKE_BINARY_DIR}/ReMakeFiles)

# Define a ReMake file. If the filename contains a relative path, the
# file will be assumed below ${REMAKE_FILE_DIR}.
macro(remake_file file_name file_var)
  if(IS_ABSOLUTE ${file_name})
    remake_set(${file_var} ${file_name})
  else(IS_ABSOLUTE ${file_name})
    remake_set(${file_var} ${REMAKE_FILE_DIR}/${file_name})
  endif(IS_ABSOLUTE ${file_name})
endmacro(remake_file)

# Output a valid filename from a string.
macro(remake_file_name file_var)
  string(TOLOWER "${ARGN}" file_lower)
  string(REGEX REPLACE "[ ;]" "_" ${file_var} "${file_lower}")
endmacro(remake_file_name)

# Find files using a glob expression, omit hidden files from the list.
macro(remake_file_glob file_var)
  remake_arguments(PREFIX file_ OPTION HIDDEN ARGN globs ${ARGN})

  file(GLOB ${file_var} ${file_globs})
  if(NOT file_hidden)
    foreach(file_name ${${file_var}})
      string(REGEX MATCH "^.*/[.].*$" file_matched ${file_name})
      if(file_matched)
        list(REMOVE_ITEM ${file_var} ${file_name})
      endif(file_matched)
    endforeach(file_name)
  endif(NOT file_hidden)
endmacro(remake_file_glob)

# Create a directory. If the directory name contains a relative path, the
# directory will be created below ${REMAKE_FILE_DIR}.
macro(remake_file_mkdir file_dir_name)
  remake_file(${file_dir_name} file_dir)

  if(NOT EXISTS  ${file_dir})
    file(WRITE ${file_dir}/.touch)
    file(REMOVE ${file_dir}/.touch)
  endif(NOT EXISTS ${file_dir})
endmacro(remake_file_mkdir)

# Create an empty file. If the filename contains a relative path, the
# file will be created below ${REMAKE_FILE_DIR}. Optionally, re-create
# outdated files.
macro(remake_file_create file_name)
  remake_arguments(PREFIX file_ OPTION OUTDATED ${ARGN})
  remake_file(${file_name} file_create)

  if(EXISTS ${file_create})
    if(file_outdated)
      if(${REMAKE_FILE_TIMESTAMP} IS_NEWER_THAN ${file_create})
        file(WRITE ${file_create})
      endif(${REMAKE_FILE_TIMESTAMP} IS_NEWER_THAN ${file_create})
    else(file_outdated)
      file(WRITE ${file_create})
    endif(file_outdated)
  else(EXISTS ${file_create})
    file(WRITE ${file_create})
  endif(EXISTS ${file_create})
endmacro(remake_file_create)

# Read content from file. If the filename contains a relative path, the
# file will be assumed below ${REMAKE_FILE_DIR}.
macro(remake_file_read file_name file_var)
  remake_file(${file_name} file_read)

  if(EXISTS ${file_read})
    file(READ ${file_read} ${file_var})
  else(EXISTS ${file_read})
    remake_set(${file_var})
  endif(EXISTS ${file_read})
endmacro(remake_file_read)

# Write content to file. If the filename contains a relative path, the
# file will be assumed below ${REMAKE_FILE_DIR}. If the file exists,
# any content will be appended.
macro(remake_file_write file_name)
  remake_file(${file_name} file_write)

  if(EXISTS ${file_write})
    file(READ ${file_write} file_content)
  else(EXISTS ${file_write})
    remake_set(file_content)
  endif(EXISTS ${file_write})

  if(file_content)
    file(APPEND ${file_write} ";${ARGN}")
  else(file_content)
    file(APPEND ${file_write} "${ARGN}")
  endif(file_content)
endmacro(remake_file_write)

# Configure files using ReMake variables. The macro actually configures
# files with a .remake extension, but copies files that do not match this
# naming convention. By default, the output path will be the relative 
# source path below ${CMAKE_CURRENT_BINARY_DIR}. The .remake extension will
# automatically be stripped from the output filename.
macro(remake_file_configure)
  remake_arguments(PREFIX file_ VAR DESTINATION VAR OUTPUT ARGN globs ${ARGN})

  file(RELATIVE_PATH file_relative_path ${CMAKE_SOURCE_DIR} 
    ${CMAKE_CURRENT_SOURCE_DIR})
  remake_set(file_destination SELF
    DEFAULT ${CMAKE_BINARY_DIR}/${file_relative_path})
  if(file_output)
    set(${file_output})
  endif(file_output)

  remake_file_glob(file_sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    ${file_globs})
  foreach(file_src ${file_sources})
    if(file_src MATCHES "[.]remake$")
      string(REGEX REPLACE "[.]remake$" "" file_dst ${file_src})
    else(file_src MATCHES "[.]remake$")
      set(file_dst ${file_src} COPYONLY)
    endif(file_src MATCHES "[.]remake$")

    configure_file(${file_src} ${file_destination}/${file_dst})
    if(file_output)
      list(APPEND ${file_output} ${file_destination}/${file_dst})
    endif(file_output)
  endforeach(file_src)
endmacro(remake_file_configure)

remake_file(timestamp REMAKE_FILE_TIMESTAMP)
remake_file_create(${REMAKE_FILE_TIMESTAMP})
