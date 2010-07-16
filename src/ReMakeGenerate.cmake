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
include(ReMakeComponent)

include(ReMakePrivate)

### \brief ReMake code generation macros
#   The ReMake code generation macros define additional targets for the
#   automated generation of source code.
#
#   Support is provided for major lexicographic and parser generators,
#   such as Flex and Bison.

### \brief Add Fast Lexical Analyzer (Flex) sources for a target.
#   This macro specifies code generation rules for a list of Flex sources.
#   It attempts to find the Flex executable and calls remake_generate()
#   in order to define the generator command.
#   \required[value] target The name of the build target to add the
#     generated Flex code for.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the Flex source files, defaulting to *.l.
#   \optional[value] LANG:language The optional language of the build target
#     for which the Flex code will be generated, defaults to C.
#   \optional[value] PREFIX:prefix The optional prefix to be appended to
#     external Flex symbols.
#   \optional[option] IGNORE_CASE If present, this option causes Flex
#     to generate a case-insensitive lexical analyzer.
macro(remake_generate_flex generate_target)
  remake_arguments(PREFIX generate_ VAR LANG VAR PREFIX OPTION IGNORE_CASE
    ARGN globs ${ARGN})
  remake_set(generate_lang SELF DEFAULT C)
  remake_set(generate_globs SELF DEFAULT *.l)

  remake_find_executable(flex PACKAGE Flex)

  if(FLEX_FOUND)
    remake_set(generate_flex_args)
    if(generate_prefix)
      remake_list_push(generate_flex_args -P ${generate_prefix})
    endif(generate_prefix)
    if(generate_ignore_case)
      remake_list_push(generate_flex_args -i)
    endif(generate_ignore_case)

    remake_file_name(generate_extension ${generate_lang})
    remake_file_glob(generate_inputs ${generate_globs})
    foreach(generate_input ${generate_inputs})
      remake_file_name_substitute(generate_source ${generate_input}
        PATH ${CMAKE_CURRENT_BINARY_DIR}
        EXT ${generate_extension})
      remake_generate(Flex ${generate_target} ${FLEX_EXECUTABLE}
        ARGS ${generate_flex_args} -o ${generate_source} ${generate_input}
        INPUT ${generate_input}
        SOURCES ${generate_source})
    endforeach(generate_input)
  endif(FLEX_FOUND)
endmacro(remake_generate_flex)

### \brief Add GNU parser generator (Bison) sources for a target.
#   This macro specifies code generation rules for a list of Bison sources.
#   It attempts to find the Bison executable and calls remake_generate()
#   in order to define the generator command.
#   \required[value] target The name of the build target to add the
#     generated Bison code for.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the Bison source files, defaulting to *.y.
#   \optional[value] LANG:language The optional language of the build target
#     for which the Bison code will be generated, defaults to C.
#   \optional[value] PREFIX:prefix The optional prefix to be appended to
#     external Bison symbols.
#   \optional[option] HEADERS If present, this option tells Bison to also
#     produce header files.
macro(remake_generate_bison generate_target)
  remake_arguments(PREFIX generate_ VAR LANG VAR PREFIX OPTION HEADERS
    ARGN globs ${ARGN})
  remake_set(generate_lang SELF DEFAULT C)
  remake_set(generate_globs SELF DEFAULT *.y)

  remake_find_executable(bison PACKAGE Bison)

  if(BISON_FOUND)
    remake_set(generate_bison_args -y)
    if(generate_prefix)
      remake_list_push(generate_bison_args -p ${generate_prefix})
    endif(generate_prefix)
    if(generate_headers)
      remake_list_push(generate_bison_args -d)
      remake_include(${CMAKE_CURRENT_BINARY_DIR})
    endif(generate_headers)

    remake_file_name(generate_src_extension ${generate_lang})
    string(REGEX REPLACE "^.(.*)" "h\\1" generate_header_extension
      ${generate_src_extension})
    remake_file_glob(generate_inputs ${generate_globs})
    foreach(generate_input ${generate_inputs})
      remake_file_name_substitute(generate_source ${generate_input}
        PATH ${CMAKE_CURRENT_BINARY_DIR}
        EXT ${generate_src_extension})
      remake_list_push(generate_bison_args -o ${generate_source})
      if(generate_headers)
        remake_file_name_substitute(generate_header ${generate_input}
          PATH ${CMAKE_CURRENT_BINARY_DIR}
          EXT ${generate_header_extension})
      endif(generate_headers)

      remake_generate(Bison ${generate_target} ${BISON_EXECUTABLE}
        ARGS ${generate_bison_args} ${generate_input}
        INPUT ${generate_input}
        SOURCES ${generate_source}
        OTHERS ${generate_header})
    endforeach(generate_input)
  endif(BISON_FOUND)
endmacro(remake_generate_bison)

### \brief Add custom generator sources for a target.
#   This macro specifies code generation rules for a custom generator.
#   It attempts to call remake_generate() with the custom generator's
#   executable in order to define the generator command.
#   \required[value] generator The name of the custom code generator.
#   \required[value] target The name of the build target to add the
#     custom-generated code for.
#   \required[value] command The command that executes the custom generator.
#     Assuming that the generator is provided with the sources, the working
#     directory for this command defaults to ${CMAKE_CURRENT_SOURCE_DIR}.
#     If the custom generator itself needs to be generated, the command will
#     instead be interpreted as target name.
#   \optional[list] arg An optional list of command line arguments to be
#     passed to the generator command.
#   \required[list] INPUT:glob A list of glob expressions that are resolved
#     in order to find the input source files for the custom generator. The
#     list of input files may be substituted for the command-line placeholder
#     %INPUT%.
#   \required[list] SOURCES:filename A list of filenames that identify the
#     generated source files. If no absolute path is provided with the
#     filenames, ${CMAKE_CURRENT_BINARY_DIR} will be used as output path
#     instead. The list of generated sources may be substituted for the
#     command-line placeholder %SOURCES%.
#   \required[list] OTHERS:filename A list of filenames that identify the
#     generated non-source files. If no absolute path is provided with the
#     filenames, ${CMAKE_CURRENT_BINARY_DIR} will be used as output path
#     instead. The list of generated non-sources may be substituted for the
#     command-line placeholder %OTHERS%.
macro(remake_generate_custom generate_generator generate_target
    generate_command)
  remake_arguments(PREFIX generate_ LIST INPUT LIST SOURCES LIST OTHERS
    ARGN args ${ARGN})

  remake_file_glob(generate_inputs ${generate_input})
  remake_file_name_substitute(generate_abs_sources ${generate_sources}
    PATH ${CMAKE_CURRENT_BINARY_DIR} TO_ABSOLUTE)
  remake_file_name_substitute(generate_abs_others ${generate_others}
    PATH ${CMAKE_CURRENT_BINARY_DIR} TO_ABSOLUTE)

  remake_list_replace(generate_args %INPUT% REPLACE ${generate_inputs})
  remake_list_replace(generate_args %SOURCES% REPLACE ${generate_abs_sources})
  remake_list_replace(generate_args %OTHERS% REPLACE ${generate_abs_others})

  remake_generate(${generate_generator} ${generate_target} ${generate_command}
    ARGS ${generate_args}
    INPUT ${generate_inputs}
    SOURCES ${generate_abs_sources}
    OTHERS ${generate_abs_others})
endmacro(remake_generate_custom)

### \brief Define commands for source code generation.
#   This macro is a helper macro to define source code generation commands
#   for a list of input files. Note that the macro gets invoked by the
#   generator-specific macros defined in this module. It should not be called
#   directly from a CMakeLists.txt file.
#   \required[value] generator The name of the generator to be used for
#     code generation.
#   \required[value] target The name of the build target to add the
#     generated source code for.
#   \required[value] command The generator command that will be called to
#     generate the code.
#   \optional[list] ARGS:arg An optional list of arguments that will be
#     passed to the generator command.
#   \required[list] INPUT:filename A list of filenames that identify the
#     input files to the generator command.
#   \required[list] SOURCES:filename A list of filenames that identify the
#     source output files of the generator command, i.e. the generated
#     sources that will be added as build sources of the specified target.
#   \optional[list] OTHERS:filename A list of filenames that identify the
#     non-source output files of the generator command. Note that header
#     files or similar output should be specified here.
macro(remake_generate generate_generator generate_target generate_command)
  remake_arguments(PREFIX generate_ VAR LANG LIST ARGS LIST INPUT
    LIST SOURCES LIST OTHERS ${ARGN})

  remake_set(generate_relatives)
  foreach(generate_src ${generate_sources})
    file(RELATIVE_PATH generate_relative ${CMAKE_BINARY_DIR} ${generate_src})
    remake_list_push(generate_relatives ${generate_relative})
  endforeach(generate_src)

  add_custom_command(
    COMMAND ${generate_command} ${generate_args}
    DEPENDS ${generate_input}
    OUTPUT ${generate_sources} ${generate_others}
    COMMENT "Generating ${generate_generator} source(s) ${generate_relatives}")

  remake_target_add_sources(${generate_target} ${generate_sources})
endmacro(remake_generate)
