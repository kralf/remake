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

### \brief ReMake Subversion macros
#   The ReMake Subversion module provides useful tools for Subversion-based
#   projects.

### \brief Retrieve the Subversion head revision.
#   This macro retrieves the Subversion head revision of the working directory.
#   The macro defines an output variable with the name provided and assigns the
#   revision number or 0 for non-versioned directories.
#   \required[value] variable The name of a variable to be assigned the 
#     revision number.
macro(remake_svn_revision svn_var)
  remake_set(${svn_var} 0)
  
  if(SUBVERSION_FOUND)
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
      execute_process(COMMAND ${Subversion_SVN_EXECUTABLE} info
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE svn_info)
      string(REGEX REPLACE ".*Revision: ([0-9]*).*" "\\1" ${svn_var}
        ${svn_info})
    endif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
  endif(SUBVERSION_FOUND)
endmacro(remake_svn_revision)

### \brief Define a Subversion log target.
#   This macro defines a top-level target and a build rule for the acquisition
#   of Subversion log messages in the working directory. It may be used to
#   dump a project's Subversion log into a file during build.
#   \required[value] filename The name of the file to write the Subversion
#     log messages to, relative to ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[value] TARGET:name The optional name of the target for which 
#     the Subversion log build rule is defined, defaults to svn_log.
#   \optional[value] COMMENT:string An optional comment string that is
#     printed during the build target's execution.
#   \optional[value] REVISION:rev The Subversion revision for which to
#     request the log information, defaults to BASE:HEAD. See the Subversion
#     documentation for details.
#   \optional[var] OUTPUT:variable The optional name of a variable to be
#     assigned the absolute-path output filename.
macro(remake_svn_log svn_file)
  remake_arguments(PREFIX svn_ VAR TARGET VAR COMMENT VAR REVISION VAR OUTPUT
    ${ARGN})
  remake_set(svn_target SELF DEFAULT svn_log)
  remake_set(svn_revision SELF DEFAULT BASE:HEAD)
  
  if(SUBVERSION_FOUND)
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
      if(NOT IS_ABSOLUTE ${svn_file})
        remake_set(svn_absolute ${CMAKE_CURRENT_BINARY_DIR}/${svn_file})
    else(NOT IS_ABSOLUTE ${svn_file})
        remake_set(svn_absolute ${svn_file})
      endif(NOT IS_ABSOLUTE ${svn_file})
  
      remake_target(${svn_target} ALL 
        COMMAND ${Subversion_SVN_EXECUTABLE} log -r ${svn_revision}
          ${CMAKE_CURRENT_SOURCE_DIR} > ${svn_absolute}
        DEPENDS 
        ${COMMENT})
      if(svn_output)
        remake_set(${svn_output} ${svn_absolute})
      endif(svn_output)
    endif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
  endif(SUBVERSION_FOUND)
endmacro(remake_svn_log)

remake_find_package(Subversion QUIET)
