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

include(ReMakeProject)
include(ReMakeFile)
include(ReMakeComponent)

### \brief ReMake documentation macros
#   The ReMake documentation module has been designed for simple and 
#   transparent intergration of project documentation tasks with CMake.
#
#   It provides support for major document generators, such as Doxygen and
#   GNU Troff.

### \variable REMAKE_DOC_TYPES The list of documentation types to be 
#     generated.
#   \variable REMAKE_DOC_OUTPUTS The list of document output directories,
#     one directory for each type in ${REMAKE_DOC_TYPES}.
#   \variable REMAKE_DOC_DESTINATIONS The list of document install 
#     destinations, one destination directory for each type in
#     ${REMAKE_DOC_TYPES}.
#   \variable REMAKE_DOC_CONFIGURATION_DIR The directory containing the 
#     project document configuration.

remake_set(REMAKE_DOC_COMPONENT_SUFFIX doc)

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
#     ${REMAKE_PROJECT_SOURCE_DIR}.
#   \optional[list] PATTERNS:pattern An optional list of glob patterns that
#     are used to filter input files for Doxygen, defaults to *.h, *.hpp,
#     and *.tpp.
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
  remake_arguments(PREFIX doc_ LIST INPUT LIST PATTERNS VAR OUTPUT
    VAR INSTALL VAR COMPONENT ARGN globs ${ARGN})
  remake_set(doc_input SELF DEFAULT ${REMAKE_PROJECT_SOURCE_DIR})
  remake_set(doc_patterns SELF DEFAULT *.h DEFAULT *.hpp DEFAULT *.tpp)
  remake_set(doc_output SELF DEFAULT ${CMAKE_CURRENT_BINARY_DIR})

  if(NOT DEFINED DOXYGEN_FOUND)
    remake_find_package(Doxygen QUIET)
  endif(NOT DEFINED DOXYGEN_FOUND)

  if(DOXYGEN_FOUND)
    remake_doc_support(doxygen html chi latex rtf man xml)
    remake_file_glob(doc_input_dirs DIRECTORIES ${doc_input})
    remake_file_glob(doc_input_files ${doc_patterns} RECURSE ${doc_input_dirs})
    string(REPLACE ";" " " REMAKE_DOC_INPUT "${doc_input_dirs}")
    string(REPLACE ";" " " REMAKE_DOC_PATTERNS "${doc_patterns}")
    remake_file_glob(doc_files ${doc_globs})

    foreach(doc_type ${REMAKE_DOC_TYPES})
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
        remake_doc_generate(${doc_type}
          COMMAND ${DOXYGEN_EXECUTABLE} ${doc_configured}
          DEPENDS ${doc_input_files} ${doc_configured}
          COMMENT "Generating Doxygen documentation ${doc_relative}"
          OUTPUT ${doc_output_dir}
          ${COMPONENT})
      endforeach(doc_file)
    endforeach(doc_type)

    remake_doc_install(TYPES ${REMAKE_DOC_TYPES} ${INSTALL} ${COMPONENT})
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
    foreach(doc_type ${REMAKE_DOC_TYPES})
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
        remake_doc_generate(${doc_type} ${doc_commands}
          DEPENDS ${doc_macro_file} ${doc_files}
          COMMENT "Generating groff documentation ${doc_relative}"
          OUTPUT ${doc_output_files}
          ${COMPONENT})
      endif(${doc_macro} STREQUAL ${doc_type})
    endforeach(doc_type)

    remake_doc_install(TYPES ${REMAKE_DOC_TYPES} ${INSTALL} ${COMPONENT})
  endif(GROFF_FOUND)
endmacro(remake_doc_groff)

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
#     a set of input files for the generator.  The list of input files may
#     be substituted for the command-line placeholder %INPUT%.
#   \optional[value] OUTPUT:dirname An optional directory name that identifies
#     the base output directory for the document generator, defaults to
#     ${CMAKE_CURRENT_BINARY_DIR}. Note that the base output directory will
#     automatically be suffixed by the filename conversion of the current
#     document type. The type-specific output directories may be substituted
#     for the command-line placeholder %OUTPUT%.
#   \optional[list] TYPES:type The optional list of document types generated
#     by the custom generator, defaults to ${REMAKE_DOC_TYPES}. For each 
#     document type requested, the generator gets called with the document
#     type and and the name of the respective output directory added to its 
#     command line arguments. The current document type may be substituted for
#     the command-line placeholder %TYPE%.
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
  remake_list_replace(doc_custom_args %INPUT% REPLACE ${doc_inputs})

  foreach(doc_type ${${doc_types_var}})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_set(doc_output_dir ${doc_output}/${${doc_output_var}})

    remake_file_name(doc_extension ${doc_type})
    remake_set(doc_type_args ${doc_custom_args})
    remake_list_replace(doc_type_args %TYPE% REPLACE ${doc_type})
    remake_list_replace(doc_type_args %OUTPUT% REPLACE ${doc_output_dir})

    file(RELATIVE_PATH doc_relative ${CMAKE_BINARY_DIR} ${doc_output_dir})
    remake_doc_generate(${doc_type}
      COMMAND ${doc_command} ${doc_type_args}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${doc_inputs}
      COMMENT "Generating ${doc_generator} documentation ${doc_relative}"
      OUTPUT ${doc_output_dir}
      ${COMPONENT})
  endforeach(doc_type)

  remake_doc_install(TYPES ${${doc_types_var}} ${INSTALL} ${COMPONENT})
endmacro(remake_doc_custom)

### \brief Add documentation build rule.
#   This macro is a helper macro to define documentation build rules. Note
#   that the macro gets invoked by the generator-specific macros defined in
#   this module. In most cases, it will therefore not be necessary to call it
#   directly from a CMakeLists.txt file.
#   \required[value] type The document type that will be built by this
#     rule. Note that here the document type will only be used to generate
#     a component-specific documentation target name.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_add_command(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_DOC_COMPONENT_SUFFIX}. See ReMakeComponent
#     for details.
#   \optional[list] arg Additional arguments to be passed on to
#     remake_component_add_command(). See ReMakeComponent for details.
macro(remake_doc_generate doc_type)
  remake_arguments(PREFIX doc_ VAR COMPONENT ARGN generate_args ${ARGN})
  remake_component_name(doc_default_component ${REMAKE_COMPONENT}
    ${REMAKE_DOC_COMPONENT_SUFFIX})
  remake_set(doc_component SELF DEFAULT ${doc_default_component})

  remake_component_target_name(doc_target ${doc_type}
    COMPONENT ${doc_component})
  remake_component_add_command(
    ${doc_generate_args} AS ${doc_target}
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
  remake_arguments(PREFIX doc_ LIST TYPES VAR INSTALL VAR COMPONENT
    ARGN install_args ${ARGN})
  remake_component_name(doc_default_component ${REMAKE_COMPONENT}
    ${REMAKE_DOC_COMPONENT_SUFFIX})
  remake_set(doc_component SELF DEFAULT ${doc_default_component})

  foreach(doc_type ${doc_types})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_var_name(doc_install_var REMAKE_DOC ${doc_type} DESTINATION)
    remake_set(doc_destination FROM doc_install DEFAULT ${${doc_install_var}})
    string(REPLACE "%TYPE%" "${doc_type}" doc_destination ${doc_destination})

    remake_component_install(
      DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}}
      DESTINATION ${doc_destination}
      COMPONENT ${doc_component}
      ${doc_install_args})
  endforeach(doc_type)
endmacro(remake_doc_install)
