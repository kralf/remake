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

# Parse macro arguments. Return optional arguments and the list of arguments
# given pass the last optional argument.
macro(remake_arguments)
  set(var_names)
  set(opt_names)
  set(argn_name)  
  set(arguments)

  set(push_var)
  foreach(arg ${ARGN})
    if(push_var)
      list(APPEND ${push_var} ${arg})
      set(push_var)
    else(push_var)
      if(arg STREQUAL VAR)
        set(push_var var_names)
      elseif(arg STREQUAL OPTION)
        set(push_var opt_names)
      elseif(arg STREQUAL ARGN)
        set(push_var argn_name)
      else(arg STREQUAL VAR)
        list(APPEND arguments ${arg})
      endif(arg STREQUAL VAR)
    endif(push_var)
  endforeach(arg)
  
  foreach(var_name ${var_names})
    set(${var_name})
  endforeach(var_name)
  foreach(opt_name ${opt_names})
    set(${opt_name} OFF)
  endforeach(opt_name)
  if(argn_name)
    set(${argn_name})
  endif(argn_name)

  set(var_name)
  foreach(arg ${arguments})
    if(var_name)
      list(APPEND ${var_name} ${arg})
      set(var_name)
    else(var_name)
      list(FIND var_names ${arg} var_found)
      list(FIND opt_names ${arg} opt_found)

      if(var_found GREATER -1)
        list(GET var_names ${var_found} var_name)
      elseif(opt_found GREATER -1)
        list(GET opt_names ${opt_found} opt_name)
        set(${opt_name} ${opt_name})
      else(var_found GREATER -1)
        list(APPEND ${argn_name} ${arg})
      endif(var_found GREATER -1)
    endif(var_name)
  endforeach(arg)
endmacro(remake_arguments)

# Output a valid variable name from a string.
macro(remake_var_name string var_name)
  string(TOUPPER "${string}" upper_string)
  string(REPLACE " " "_" ${var_name} "${upper_string}")
endmacro(remake_var_name)

# Define the value of a variable. Optionally, set the variable value from
# another variable. Use a given default value if the variable value is 
# undefined.
macro(remake_set var_name)
  remake_arguments(VAR FROM VAR DEFAULT ARGN argn ${ARGN})

  if(FROM)
    if(${FROM})
      set(${var_name} ${${FROM}} ${argn})
    else(${FROM})
      set(${var_name} ${DEFAULT} ${argn})
    endif(${FROM})
  else(FROM)
    if(DEFINED DEFAULT)
      if(NOT ${var_name})
       set(${var_name} ${DEFAULT} ${argn})
      endif(NOT ${var_name})
    else(DEFINED DEFAULT)
      set(${var_name} ${argn})
    endif(DEFINED DEFAULT)
  endif(FROM)
endmacro(remake_set)

# Generate debugging output for ReMake.
macro(remake_debug)
  foreach(var_name ${ARGN})
    if(DEFINED ${var_name})
      message("++ ${var_name} = ${${var_name}}")
    else(DEFINED ${var_name})
      message("++ ${var_name} undefined")
    endif(DEFINED ${var_name})
  endforeach(var_name)
endmacro(remake_debug)
