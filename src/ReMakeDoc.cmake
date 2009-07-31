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
    remake_file_name(${doc_type} doc_filename)
    remake_list_pop(OUTPUT doc_output DEFAULT ${doc_filename})
    remake_list_pop(INSTALL doc_install 
      DEFAULT "share/doc/${REMAKE_PROJECT_FILENAME}")

    remake_project_set(DOC_${doc_type} ON CACHE BOOL 
      "Generate documentation of type ${doc_type}.")

    remake_var_name(REMAKE_DOC_${doc_type} type_var)
    remake_project_get(DOC_${doc_type} OUTPUT ${type_var})
    list(APPEND REMAKE_DOC_TYPES ${doc_type})

    remake_var_name(REMAKE_DOC_${doc_type}_OUTPUT output_var)
    remake_set(${output_var} ${doc_output})
    list(APPEND REMAKE_DOC_OUTPUTS ${doc_output})

    remake_var_name(REMAKE_DOC_${doc_type}_DESTINATION install_var)
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

  remake_target(${REMAKE_DOC_TARGET})
endmacro(remake_doc)

# Generate documentation using Doxygen.
macro(remake_doc_doxygen)
  if(NOT DEFINED DOXYGEN_FOUND)
    find_package(Doxygen QUIET)
  endif(NOT DEFINED DOXYGEN_FOUND)

  if(DOXYGEN_FOUND)
    remake_file_configure(${ARGN} OUTPUT doxy_files)
    foreach(doxy_file ${doxy_files})
      remake_target_add_command(${REMAKE_DOC_TARGET}
        COMMAND ${DOXYGEN_EXECUTABLE} ${doxy_file})
    endforeach(doxy_file)
  endif(DOXYGEN_FOUND)
endmacro(remake_doc_doxygen)
