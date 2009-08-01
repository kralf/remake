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
macro(remake_file file_name var_name)
  if(IS_ABSOLUTE ${file_name})
    remake_set(${var_name} ${file_name})
  else(IS_ABSOLUTE ${file_name})
    remake_set(${var_name} ${REMAKE_FILE_DIR}/${file_name})
  endif(IS_ABSOLUTE ${file_name})
endmacro(remake_file)

# Output a valid filename from a string.
macro(remake_file_name var_name)
  string(TOLOWER "${ARGN}" lower_string)
  string(REGEX REPLACE "[ ;]" "_" ${var_name} "${lower_string}")
endmacro(remake_file_name)

# Find files using a glob expression, omit hidden files from the list.
macro(remake_file_glob var_name)
  remake_arguments(OPTION HIDDEN ARGN glob_expressions ${ARGN})

  file(GLOB ${var_name} ${glob_expressions})
  if(NOT HIDDEN)
    foreach(file_name ${${var_name}})
      string(REGEX MATCH "^.*/[.].*$" regex_matched ${file_name})
      if(regex_matched)
        list(REMOVE_ITEM ${var_name} ${file_name})
      endif(regex_matched)
    endforeach(file_name)
  endif(NOT HIDDEN)
endmacro(remake_file_glob)

# Check if a file exists.
macro(remake_file_create file_name)
  remake_file(${file_name} create_file)
  file(WRITE ${create_file})
endmacro(remake_file_create)

# Create an empty file. If the filename contains a relative path, the
# file will be created below ${REMAKE_FILE_DIR}. Optionally, re-create
# outdated files.
macro(remake_file_create file_name)
  remake_arguments(OPTION OUTDATED ${ARGN})
  remake_file(${file_name} create_file)

  if(EXISTS ${create_file})
    if(OUTDATED)
      if(${REMAKE_FILE_TIMESTAMP} IS_NEWER_THAN ${create_file})
        file(WRITE ${create_file})
      endif(${REMAKE_FILE_TIMESTAMP} IS_NEWER_THAN ${create_file})
    else(OUTDATED)
      file(WRITE ${create_file})
    endif(OUTDATED)
  else(EXISTS ${create_file})
    file(WRITE ${create_file})
  endif(EXISTS ${create_file})
endmacro(remake_file_create)

# Read content from file. If the filename contains a relative path, the
# file will be assumed below ${REMAKE_FILE_DIR}.
macro(remake_file_read file_name var_name)
  remake_file(${file_name} read_file)

  if(EXISTS ${read_file})
    file(READ ${read_file} ${var_name})
  else(EXISTS ${read_file})
    remake_set(${var_name})
  endif(EXISTS ${read_file})
endmacro(remake_file_read)

# Write content to file. If the filename contains a relative path, the
# file will be assumed below ${REMAKE_FILE_DIR}. If the file exists,
# any content will be appended.
macro(remake_file_write file_name)
  remake_file(${file_name} write_file)

  if(EXISTS ${write_file})
    file(READ ${write_file} file_content)
  else(EXISTS ${write_file})
    remake_set(file_content)
  endif(EXISTS ${write_file})

  if(file_content)
    file(APPEND ${write_file} ";${ARGN}")
  else(file_content)
    file(APPEND ${write_file} "${ARGN}")
  endif(file_content)
endmacro(remake_file_write)

# Configure files using ReMake variables. The macro actually configures
# files with a .remake extension, but copies files that do not match this
# naming convention. By default, the output path will be the relative 
# source path below ${CMAKE_CURRENT_BINARY_DIR}. The .remake extension will
# automatically be stripped from the output filename.
macro(remake_file_configure)
  remake_arguments(VAR DESTINATION VAR OUTPUT ARGN glob_expressions ${ARGN})
  file(RELATIVE_PATH relative_path ${CMAKE_SOURCE_DIR} 
    ${CMAKE_CURRENT_SOURCE_DIR})
  remake_set(DESTINATION DEFAULT ${CMAKE_BINARY_DIR}/${relative_path})
  if(OUTPUT)
    set(${OUTPUT})
  endif(OUTPUT)

  remake_file_glob(config_files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} 
    ${glob_expressions})
  foreach(config_file ${config_files})
    if(config_file MATCHES "[.]remake$")
      string(REGEX REPLACE "[.]remake$" "" output_file ${config_file})
    else(config_file MATCHES "[.]remake$")
      set(output_file ${config_file} COPYONLY)
    endif(config_file MATCHES "[.]remake$")

    configure_file(${config_file} ${DESTINATION}/${output_file})
    if(OUTPUT)
      list(APPEND ${OUTPUT} ${DESTINATION}/${output_file})
    endif(OUTPUT)
  endforeach(config_file)
endmacro(remake_file_configure)

remake_file(timestamp REMAKE_FILE_TIMESTAMP)
remake_file_create(${REMAKE_FILE_TIMESTAMP})
