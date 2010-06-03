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

### \brief ReMake file macros
#   The ReMake file macros are a set of helper macros to simplify
#   file operations in ReMake.

remake_set(REMAKE_FILE_DIR ReMakeFiles)

### \brief Define a ReMake file.
#   This macro creates a variable to hold the ReMake-compliant path to a
#   a regular file or directory with the specified name. If the file or
#   directory name contains a relative path, it is assumed to be located
#   below the ReMake directory ${REMAKE_FILE_DIR}.
#   \required[value] variable name of the output variable to be assigned the
#     ReMake path to the file or directory.
#   \required[value] filename The name of a file or directory.
#   \optional[option] TOPLEVEL If this option is present, the relative-path
#     file or directory is assumed to be located in the top-level ReMake
#     directory below ${CMAKE_BINARY_DIR}. Otherwise, the file or directory
#     resides in the local ReMake directory below ${CMAKE_CURRENT_BINARY_DIR}.
macro(remake_file file_var file_name)
  remake_arguments(PREFIX file_ OPTION TOPLEVEL ${ARGN})

  if(IS_ABSOLUTE ${file_name})
    remake_set(${file_var} ${file_name})
  else(IS_ABSOLUTE ${file_name})
    if(file_toplevel)
      remake_set(${file_var}
        ${CMAKE_BINARY_DIR}/${REMAKE_FILE_DIR}/${file_name})
    else(file_toplevel)
      remake_set(${file_var}
        ${CMAKE_CURRENT_BINARY_DIR}/${REMAKE_FILE_DIR}/${file_name})
    endif(file_toplevel)
  endif(IS_ABSOLUTE ${file_name})
endmacro(remake_file)

### \brief Output a valid file or directory name from a set of strings.
#   This macro is a helper macro to generate valid filenames from arbitrary
#   strings. It replaces whitespace characters and CMake list separators by
#   underscores and performs a lower-case conversion of the result.
#   \required[value] variable The name of a variable to be assigned the
#     generated filename.
#   \required[list] string A list of strings to be concatenated to the
#     filename.
macro(remake_file_name file_var)
  string(TOLOWER "${ARGN}" file_lower)
  string(REGEX REPLACE "[ ;]" "_" ${file_var} "${file_lower}")
endmacro(remake_file_name)

### \brief Append a list of suffixes to a filename.
#   This macro appends a list of suffixes to a filename. The suffixes are
#   appended to the filename itself, not to the filename's extension.
#   \required[value] variable The name of the variable that is assigned the
#     resulting suffixed filename.
#   \required[value] filename The input filename to be suffixed.
#   \required[list] suffix The list of suffixes to be appended to the
#     filename. Note that the list can be empty in which case the input
#     filename is returned.
macro(remake_file_suffix file_var file_name)
  remake_arguments(PREFIX file_ ARGN suffixes ${ARGN})

  if(file_suffixes)
    get_filename_component(file_path ${file_name} PATH)
    get_filename_component(file_name_we ${file_name} NAME_WE)
    get_filename_component(file_ext ${file_name} EXT)

    if(file_path)
      remake_set(${file_var} "${file_path}/")
    else(file_path)
      remake_set(${file_var})
    endif(file_path)
    remake_set(${file_var} "${${file_var}}${file_name_we}")
    foreach(file_suffix ${file_suffixes})
      remake_set(${file_var} "${${file_var}}${file_suffix}")
    endforeach(file_suffix)
    if(file_ext)
      remake_set(${file_var} "${${file_var}}.${file_ext}")
    endif(file_ext)
  else(file_suffixes)
    remake_set(${file_var} ${file_name})
  endif(file_suffixes)
endmacro(remake_file_suffix)

### \brief Find files or directories using a glob expression.
#   This macro searches the current directory for files or directories having
#   names that match any of the glob expression passed to the macro and returns
#   a result list of file/directory names. By default, hidden files/directories
#   will be excluded from the result list.
#   \required[value] variable The name of the output variable to hold the
#     matched file/directory names.
#   \optional[value] WORKING_DIRECTORY:dirname An optional directory name that
#     refers to the working directory for resolving relative-path glob
#     expressions, defaults to the current directory.
#   \optional[option] HIDDEN If present, this option prevents hidden
#     files/directories from being excluded from the result list.
#   \optional[option] FILES If present, this option causes the macro
#     to find regular files. Note that this is the default behavior. However,
#     passing the option may prove useful in cases where both, files and
#     directories, shall be included in the result list.
#   \optional[option] DIRECTORIES If present, this option causes the macro
#     to find directories. With the FILES option being passed in addition,
#     regular files are also included in the result list.
#   \required[list] glob A list of glob expressions that is passed to CMake's
#     file(GLOB ...) macro. See the CMake documentation for usage.
macro(remake_file_glob file_var)
  remake_arguments(PREFIX file_ VAR WORKING_DIRECTORY OPTION HIDDEN
    OPTION FILES OPTION DIRECTORIES ARGN globs ${ARGN})

  if(file_working_directory)
    remake_set(file_working_globs)
    foreach(file_glob ${file_globs})
      if(IS_ABSOLUTE ${file_glob})
        remake_list_push(file_working_globs ${file_glob})
      else(IS_ABSOLUTE ${file_glob})
        remake_list_push(file_working_globs
          ${file_working_directory}/${file_glob})
      endif(IS_ABSOLUTE ${file_glob})
    endforeach(file_glob)
  else(file_working_directory)
    remake_set(file_working_globs ${file_globs})
  endif(file_working_directory)

  file(GLOB ${file_var} ${file_working_globs})

  if(NOT file_directories)
    foreach(file_name ${${file_var}})
      if(IS_DIRECTORY ${file_name})
        list(REMOVE_ITEM ${file_var} ${file_name})
      endif(IS_DIRECTORY ${file_name})
    endforeach(file_name)
    remake_set(file_files ON)
  endif(NOT file_directories)

  if(NOT file_files)
    foreach(file_name ${${file_var}})
      if(NOT IS_DIRECTORY ${file_name})
        list(REMOVE_ITEM ${file_var} ${file_name})
      endif(NOT IS_DIRECTORY ${file_name})
    endforeach(file_name)
  endif(NOT file_files)

  if(NOT file_hidden)
    foreach(file_name ${${file_var}})
      string(REGEX MATCH "^.*/[.][^/]*$" file_matched ${file_name})
      if(file_matched)
        list(REMOVE_ITEM ${file_var} ${file_name})
      endif(file_matched)
    endforeach(file_name)
  endif(NOT file_hidden)
endmacro(remake_file_glob)

### \brief Create a directory.
#   This macro creates a ReMake directory. The directory name is automatically
#   converted into a ReMake location by a call to remake_file().
#   \required[value] dirname The name of the directory to be created.
#   \optional[option] TOPLEVEL If this option is present, the directory
#     to be created is a top-level ReMake directory.
macro(remake_file_mkdir file_dir_name)
  remake_arguments(PREFIX file_ OPTION TOPLEVEL ${ARGN})
  remake_file(file_dir ${file_dir_name} ${TOPLEVEL})

  if(NOT IS_DIRECTORY  ${file_dir})
    file(MAKE_DIRECTORY ${file_dir})
  endif(NOT IS_DIRECTORY ${file_dir})
endmacro(remake_file_mkdir)

### \brief Recursively remove a directory.
#   This macro recursively removes a ReMake directory. The directory name
#   is automatically converted into a ReMake location by a call to
#   remake_file().
#   \required[value] dirname The name of the directory to be removed.
#   \optional[option] TOPLEVEL If this option is present, the directory
#     to be removed is a top-level ReMake directory.
macro(remake_file_rmdir file_dir_name)
  remake_arguments(PREFIX file_ OPTION TOPLEVEL ${ARGN})
  remake_file(file_dir ${file_dir_name} ${TOPLEVEL})

  if(IS_DIRECTORY  ${file_dir})
    file(REMOVE_RECURSE ${file_dir})
  endif(IS_DIRECTORY ${file_dir})
endmacro(remake_file_rmdir)

### \brief Create an empty file.
#   This macro creates an empty ReMake file. The filename is automatically
#   converted into a ReMake location by a call to remake_file(). Optionally,
#   the macro allows for selectively re-creating outdated files. Therefor,
#   the file modification date is tested against ReMake's timestamp file,
#   a special file created at inclusion time.
#   \required[value] filename The name of the file to be created.
#   \optional[option] OUTDATED If present, this option prevents files with
#      a recent modification timestamp from being re-created.
#   \optional[option] TOPLEVEL If this option is present, the file
#     to be created is a top-level ReMake file.
macro(remake_file_create file_name)
  remake_arguments(PREFIX file_ OPTION TOPLEVEL OPTION OUTDATED ${ARGN})
  remake_file(file_create ${file_name} ${TOPLEVEL})

  if(EXISTS ${file_create})
    if(file_outdated)
      if(NOT ${file_create} IS_NEWER_THAN ${REMAKE_FILE_TIMESTAMP})
        file(WRITE ${file_create})
      endif(NOT ${file_create} IS_NEWER_THAN ${REMAKE_FILE_TIMESTAMP})
    else(file_outdated)
      file(WRITE ${file_create})
    endif(file_outdated)
  else(EXISTS ${file_create})
    file(WRITE ${file_create})
  endif(EXISTS ${file_create})
endmacro(remake_file_create)

### \brief Read content from file.
#   This macro reads file content into a string variable. The name of the file
#   to be read is automatically converted into a ReMake location by a call to
#   remake_file().
#   \required[value] variable The name of a string variable to be assigned
#     the file's content.
#   \required[value] filename The name of the file to be read from.
#   \optional[option] TOPLEVEL If this option is present, the file
#     to be read is a top-level ReMake file.
macro(remake_file_read file_var file_name)
  remake_arguments(PREFIX file_ OPTION TOPLEVEL ${ARGN})
  remake_file(file_read ${file_name} ${TOPLEVEL})

  if(EXISTS ${file_read})
    file(READ ${file_read} ${file_var})
  else(EXISTS ${file_read})
    remake_set(${file_var})
  endif(EXISTS ${file_read})
endmacro(remake_file_read)

### \brief Write content to file.
#   This macro appends a list of string values to a file. The name of the file
#   to be written is automatically converted into a ReMake location by a call
#   to remake_file(). If the file does not exists yets, it will automatically
#   be created.
#   \required[value] filename The name of the file to be written to.
#   \optional[option] TOPLEVEL If this option is present, the file
#     to be written is a top-level ReMake file.
#   \optional[value] FROM:variable The name of a variable holding the content
#     to be written. Passing file content by reference makes the macro
#     ignore all additional string values and is particularly useful in the
#     presence of escape characters. Whereas value passing generally causes
#     CMake to resolve escape sequences, reference passing does not suffer
#     from such modifications.
#   \optional[list] string The list of strings to be appended to the file.
macro(remake_file_write file_name)
  remake_arguments(PREFIX file_ OPTION TOPLEVEL VAR FROM ARGN strings ${ARGN})
  remake_file(file_write ${file_name} ${TOPLEVEL})

  if(EXISTS ${file_write})
    file(READ ${file_write} file_not_empty)
    if(file_not_empty)
      file(APPEND ${file_write} ";")
    endif(file_not_empty)
    if(file_from)
      file(APPEND ${file_write} "${${file_from}}")
    else(file_from)
      file(APPEND ${file_write} "${file_strings}")
    endif(file_from)
  else(EXISTS ${file_write})
    remake_set(file_content)
  endif(EXISTS ${file_write})
endmacro(remake_file_write)

### \brief Configure files using ReMake variables.
#   This macro takes a glob expression and, in all matching input files,
#   replaces variables referenced as ${VAR} with their values as determined
#   by CMake.
#   The macro actually configures files with a .remake extension, but copies
#   files that do not match this naming convention. By default, the
#   configured file's output path is the relative source path below
#   ${CMAKE_CURRENT_BINARY_DIR}. The .remake extension is automatically
#   stripped from the output filenames.
#   \required[list] glob A list of glob expressions that are matched to find
#     the input files.
#   \optional[var] DESTINATION:dirname The optional destination path for
#     output files generated by this macro.
#   \optional[var] OUTPUT:variable The optional name of a list variable to
#     be assigned all absolute-path output filenames.
#   \optional[option] ESCAPE_QUOTES If specified, any substituted quotes
#     will be C-style escaped.
#   \optional[option] ESCAPE_NEWLINES If specified, any substituted line
#     breaks will be C-style escaped.
macro(remake_file_configure)
  remake_arguments(PREFIX file_ VAR DESTINATION VAR OUTPUT OPTION ESCAPE_QUOTES
    OPTION ESCAPE_NEWLINES ARGN globs ${ARGN})

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
    remake_file_read(file_content ${CMAKE_CURRENT_SOURCE_DIR}/${file_src})
    if(file_src MATCHES "[.]remake$")
      get_cmake_property(file_globals VARIABLES)
      string(REGEX MATCHALL "\\\${[a-zA-Z_]*}" file_vars ${file_content})
      list(REMOVE_DUPLICATES file_vars)

      foreach(file_var ${file_vars})
        string(REGEX REPLACE "\\\${([a-zA-Z_]*)}" "\\1" file_var ${file_var})
        remake_set(file_value "${${file_var}}")
        if(file_escape_quotes)
          string(REGEX REPLACE "\"" "\\\\\"" file_value "${file_value}")
        endif(file_escape_quotes)
        if(file_escape_newlines)
          string(REGEX REPLACE "\n" "\\\\n" file_value "${file_value}")
        endif(file_escape_newlines)
        string(REPLACE "\${${file_var}}" "${file_value}" file_content
          "${file_content}")
      endforeach(file_var)

      string(REGEX REPLACE "[.]remake$" "" file_dst ${file_src})
      remake_file_create(${file_destination}/${file_dst})
      remake_file_write(${file_destination}/${file_dst} FROM file_content)

      configure_file(${file_destination}/${file_dst}
        ${file_destination}/${file_dst})
    else(file_src MATCHES "[.]remake$")
      set(file_dst ${file_src})
      remake_file_create(${file_destination}/${file_dst})
      remake_file_write(${file_destination}/${file_dst} FROM file_content)
    endif(file_src MATCHES "[.]remake$")

    if(file_output)
      list(APPEND ${file_output} ${file_destination}/${file_dst})
    endif(file_output)
  endforeach(file_src)
endmacro(remake_file_configure)

remake_file(REMAKE_FILE_TIMESTAMP timestamp)
remake_file_create(${REMAKE_FILE_TIMESTAMP})
