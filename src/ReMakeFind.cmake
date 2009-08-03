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

# Emit a message on the result of a find operation.  Set the ${PACKAGE}_FOUND 
# variable. 
macro(remake_find_result find_package)
  remake_arguments(PREFIX find_ OPTION OPTIONAL ARGN result ${ARGN})
  remake_var_name(find_result_var ${find_package} FOUND)

  if(find_result)
    remake_set(${find_result_var} TRUE)
  else(find_result)
    remake_set(${find_result_var} FALSE)
    if(find_optional)
      message(STATUS "Missing ${find_package} support!")
    else(find_optional)
      message(FATAL_ERROR "Missing ${find_package} support!")
    endif(find_optional)    
  endif(find_result)
endmacro(remake_find_result)

# Find a package.
macro(remake_find_package find_package)
  remake_var_name(find_package_var ${find_package} FOUND)

  find_package(${find_package} ${ARGN})
  remake_find_result(${find_package} ${${find_package_var}} ${ARGN})
endmacro(remake_find_package)

# Find a library and its development headers.
macro(remake_find_library find_lib find_header)
  remake_arguments(PREFIX find_ VAR PACKAGE ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_lib})
  remake_var_name(find_lib_var ${find_package} LIBRARY)
  remake_var_name(find_header_var ${find_package} HEADER)

  find_library(${find_lib_var} NAMES ${find_lib})
  if(${find_lib_var})
    find_file(${find_header_var} NAMES ${find_header})
  else(${find_lib_var})
    remake_set(${find_header_var})
  endif(${find_lib_var})

  remake_find_result(${find_package} ${${find_header_var}} ${ARGN})
endmacro(remake_find_library)

# Find an executable.
macro(remake_find_executable find_exec)
  remake_arguments(prefix find_ VAR PACKAGE ${ARGN})
  remake_set(find_package SELF DEFAULT ${find_exec})
  remake_var_name(find_exec_var ${find_package} EXECUTABLE)  

  find_program(${find_exec_var} NAMES ${find_exec})

  remake_find_result(${find_package} ${${find_exec_var}} ${ARGN})
endmacro(remake_find_executable)
