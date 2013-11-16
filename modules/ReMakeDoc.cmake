############################################################################
#    Copyright (C) 2013 by Ralf Kaestner                                   #
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

include(ReMakeProject)
include(ReMakeFile)
include(ReMakeComponent)
include(ReMakeDebian)

### \brief ReMake documentation macros
#   The ReMake documentation module has been designed for simple and 
#   transparent intergration of project documentation tasks with CMake.
#
#   It provides support for major document generators, such as Doxygen and
#   GNU Troff.
#
#   \variable REMAKE_DOC_TYPES The list of documentation types to be
#     generated.
#   \variable REMAKE_DOC_OUTPUTS The list of document output directories,
#     one directory for each type in ${REMAKE_DOC_TYPES}.
#   \variable REMAKE_DOC_DESTINATIONS The list of document install 
#     destinations, one destination directory for each type in
#     ${REMAKE_DOC_TYPES}.
#   \variable REMAKE_DOC_CONFIGURATION_DIR The directory containing the 
#     project document configuration.

if(NOT DEFINED REMAKE_DOC_CMAKE)
  remake_set(REMAKE_DOC_CMAKE ON)

  remake_set(REMAKE_DOC_COMPONENT_SUFFIX doc)
endif(NOT DEFINED REMAKE_DOC_CMAKE)

### \brief Configure ReMake documentation task support.
#   This macro initializes all the ReMake documentation task variables from
#   the arguments provided or from default values. It should be called in the 
#   project root's CMakeLists.txt file, before any other documentation macro.
#   \required[list] type Defines the types of documentation to be generated 
#     by all documentation macros. Common document types are man, html, latex, 
#     etc. Note that the types provided here must be supported by all 
#     generators used throughout the project.
#   \optional[list] OUTPUT:dir An optional list of output directories, one
#     for each document type, that is passed to the document generator. The
#     directories define relative paths below ${CMAKE_CURRENT_BINARY_DIR} and
#     default to a filename conversion of the respective document type.
#   \optional[list] INSTALL:dir An optional list of directories defining the 
#     install destintations for the given document types. All directories
#     default to the project's ${DOCUMENTATION_DESTINATION}. See
#     remake_doc_install() for details.
#   \optional[value] CONFIGURATION:dir The directory containing the project
#     document configuration, defaults to doc.
macro(remake_doc)
  remake_arguments(PREFIX doc_ VAR OUTPUT VAR INSTALL VAR CONFIGURATION
    ARGN types ${ARGN})
  remake_set(doc_configuration SELF DEFAULT doc)

  foreach(doc_type ${doc_types})
    remake_file_name(doc_file ${doc_type})
    remake_list_pop(doc_output doc_type_output DEFAULT ${doc_file})
    remake_project_get(DOCUMENTATION_DESTINATION)
    remake_list_pop(doc_install doc_type_install
      DEFAULT ${DOCUMENTATION_DESTINATION})

    remake_project_set(DOC_${doc_type} ON CACHE BOOL
      "Generate documentation of type ${doc_type}.")
    remake_var_name(doc_type_var REMAKE_DOC ${doc_type})
    remake_project_get(DOC_${doc_type} OUTPUT ${doc_type_var})
    list(APPEND REMAKE_DOC_TYPES ${doc_type})

    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_set(${doc_output_var} ${doc_type_output})
    list(APPEND REMAKE_DOC_OUTPUTS ${doc_type_output})

    remake_var_name(doc_install_var REMAKE_DOC ${doc_type} DESTINATION)
    remake_set(${doc_install_var} ${doc_type_install})
    list(APPEND REMAKE_DOC_DESTINATIONS ${doc_type_install})
  endforeach(doc_type)

  if(REMAKE_DOC_TYPES)
    string(REPLACE ";" ", " doc_types "${REMAKE_DOC_TYPES}")
    message(STATUS "Documentation: ${doc_types}")

    get_filename_component(REMAKE_DOC_CONFIGURATION_DIR
      ${doc_configuration} ABSOLUTE)
    if(EXISTS ${REMAKE_DOC_CONFIGURATION_DIR})
      remake_add_directories(${REMAKE_DOC_CONFIGURATION_DIR})
    endif(EXISTS ${REMAKE_DOC_CONFIGURATION_DIR})
  else(REMAKE_DOC_TYPES)
    message(STATUS "Documentation: not available")
  endif(REMAKE_DOC_TYPES)
endmacro(remake_doc)

### \brief Evaluate support for the documentation types requested.
#   This macro is a helper macro to evaluate generator support for the 
#   documentation types requested. It emits a fatal error message if a 
#   generator lacks support for any of the types. Note that the macro
#   gets invoked by the generator-specific macros defined in this module.
#   It should not be called directly from a CMakeLists.txt file.
#   \required[value] generator The name of the generator to be evaluated.
#   \required[list] type The list of documentation types supported by the
#      named generator.
macro(remake_doc_support doc_generator)
  remake_var_name(doc_supported_types_var REMAKE_DOC ${doc_generator}
    SUPPORTED_TYPES)
  remake_var_name(doc_types_var REMAKE_DOC ${doc_generator} TYPES)

  remake_set(${doc_supported_types_var} ${ARGN})
  remake_list_contains(${doc_supported_types_var} ${REMAKE_DOC_TYPES} 
    CONTAINED ${doc_types_var})

  if(NOT ${doc_types_var})
    message(FATAL_ERROR "Document generator ${doc_generator} "
      "fails to support any type requested!")
  endif(NOT ${doc_types_var})
endmacro(remake_doc_support)

### \brief Generate documentation from source.
#   This macro simply defines documentation install rules for pre-built
#   documentation files and may therefore not be regarded as an actual
#   generator. However, the macro correctly considers the output directories
#   specified with the document types when evaluating the install destination
#   of documents. Note that the directory structure below
#   ${CMAKE_CURRENT_SOURCE_DIR} will be preserved during installation.
#   \required[value] type The document type of the pre-built documentation
#     files.
#   \required[list] glob A list of glob expressions resolving to the pre-built
#     documentation files.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_DOC_COMPONENT_SUFFIX}. See ReMakeComponent
#     for details.
macro(remake_doc_source doc_type)
  remake_arguments(PREFIX doc_ VAR COMPONENT ARGN globs ${ARGN})
  remake_component_name(doc_default_component ${REMAKE_COMPONENT}
    ${REMAKE_DOC_COMPONENT_SUFFIX})
  remake_set(doc_component SELF DEFAULT ${doc_default_component})

  remake_doc_support(source ${doc_type})

  remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
  remake_var_name(doc_install_var REMAKE_DOC ${doc_type} DESTINATION)
  remake_file_glob(doc_files ${doc_globs}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} RELATIVE)

  foreach(doc_file ${doc_files})
    get_filename_component(doc_path ${doc_file} PATH)
    remake_component_install(
      FILES ${doc_file}
      DESTINATION ${${doc_install_var}}/${${doc_output_var}}/${doc_path}
      COMPONENT ${doc_component})
  endforeach(doc_file)
endmacro(remake_doc_source)

### \brief Generate documentation from source file configuration.
#   This macro defines documentation build and install rules using source
#   file configuration. It calls remake_file_configure() for a list of file
#   templates in order to generate documentation. The configured files are
#   placed into the output directory defined for the specified documentation
#   type. See ReMakeFile for details.
#   \required[value] type The document type of the file templates.
#   \required[list] glob A list of glob expressions resolving to the
#     documentation file templates. Note that each file gets configured and
#     processed independently, disregarding any output conflicts.
#   \optional[value] INSTALL:dirname The optional install directory that is
#     passed to remake_doc_install() for defining the install rules.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_doc_install() for defining the
#     install rules.
macro(remake_doc_configure doc_type)
  remake_arguments(PREFIX doc_ VAR INSTALL VAR COMPONENT ARGN globs ${ARGN})

  remake_doc_support(source ${doc_type})

  remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
  remake_set(doc_output_dir ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}})
  remake_file_mkdir(${doc_output_dir})

  remake_file_glob(doc_files FILES ${doc_globs})
  foreach(doc_file ${doc_files})
    remake_file_configure(${doc_file} DESTINATION ${doc_output_dir})
  endforeach(doc_file)

  remake_doc_install(TYPES ${doc_type} ${INSTALL} ${COMPONENT})
endmacro(remake_doc_configure)

### \brief Generate Doxygen documentation.
#   This macro defines documentation build and install rules for the Doxygen
#   generator. It configures a list of Doxygen configuration files using
#   remake_file_configure() and adds generator commands to the component
#   target. See ReMakeFile for details on file configuration, the ReMakeDoc 
#   variable listing and ReMakeProject for useful configuration variables.
#   \required[list] glob A list of glob expressions resolving to Doxygen
#     configuration files. Note that each file gets configured and processed
#     independently, disregarding any output conflicts.
#   \required[list] INPUT:glob A list of glob expressions that
#     resolves to a set of input directories for Doxygen, defaults to
#     ${REMAKE_PROJECT_SOURCE_DIR} and ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[list] PATTERNS:pattern An optional list of glob patterns that
#     are used to filter input files for Doxygen, defaults to *.dox, *.h,
#     *.hpp, and *.tpp.
#   \optional[list] TYPES:type Defines the types of documentation generated
#     by Doxygen. The default types are html, chi, latex, rtf, and xml. Note
#     that we have refrained from making man a default type for the Doxygen
#     generator as it usually produces vast amounts of cluttered manual pages
#     from source code.
#   \optional[value] MAIN_PAGE:glob An optional glob expression resolving
#     to one or multiple files which will be configured using
#     remake_file_configure() and provide the main page content of the
#     Doxygen documentation. By default, this glob expression is *.dox.remake.
#     Note that Doxygen will automatically pick up the configured files
#     from the special input directory ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[value] OUTPUT:dirname An optional directory name that
#     identifies the base output directory for Doxygen, defaults to
#     ${CMAKE_CURRENT_BINARY_DIR}. Note that the base output directory will
#     automatically be suffixed by the filename conversion of the current
#     document type.
#   \optional[value] INSTALL:dirname The optional install directory that is
#     passed to remake_doc_install() for defining the install rules.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_doc_generate() and
#     remake_doc_install() for defining the build and install rules,
#     respectively.
macro(remake_doc_doxygen)
  remake_arguments(PREFIX doc_ LIST INPUT LIST PATTERNS LIST TYPES
    VAR MAIN_PAGE VAR OUTPUT VAR INSTALL VAR COMPONENT ARGN globs ${ARGN})
  remake_set(doc_input SELF DEFAULT ${REMAKE_PROJECT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR})
  remake_set(doc_patterns SELF DEFAULT *.dox DEFAULT *.h DEFAULT *.hpp
    DEFAULT *.tpp)
  remake_set(doc_types SELF DEFAULT html chi latex rtf xml)
  remake_set(doc_main_page SELF DEFAULT *.dox.remake)
  remake_set(doc_output SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  if(NOT DEFINED DOXYGEN_FOUND)
    remake_find_package(Doxygen QUIET)
  endif(NOT DEFINED DOXYGEN_FOUND)

  if(DOXYGEN_FOUND)
    remake_doc_support(doxygen ${doc_types})
    remake_list_push(REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES man)
    remake_list_remove_duplicates(REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES)
    
    remake_file_glob(doc_input_dirs DIRECTORIES ${doc_input})
    remake_file_glob(doc_input_files ${doc_patterns} RECURSE ${doc_input_dirs})
    string(REPLACE ";" " " REMAKE_DOC_INPUT "${doc_input_dirs}")
    string(REPLACE ";" " " REMAKE_DOC_PATTERNS "${doc_patterns}")
    remake_file_glob(doc_files ${doc_globs})
    remake_file_configure(${doc_main_page} OUTPUT doc_main_configured)

    foreach(doc_type ${REMAKE_DOC_DOXYGEN_TYPES})
      remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
      remake_set(doc_output_dir ${doc_output}/${${doc_output_var}})

      foreach(doc_supported_type ${REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES})
        remake_var_name(doc_type_var REMAKE_DOC ${doc_supported_type})
        if(${doc_type} STREQUAL ${doc_supported_type})
          remake_set(${doc_type_var} YES)
        else(${doc_type} STREQUAL ${doc_supported_type})
          remake_set(${doc_type_var} NO)
        endif(${doc_type} STREQUAL ${doc_supported_type})
      endforeach(doc_supported_type)

      foreach(doc_file ${doc_files})
        remake_file_configure(${doc_file} EXT ${doc_type}
          OUTPUT doc_configured)
        file(RELATIVE_PATH doc_relative ${CMAKE_BINARY_DIR} ${doc_output_dir})
        remake_doc_generate(doxygen ${doc_type}
          COMMAND ${DOXYGEN_EXECUTABLE} ${doc_configured}
          DEPENDS ${doc_input_files} ${doc_configured} ${doc_main_configured}
          COMMENT "Generating Doxygen documentation ${doc_relative}"
          OUTPUT ${doc_output_dir}
          ${COMPONENT})
      endforeach(doc_file)
    endforeach(doc_type)

    remake_doc_install(
      TYPES ${REMAKE_DOC_DOXYGEN_TYPES}
      OUTPUT ${doc_output}
      ${INSTALL} ${COMPONENT})
  endif(DOXYGEN_FOUND)
endmacro(remake_doc_doxygen)

### \brief Generate GNU Troff documentation.
#   This macro defines documentation build and install rules for the GNU
#   Troff (groff) generator. Unlike Doxygen, groff does not generate
#   documentation from documented source code, but takes formatted
#   input to create HTML or PostScript documents. For details, see groff(1).
#   \required[list] glob A list of glob expressions resolving to groff input
#     files. The files must contain formatted input that can be interpreted
#     by the named groff macro.
#   \optional[value] MACRO:macro The groff macro to be used for interpreting 
#     the input, defaults to man.
#   \optional[value] OUTPUT:dirname An optional directory name that
#     identifies the base output directory for groff, defaults to
#     ${CMAKE_CURRENT_BINARY_DIR}. Note that the base output directory will
#     automatically be suffixed by the filename conversion of the current
#     document type.
#   \optional[value] INSTALL:dirname The optional install directory that is
#     passed to remake_doc_install() for defining the install rules.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_doc_generate() and
#     remake_doc_install() for defining the build and install rules,
#     respectively.
macro(remake_doc_groff)
  remake_arguments(PREFIX doc_ VAR MACRO VAR OUTPUT VAR INSTALL VAR COMPONENT
    ARGN globs ${ARGN})
  remake_set(doc_macro SELF DEFAULT man)
  remake_set(doc_output SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  if(NOT DEFINED GROFF_FOUND)
    remake_find_executable(groff)
  endif(NOT DEFINED GROFF_FOUND)

  if(GROFF_FOUND)
    remake_doc_support(groff man ascii utf8 html ps)
    foreach(doc_type ${REMAKE_DOC_GROFF_TYPES})
      remake_var_name(doc_output_var REMAKE_DOC ${doc_macro} OUTPUT)
      remake_set(doc_output_dir ${doc_output}/${${doc_output_var}})
      remake_file_mkdir(${doc_output_dir})

      if(${doc_macro} STREQUAL ${doc_type})
        remake_file_configure(${doc_globs} DESTINATION ${doc_output_dir})
      else(${doc_macro} STREQUAL ${doc_type})
        string(REGEX REPLACE "^m" "" doc_macro_file ${doc_macro})
        remake_file_glob(doc_files ${doc_globs})
        remake_file_name(doc_extension ${doc_type})

        remake_set(doc_commands)
        remake_set(doc_output_files)
        foreach(doc_file ${doc_files})
          get_filename_component(doc_name ${doc_file} NAME)
          remake_set(doc_output_file
            ${doc_output_dir}/${doc_name}.${doc_extension})
          remake_list_push(doc_commands
            COMMAND ${GROFF_EXECUTABLE} -t -e -m${doc_macro_file}
              -T${doc_type} ${doc_file} > ${doc_output_file})
          remake_list_push(doc_output_files ${doc_output_file})
        endforeach(doc_file)

        file(RELATIVE_PATH doc_relative ${CMAKE_BINARY_DIR} ${doc_output_dir})
        remake_doc_generate(groff ${doc_type}
          ${doc_commands}
          DEPENDS ${doc_macro_file} ${doc_files}
          COMMENT "Generating groff documentation ${doc_relative}"
          OUTPUT ${doc_output_files}
          ${COMPONENT})
      endif(${doc_macro} STREQUAL ${doc_type})
    endforeach(doc_type)

    remake_doc_install(
      TYPES ${REMAKE_DOC_TYPES}
      OUTPUT ${doc_output}
      ${INSTALL} ${COMPONENT})
  endif(GROFF_FOUND)
endmacro(remake_doc_groff)

### \brief Generate documentation from an executable target for this target.
#   This macro defines documentation build and install rules for generators
#   which represent executable targets in the project and which know how
#   to generate their documentation themselves.
#   \required[list] target A list of target names referring to valid 
#     executable targets in the project. For each generator target, the
#     corresponding executable gets called with the provided list of command
#     line arguments and is expected to produce a file whose name corresponds
#     to the specified output filename. The current target and its executable
#     name may be substituted in this output filename for the command-line
#     placeholder %TARGET% and %EXECUTABLE%, respectively.
#   \optional[list] ARGS:arg An optional list of command line arguments to be
#     passed to the generator target when being executed. Placeholders may be
#     used for command-line substitution of arguments to the generator target
#     executable. Details are provided with the corresponding macro parameters.
#   \optional[value] LINK_ALTERNATIVES:lib An optional generic library name
#     with alternatives installed in the system. The macro passes the generic
#     library name to remake_debian_get_alternatives() in order to find its
#     alternative names. For each alternative library name, the target
#     executables will be called with the LD_PRELOAD environment variable
#     set to the alternative. Further, a prefix-stripped and filename
#     extension-stripped library name conversion of the current alternative
#     may be substituted in the output filename for the special placeholder
#     %ALTERNATIVE%. Targets may thus generate specific documentation for 
#     different alternatives of a library they depend on. See ReMakeDebian
#     for additional information.
#   \optional[value] OUTPUT_DIRECTORY:dirname An optional directory name that
#     identifies the base output directory for all target generators, defaults
#     to ${CMAKE_CURRENT_BINARY_DIR}. Note that the base output directory will
#     automatically be suffixed by the filename conversion of the current
#     document type.
#   \required[value] OUTPUT_FILE:filename The filename that identifies the
#     output file of a document generator target when being executed, relative
#     to the output directory. As output filenames must be unique, i.e.,
#     target-specific and type-specific, the placeholders %TARGET%,
#     %EXECUTABLE%, %TYPE%, and %ALTERNATIVE% may be used. The full-path
#     target-specific and type-specific output filenames may further be 
#     substituted for the command-line placeholder %OUTPUT%.
#   \optional[option] MAKE_DIRECTORIES As some target generators may expect
#     their output directories to exist, this option causes the macro to
#     create these directories during the configuration stage of CMake.
#   \optional[list] TYPES:type The optional list of document types generated
#     by the target executables, defaults to ${REMAKE_DOC_TYPES}. For each 
#     document type requested, the executables get called with the provided
#     list of command line arguments and are expected to produce a file whose
#     name corresponds to the specified output filename. The current document
#     type may be substituted in the list of arguments for the command-line
#     placeholder %TYPE%. Likewise, it replaces %TYPE% in the output filename.
#   \optional[value] INSTALL:dirname The optional install directory that is
#     passed to remake_doc_install() for defining the install rules.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_doc_generate() and
#     remake_doc_install() for defining the build and install rules,
#     respectively.
macro(remake_doc_targets)
  remake_arguments(PREFIX doc_ LIST ARGS LIST LINK_ALTERNATIVES LIST TYPES
    VAR INSTALL VAR COMPONENT VAR OUTPUT_DIRECTORY VAR OUTPUT_FILE
    OPTION MAKE_DIRECTORIES ARGN targets ${ARGN})
  remake_set(doc_types SELF DEFAULT ${REMAKE_DOC_TYPES})
  remake_set(doc_output_directory SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  remake_unset(doc_alternatives)
  if(doc_link_alternatives)
    remake_debian_get_alternatives(${doc_link_alternatives}
      OUTPUT doc_alternatives)
  endif(doc_link_alternatives)
  
  foreach(doc_target ${doc_targets})
    remake_doc_support(${doc_target} ${doc_types})
    remake_var_name(doc_types_var REMAKE_DOC ${doc_target} TYPES)

    foreach(doc_type ${${doc_types_var}})
      remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
      remake_set(doc_output_dir ${doc_output_directory}/${${doc_output_var}})
      get_target_property(doc_target_executable ${doc_target} OUTPUT_NAME)
      get_target_property(doc_target_location ${doc_target} LOCATION)

      remake_set(doc_output ${doc_output_dir}/${doc_output_file})
      string(REPLACE "%TYPE%" "${doc_type}" doc_output ${doc_output})
      string(REPLACE "%TARGET%" "${doc_target}" doc_output ${doc_output})
      string(REPLACE "%EXECUTABLE%" "${doc_target_executable}" doc_output
        ${doc_output})
      
      remake_set(doc_type_args ${doc_args})
      remake_list_replace(doc_type_args %TYPE% REPLACE ${doc_type} VERBATIM)
      remake_list_replace(doc_type_args %TARGET% REPLACE ${doc_target}
         VERBATIM)
      remake_list_replace(doc_type_args %EXECUTABLE% REPLACE
        ${doc_target_executable} VERBATIM)

      if(doc_alternatives)
        foreach(doc_alternative ${doc_alternatives})
          get_filename_component(doc_alternative_we ${doc_alternative} NAME_WE)
          string(REGEX REPLACE "^${CMAKE_SHARED_LIBRARY_PREFIX}" "" doc_alt
            ${doc_alternative_we})                  
          string(REPLACE "%ALTERNATIVE%" "${doc_alt}" doc_output_alt
            ${doc_output})
          
          remake_set(doc_type_args_alt ${doc_type_args})
          remake_list_replace(doc_type_args_alt %OUTPUT% REPLACE
            ${doc_output_alt} VERBATIM)
          
          if(doc_make_directories)
            get_filename_component(doc_output_path ${doc_output_alt} PATH)
            remake_file_mkdir(${doc_output_path})
          endif(doc_make_directories)
          
          file(RELATIVE_PATH doc_relative ${CMAKE_BINARY_DIR}
            ${doc_output_alt})
          remake_set(LD_PRELOAD ${doc_alternative})
          remake_doc_generate(${doc_target}_${doc_alt} ${doc_type}
            COMMAND ${doc_target_location} ${doc_type_args_alt}
            DEPENDS ${doc_target}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating ${doc_target} documentation ${doc_relative}"
            OUTPUT ${doc_output_alt}
            ENVIRONMENT LD_PRELOAD
            ${COMPONENT})
        endforeach(doc_alternative)
      else(doc_alternatives)
        remake_list_replace(doc_type_args %OUTPUT% REPLACE ${doc_output}
          VERBATIM)
          
        if(doc_make_directories)
          get_filename_component(doc_output_path ${doc_output} PATH)
          remake_file_mkdir(${doc_output_path})
        endif(doc_make_directories)
          
        file(RELATIVE_PATH doc_relative ${CMAKE_BINARY_DIR} ${doc_output})
        remake_doc_generate(${doc_target} ${doc_type}
          COMMAND ${doc_target_location} ${doc_type_args}
          DEPENDS ${doc_target}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT "Generating ${doc_target} documentation ${doc_relative}"
          OUTPUT ${doc_output}
          ${COMPONENT})
      endif(doc_alternatives)
    endforeach(doc_type)

    remake_doc_install(
      TYPES ${${doc_types_var}}
      OUTPUT ${doc_output_directory}
      ${INSTALL} ${COMPONENT})
  endforeach(doc_target)
endmacro(remake_doc_targets)

### \brief Generate documentation using a custom generator.
#   This macro defines documentation build and install rules for a custom
#   generator, such as a script. It adds the provided generator command to 
#   the component target.
#   \required[value] generator The name of the custom generator.
#   \required[value] command The command that executes the custom generator.
#     Assuming that the generator is provided with the sources, the working 
#     directory for this command defaults to ${CMAKE_CURRENT_SOURCE_DIR}.
#     Placeholders may be used for command-line substitution of arguments
#     to the generator command. Details are provided with the corresponding
#     macro parameters.
#   \optional[list] arg An optional list of command line arguments to be
#     passed to the generator command.
#   \required[list] INPUT:glob A list of glob expressions that resolves to
#     a set of input files for the generator. The list of input files may
#     be substituted for the command-line placeholder %INPUT%.
#   \optional[value] OUTPUT:dirname An optional directory name that identifies
#     the base output directory for the document generator, defaults to
#     ${CMAKE_CURRENT_BINARY_DIR}. Note that the base output directory will
#     automatically be suffixed by the filename conversion of the current
#     document type. The type-specific output directories may be substituted
#     for the command-line placeholder %OUTPUT%.
#   \optional[list] TYPES:type The optional list of document types generated
#     by the custom generator, defaults to ${REMAKE_DOC_TYPES}. For each 
#     document type requested, the generator gets called with the provided
#     list of command line arguments. The current document type may be
#     substituted in this list for the command-line placeholder %TYPE%.
#   \optional[value] INSTALL:dirname The optional install directory that is
#     passed to remake_doc_install() for defining the install rules.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_doc_generate() and
#     remake_doc_install() for defining the build and install rules,
#     respectively.
macro(remake_doc_custom doc_generator doc_command)
  remake_arguments(PREFIX doc_ LIST TYPES VAR INSTALL VAR COMPONENT LIST INPUT
    LIST OUTPUT ARGN custom_args ${ARGN})
  remake_set(doc_types SELF DEFAULT ${REMAKE_DOC_TYPES})
  remake_set(doc_output SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  remake_doc_support(${doc_generator} ${doc_types})
  remake_var_name(doc_types_var REMAKE_DOC ${doc_generator} TYPES)

  remake_file_glob(doc_inputs ${doc_input})
  remake_list_replace(doc_custom_args %INPUT% REPLACE ${doc_inputs} VERBATIM)

  foreach(doc_type ${${doc_types_var}})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_set(doc_output_dir ${doc_output}/${${doc_output_var}})

    remake_set(doc_type_args ${doc_custom_args})
    remake_list_replace(doc_type_args %TYPE% REPLACE ${doc_type} VERBATIM)
    remake_list_replace(doc_type_args %OUTPUT% REPLACE ${doc_output_dir}
      VERBATIM)

    file(RELATIVE_PATH doc_relative ${CMAKE_BINARY_DIR} ${doc_output_dir})
    remake_doc_generate(${doc_generator} ${doc_type}
      COMMAND ${doc_command} ${doc_type_args}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${doc_inputs}
      COMMENT "Generating ${doc_generator} documentation ${doc_relative}"
      OUTPUT ${doc_output_dir}
      ${COMPONENT})
  endforeach(doc_type)

  remake_doc_install(
    TYPES ${${doc_types_var}}
    OUTPUT ${doc_output}
    ${INSTALL} ${COMPONENT})
endmacro(remake_doc_custom)

### \brief Add documentation build rule.
#   This macro is a helper macro to define documentation build rules. Note
#   that the macro gets invoked by the generator-specific macros defined in
#   this module. In most cases, it will therefore not be necessary to call it
#   directly from a CMakeLists.txt file.
#   \required[value] generator The document generator for this rule. Note
#     that here the document generator will only be used to construct a
#     generator-specific and type-specific documentation target name.
#   \required[value] type The document type that will be built by this
#     rule. Note that here the document type will only be used to construct
#     a generator-specific and type-specific documentation target name.
#   \optional[list] ENVIRONMENT:var An optional list of variable names
#     known to CMake which will be set as environment variables to the
#     generator command. Sine CMake does not provide a portable solution
#     for setting the environment of a custom command, the variable
#     definitions are instead prepended to the generator command as VAR=${VAR}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_add_command(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_DOC_COMPONENT_SUFFIX}. See ReMakeComponent
#     for details.
#   \optional[list] arg Additional arguments to be passed on to
#     remake_component_add_command(). See ReMakeComponent for details.
macro(remake_doc_generate doc_generator doc_type)
  remake_arguments(PREFIX doc_ VAR COMMAND LIST ENVIRONMENT VAR COMPONENT
    ARGN generate_args ${ARGN})
  remake_component_name(doc_default_component ${REMAKE_COMPONENT}
    ${REMAKE_DOC_COMPONENT_SUFFIX})
  remake_set(doc_component SELF DEFAULT ${doc_default_component})

  remake_unset(doc_generate_env)
  foreach(doc_env ${doc_environment})
    remake_list_push(doc_generate_env "${doc_env}=${${doc_env}}")
  endforeach(doc_env)
  if(doc_generate_env)
    string(REPLACE ";" ";&&;" doc_generate_env "${doc_generate_env}")
  endif(doc_generate_env)
  
  remake_target_name(doc_as_target ${doc_generator} ${doc_type})
  remake_component_add_command(
    COMMAND ${doc_generate_env} ${doc_command}
    ${doc_generate_args}
    AS ${doc_as_target}
    COMPONENT ${doc_component})
endmacro(remake_doc_generate)

### \brief Add documentation install rule.
#   This macro is a helper macro to define documentation install rules for
#   all requested document types. It expects generated documentation content
#   in the defined output location of the build directory. Note that the macro
#   gets invoked by the generator-specific macros defined in this module. In
#   most cases, it will therefore not be necessary to call it directly from a
#   CMakeLists.txt file.
#   \required[list] TYPES:type The list of documentation types for which to
#     add install rules. Each type may be substituted for the install directory
#     placeholder %TYPE%, thus allowing for the definition of alternative
#     type-specific install destinations.
#   \optional[value] OUTPUT:dirname An optional directory name that identifies
#     the common base output directory for all document types, defaults to
#     ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[value] INSTALL:dirname The directory that shall be passed as the
#     documentation's install destination, defaults to the install destination
#     of each document type given.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_DOC_COMPONENT_SUFFIX}. See ReMakeComponent
#     for details.
#   \optional[list] arg Additional arguments to be passed on to
#     remake_component_install(). See ReMakeComponent for details.
macro(remake_doc_install)
  remake_arguments(PREFIX doc_ LIST TYPES VAR OUTPUT VAR INSTALL VAR COMPONENT
    ARGN install_args ${ARGN})
  remake_set(doc_output SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})
  remake_component_name(doc_default_component ${REMAKE_COMPONENT}
    ${REMAKE_DOC_COMPONENT_SUFFIX})
  remake_set(doc_component SELF DEFAULT ${doc_default_component})

  foreach(doc_type ${doc_types})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_var_name(doc_install_var REMAKE_DOC ${doc_type} DESTINATION)
    remake_set(doc_destination FROM doc_install DEFAULT ${${doc_install_var}})
    string(REPLACE "%TYPE%" "${doc_type}" doc_destination ${doc_destination})

    remake_component_install(
      DIRECTORY ${doc_output}/${${doc_output_var}}
      DESTINATION ${doc_destination}
      COMPONENT ${doc_component}
      ${doc_install_args})
  endforeach(doc_type)
endmacro(remake_doc_install)
