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
#   \variable REMAKE_DOC_TARGET The name of the documentation target
#     containing the document build rules.

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
#     default to share/doc/${REMAKE_PROJECT_FILENAME}. See remake_doc_install() 
#     for details.
#   \optional[value] CONFIGURATION:dir The directory containing the project
#     document configuration, defaults to doc.
macro(remake_doc)
  remake_arguments(PREFIX doc_ VAR OUTPUT VAR INSTALL VAR CONFIGURATION 
    ARGN types ${ARGN})

  foreach(doc_type ${doc_types})
    remake_file_name(doc_file ${doc_type})
    remake_list_pop(doc_output doc_type_output DEFAULT ${doc_file})
    remake_list_pop(doc_install doc_type_install 
      DEFAULT "share/doc/${REMAKE_PROJECT_FILENAME}")

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
    message(STATUS "Documentation: ${REMAKE_DOC_TYPES}")
    remake_set(REMAKE_DOC_TARGET documentation)
  else(REMAKE_DOC_TYPES)
    message(STATUS "Documentation: not available")
  endif(REMAKE_DOC_TYPES)

  remake_set(REMAKE_DOC_CONFIGURATION_DIR ${doc_configuration} DEFAULT doc)
  if(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_DOC_CONFIGURATION_DIR})
    remake_add_directories(${REMAKE_DOC_CONFIGURATION_DIR})
  endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_DOC_CONFIGURATION_DIR})

  remake_target(${REMAKE_DOC_TARGET} ALL)
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
    message(FATAL_ERROR 
    "Document generator ${doc_generator} fails to support any type requested!")
  endif(NOT ${doc_types_var})
endmacro(remake_doc_support)

### \brief Generate Doxygen documentation.
#   This macro defines documentation build and install rules for the Doxygen
#   generator. It configures a list of Doxygen configuration files using
#   remake_file_configure() and adds generator commands to the documentation
#   target. See ReMakeFile for details on file configuration, the ReMakeDoc 
#   variable listing and ReMakeProject for useful configuration variables.
#   \required[list] glob A list of glob expressions resolving to Doxygen
#     configuration files. Note that each file gets configured and processed
#     independently, disregarding any output conflicts.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_doc_install() for defining the
#     install rule.
macro(remake_doc_doxygen)
  remake_arguments(PREFIX doc_ VAR COMPONENT ARGN globs ${ARGN})

  if(NOT DEFINED DOXYGEN_FOUND)
    remake_find_package(Doxygen QUIET)
    if(DOXYGEN_FOUND)
      remake_doc_support(doxygen html chi latex rtf man xml)
    endif(DOXYGEN_FOUND)
  endif(NOT DEFINED DOXYGEN_FOUND)

  if(DOXYGEN_FOUND)
    foreach(doc_type ${REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES})
      remake_var_name(doc_type_var REMAKE_DOC ${doc_type})
      remake_list_contains(REMAKE_DOC_TYPES ${doc_type} ALL doc_contains)
      if(doc_contains)
        remake_set(${doc_type_var} YES)
      else(doc_contains)
        remake_set(${doc_type_var} NO)
      endif(doc_contains)
    endforeach(doc_type)

    remake_file_configure(${doc_globs} OUTPUT doc_files)

    foreach(doc_file ${doc_files})
      remake_target_add_command(${REMAKE_DOC_TARGET}
        COMMAND ${DOXYGEN_EXECUTABLE} ${doc_file})
    endforeach(doc_file)

    remake_doc_install(${REMAKE_DOC_TYPES} ${COMPONENT})
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
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_doc_install() for defining the
#     install rule.
macro(remake_doc_groff)
  remake_arguments(PREFIX doc_ VAR MACRO VAR COMPONENT ARGN globs ${ARGN})
  remake_set(doc_macro SELF DEFAULT man)

  if(NOT DEFINED GROFF_FOUND)
    remake_find_executable(groff)
    if(GROFF_FOUND)
      remake_doc_support(groff man ascii utf8 html ps)
    endif(GROFF_FOUND)
  endif(NOT DEFINED GROFF_FOUND)

  if(GROFF_FOUND)
    remake_var_name(doc_input_var REMAKE_DOC ${doc_macro} OUTPUT)
    remake_set(doc_input ${CMAKE_CURRENT_BINARY_DIR}/${${doc_input_var}})
      
    foreach(doc_type ${REMAKE_DOC_TYPES})
      remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
      remake_set(doc_output ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}})
      remake_file_mkdir(${doc_output})

      if(${doc_macro} STREQUAL ${doc_type})
        remake_file_configure(${doc_globs} DESTINATION ${doc_output})
      else(${doc_macro} STREQUAL ${doc_type})
        string(REGEX REPLACE "^m" "" doc_macro_file ${doc_macro})
        remake_file_name(doc_extension ${doc_type})

        remake_file_glob(doc_files ${doc_globs})
        foreach(doc_file ${doc_files})
          get_filename_component(doc_name ${doc_file} NAME)
          remake_target_add_command(${REMAKE_DOC_TARGET}
            COMMAND ${GROFF_EXECUTABLE} -t -e -m${doc_macro_file} 
              -T${doc_type} ${doc_file} > 
              ${doc_output}/${doc_name}.${doc_extension})
        endforeach(doc_file)
      endif(${doc_macro} STREQUAL ${doc_type})
    endforeach(doc_type)

    remake_doc_install(${REMAKE_DOC_TYPES} ${COMPONENT})
  endif(GROFF_FOUND)
endmacro(remake_doc_groff)

### \brief Generate documentation using a custom generator.
#   This macro defines documentation build and install rules for a custom
#   generator, such as a script. It adds the provided generator command to 
#   the documentation target.
#   \required[value] generator The name of the custom generator.
#   \required[value] command The command that executes the custom generator.
#     Assuming that the generator is provided with the sources, the working 
#     directory for this command defaults to ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] arg An optional list of command line arguments to be
#     passed to the generator command.
#   \optional[list] INPUT:glob An optional list of glob expressions that
#     resolves to a set of input files or directories for the generator.
#     The presence of this option causes the definition of multiple document
#     build rules, one for each input file or directory, where the input 
#     filename is appended to the generator's command line arguments.
#   \optional[list] TYPES:type The optional list of document types generated
#     by the custom generator, defaults to ${REMAKE_DOC_TYPES}. For each 
#     document type requested, the generator gets called with the document
#     type and and the name of the respective output directory added to its 
#     command line arguments.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_doc_install() for defining the
#     install rule.
macro(remake_doc_custom doc_generator doc_command)
  remake_arguments(PREFIX doc_ LIST TYPES VAR COMPONENT LIST INPUT ARGN args 
    ${ARGN})
  remake_set(doc_types SELF DEFAULT ${REMAKE_DOC_TYPES})

  remake_doc_support(${doc_generator} ${doc_types})
  remake_var_name(doc_types_var REMAKE_DOC ${doc_generator} TYPES)

  foreach(doc_type ${${doc_types_var}})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_set(doc_output_dir ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}})
    remake_file_mkdir(${doc_output_dir})

    if(doc_input)
      remake_file_glob(doc_input_files ${doc_input})
      remake_file_name(doc_extension ${doc_type})

      foreach(doc_input_file ${doc_input_files})
        get_filename_component(doc_input_name ${doc_input_file} NAME_WE)
        remake_list_pop(doc_output doc_output_file DEFAULT 
          ${doc_input_name}.${doc_extension})
        if(doc_output_file)
          remake_set(doc_output_file ${doc_output_dir}/${doc_output_file})
        endif(doc_output_file)

        remake_target_add_command(${REMAKE_DOC_TARGET}
          COMMAND ${doc_command} ${doc_args} ${doc_type} ${doc_input_file} 
            ${doc_output_dir}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
      endforeach(doc_input_file)
    else(doc_input)
      remake_target_add_command(${REMAKE_DOC_TARGET}
        COMMAND ${doc_command} ${doc_args} ${doc_type} ${doc_output_dir}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif(doc_input)
  endforeach(doc_type)

  remake_doc_install(${${doc_types_var}} ${COMPONENT})
endmacro(remake_doc_custom)

### \brief Add documentation install rule.
#   This macro is a helper macro to define documentation install rules for
#   all requested document types. It expects generated documentation content
#   in the defined output location. Note that the macro gets invoked by the 
#   generator-specific macros defined in this module. It should not be called 
#   directly from a CMakeLists.txt file.
#   \required[list] type The documentation types for which to add install
#     rules.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to CMake's install() macro. See the CMake
#     documentation for details.
macro(remake_doc_install)
  remake_arguments(PREFIX doc_ VAR COMPONENT ARGN types ${ARGN})

  foreach(doc_type ${doc_types})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_var_name(doc_install_var REMAKE_DOC ${doc_type} DESTINATION)

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}}
      DESTINATION ${${doc_install_var}} ${COMPONENT})
  endforeach(doc_type)
endmacro(remake_doc_install)
