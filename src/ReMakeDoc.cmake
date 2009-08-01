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
  remake_arguments(VAR OUTPUT VAR INSTALL VAR CONFIGURATION ARGN doc_types 
    ${ARGN})

  foreach(doc_type ${doc_types})
    remake_file_name(doc_filename ${doc_type})
    remake_list_pop(OUTPUT doc_output DEFAULT ${doc_filename})
    remake_list_pop(INSTALL doc_install 
      DEFAULT "share/doc/${REMAKE_PROJECT_FILENAME}")

    remake_project_set(DOC_${doc_type} ON CACHE BOOL 
      "Generate documentation of type ${doc_type}.")
    remake_var_name(type_var REMAKE_DOC ${doc_type})
    remake_project_get(DOC_${doc_type} OUTPUT ${type_var})
    list(APPEND REMAKE_DOC_TYPES ${doc_type})

    remake_var_name(output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_set(${output_var} ${doc_output})
    list(APPEND REMAKE_DOC_OUTPUTS ${doc_output})

    remake_var_name(install_var REMAKE_DOC ${doc_type} DESTINATION)
    remake_set(${install_var} ${doc_install})
    list(APPEND REMAKE_DOC_DESTINATIONS ${doc_install})
  endforeach(doc_type)

  if(REMAKE_DOC_TYPES)
    message(STATUS "Documentation: ${REMAKE_DOC_TYPES}")
    remake_set(REMAKE_DOC_TARGET documentation)
  else(REMAKE_DOC_TYPES)
    message(STATUS "Documentation: not available")
  endif(REMAKE_DOC_TYPES)

  remake_set(REMAKE_DOC_CONFIGURATION_DIR FROM CONFIGURATION DEFAULT doc)
  if(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_DOC_CONFIGURATION_DIR})
    add_subdirectory(${REMAKE_DOC_CONFIGURATION_DIR})
  endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_DOC_CONFIGURATION_DIR})

  remake_target(${REMAKE_DOC_TARGET} ALL)
endmacro(remake_doc)

# Generate documentation using Doxygen.
macro(remake_doc_doxygen)
  remake_arguments(VAR COMPONENT ARGN glob_expressions ${ARGN})

  if(NOT DEFINED DOXYGEN_FOUND)
    find_package(Doxygen QUIET)
    remake_set(REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES html chi latex rtf man xml)
    remake_list_contains(REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES ${REMAKE_DOC_TYPES}
      MISSING missing_types)

    if(missing_types)
      message(FATAL_ERROR "Doxygen does not support: ${missing_types}")
    endif(missing_types)
  endif(NOT DEFINED DOXYGEN_FOUND)

  if(DOXYGEN_FOUND)
    foreach(doc_type ${REMAKE_DOC_DOXYGEN_SUPPORTED_TYPES})
      remake_var_name(type_var REMAKE_DOC ${doc_type})
      remake_list_contains(REMAKE_DOC_TYPES ${doc_type} ALL contains_type)
      if(contains_type)
        remake_set(${type_var} YES)
      else(contains_type)
        remake_set(${type_var} NO)
      endif(contains_type)
    endforeach(doc_type)

    remake_file_configure(${glob_expressions} OUTPUT doxy_files)

    foreach(doxy_file ${doxy_files})
      remake_target_add_command(${REMAKE_DOC_TARGET}
        COMMAND ${DOXYGEN_EXECUTABLE} ${doxy_file})
    endforeach(doxy_file)

    remake_doc_install(${REMAKE_DOC_TYPES} ${ARG_COMPONENT})
  endif(DOXYGEN_FOUND)
endmacro(remake_doc_doxygen)

macro(remake_doc_install)
  remake_arguments(VAR COMPONENT ARGN doc_types ${ARGN})

  foreach(doc_type ${doc_types})
    remake_var_name(output_var REMAKE_DOC ${doc_type} OUTPUT)
    remake_var_name(install_var REMAKE_DOC ${doc_type} DESTINATION)

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${${output_var}}
      DESTINATION ${${install_var}} ${ARG_COMPONENT})
  endforeach(doc_type)
endmacro(remake_doc_install)
