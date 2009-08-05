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

# Turn on documentation support.
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
    add_subdirectory(${REMAKE_DOC_CONFIGURATION_DIR})
  endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_DOC_CONFIGURATION_DIR})

  remake_target(${REMAKE_DOC_TARGET} ALL)
endmacro(remake_doc)

# Evaluate support for the documentation types requested. Emit an error
# message if a documentation module lacks support for any of these types.
macro(remake_doc_support doc_module)
  remake_var_name(doc_support_var REMAKE_DOC ${doc_module} SUPPORTED_TYPES)
  remake_set(${doc_support_var} ${ARGN})

  remake_list_contains(${doc_support_var} ${REMAKE_DOC_TYPES} 
    MISSING doc_missing_types)
  if(doc_missing_types)
    message(FATAL_ERROR "Unsupported document type(s) for ${doc_module}: "
      "${doc_missing_types}")
  endif(doc_missing_types)
endmacro(remake_doc_support)

# Generate documentation using doxygen.
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

# Generate documentation using groff.
macro(remake_doc_groff)
  remake_arguments(PREFIX doc_ VAR MACRO VAR COMPONENT LIST PREPROCESS 
    ARGN globs ${ARGN})
  remake_set(doc_macro SELF DEFAULT man)

  if(NOT DEFINED GROFF_FOUND)
    remake_find_executable(groff)
    if(GROFF_FOUND)
      remake_doc_support(groff man ascii utf8 html ps)
    endif(GROFF_FOUND)
  endif(NOT DEFINED GROFF_FOUND)

  if(GROFF_FOUND)
    if(doc_preprocess)
      remake_target_add_command(${REMAKE_DOC_TARGET}
        COMMAND ${doc_preprocess})
    endif(doc_preprocess)

    foreach(doc_type ${REMAKE_DOC_TYPES})
      remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
      remake_set(doc_output ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}})
      remake_file_mkdir(${doc_output})

      if(${doc_macro} STREQUAL ${doc_type})
        remake_file_configure(${doc_globs} DESTINATION ${doc_output})
      else(${doc_macro} STREQUAL ${doc_type})
        string(REGEX REPLACE "^m" "" doc_macro ${doc_macro})
        remake_file_name(doc_extension ${doc_type})
        remake_file_glob(doc_files ${doc_globs})

        foreach(doc_file ${doc_files})
          get_filename_component(doc_name ${doc_file} NAME)
          remake_target_add_command(${REMAKE_DOC_TARGET}
            COMMAND ${GROFF_EXECUTABLE} -t -e -m${doc_macro} -T${doc_type} 
            ${doc_file} > ${doc_output}/${doc_name}.${doc_extension})
        endforeach(doc_file)
      endif(${doc_macro} STREQUAL ${doc_type})
    endforeach(doc_type)

    remake_doc_install(${REMAKE_DOC_TYPES} ${COMPONENT})
  endif(GROFF_FOUND)
endmacro(remake_doc_groff)

# Add documentation install targets.
macro(remake_doc_install)
  remake_arguments(PREFIX doc_ VAR COMPONENT ARGN types ${ARGN})

  foreach(doc_type ${doc_types})
    remake_var_name(doc_output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_var_name(doc_install_var REMAKE_DOC ${doc_type} DESTINATION)

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${${doc_output_var}}
      DESTINATION ${${doc_install_var}} ${COMPONENT})
  endforeach(doc_type)
endmacro(remake_doc_install)
