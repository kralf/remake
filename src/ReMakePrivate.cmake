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
# given after the last optional argument. If an argument is specified, two
# output variables will be created. For an existing argument named ${NAME}, 
# the first variable ${name} will be defined to contain the parameters passed 
# for this argument. The second variable ${NAME} will be of the form
# ${NAME} ${VALUE} and may thus easily be passed on to other macros.
macro(remake_arguments)
  set(private_prefix)
  set(private_vars)
  set(private_lists)
  set(private_opts)
  set(private_argn)  
  set(private_args)

  set(private_push)
  foreach(private_arg ${ARGN})
    if(private_push)
      list(APPEND ${private_push} ${private_arg})
      set(private_push)
    else(private_push)
      if(private_arg STREQUAL PREFIX)
        set(private_push private_prefix)
      elseif(private_arg STREQUAL VAR)
        set(private_push private_vars)
      elseif(private_arg STREQUAL LIST)
        set(private_push private_lists)
      elseif(private_arg STREQUAL OPTION)
        set(private_push private_opts)
      elseif(private_arg STREQUAL ARGN)
        set(private_push private_argn)
      else(private_arg STREQUAL VAR)
        list(APPEND private_args ${private_arg})
      endif(private_arg STREQUAL PREFIX)
    endif(private_push)
  endforeach(private_arg)
  
  foreach(private_var ${private_vars})
    set(${private_var})
    string(TOLOWER ${private_var} private_var)
    set(${private_prefix}${private_var})
  endforeach(private_var)
  foreach(private_list ${private_lists})
    set(${private_list})
    string(TOLOWER ${private_list} private_list)
    set(${private_prefix}${private_list})
  endforeach(private_list)
  foreach(private_opt ${private_opts})
    set(${private_opt})
    string(TOLOWER ${private_opt} private_opt)
    set(${private_prefix}${private_opt} OFF)
  endforeach(private_opt)
  if(private_argn)
    set(${private_prefix}${private_argn})
  endif(private_argn)

  set(private_var)
  set(private_list)
  foreach(private_arg ${private_args})
    list(FIND private_vars ${private_arg} private_var_index)
    list(FIND private_lists ${private_arg} private_list_index)
    list(FIND private_opts ${private_arg} private_opt_index)

    if(private_var_index GREATER -1)
      list(GET private_vars ${private_var_index} private_var)
      set(private_list)
    elseif(private_list_index GREATER -1)
      list(GET private_lists ${private_list_index} private_list)
      set(private_var)
    elseif(private_opt_index GREATER -1)
      list(GET private_opts ${private_opt_index} private_opt)
      set(${private_opt} ${private_prefix}${private_opt})
      string(TOLOWER ${private_opt} private_opt)
      set(${private_prefix}${private_opt} ON)
      set(private_var)
      set(private_list)
    elseif(private_var)
      if(NOT ${private_var})
        set(${private_var} ${private_var})
      endif(NOT ${private_var})
      list(APPEND ${private_var} ${private_arg})
      string(TOLOWER ${private_var} private_var)
      list(APPEND ${private_prefix}${private_var} ${private_arg})
      set(private_var)
    elseif(private_list)
      if(NOT ${private_list})
        set(${private_list} ${private_list})
      endif(NOT ${private_list})
      list(APPEND ${private_list} ${private_arg})
      string(TOLOWER ${private_list} private_list)
      list(APPEND ${private_prefix}${private_list} ${private_arg})
    else(private_var_index GREATER -1)
      list(APPEND ${private_prefix}${private_argn} ${private_arg})
    endif(private_var_index GREATER -1)
  endforeach(private_arg)
endmacro(remake_arguments)

# Output a valid variable name from a string.
macro(remake_var_name private_var)
  string(TOUPPER "${ARGN}" private_upper)
  string(REGEX REPLACE "[ ;]" "_" ${private_var} "${private_upper}")
endmacro(remake_var_name)

# Find defined variables using regular expressions.
macro(remake_var_regex private_var private_regex)
  get_cmake_property(private_globals VARIABLES)

  foreach(private_global ${private_globals})
    string(REGEX MATCH ${private_regex} private_matched ${private_global})
    if(private_matched)
      remake_list_push(${private_var} ${private_global})
    endif(private_matched)
  endforeach(private_global)
endmacro(remake_var_regex)

# Define the value of a variable. Optionally, set the variable value from
# another variable. Use a given default value if the variable value is 
# undefined.
macro(remake_set private_var)
  remake_arguments(PREFIX private_ VAR FROM VAR DEFAULT OPTION SELF 
    ARGN values ${ARGN})

  if(private_from)
    set(${private_var} ${${private_from}} ${private_values})
  else(private_from)
    if(NOT private_self)
      set(${private_var} ${private_values})
    endif(NOT private_self)
  endif(private_from)

  if(NOT ${private_var})
    if(DEFINED private_default)
      set(${private_var} ${private_default} ${private_values})
    endif(DEFINED private_default)
  endif(NOT ${private_var})
endmacro(remake_set)

# Generate debugging output for ReMake.
macro(remake_debug)
  foreach(private_var ${ARGN})
    if(DEFINED ${private_var})
      message("++ ${private_var} = ${${private_var}}")
    else(DEFINED ${private_var})
      message("++ ${private_var} undefined")
    endif(DEFINED ${private_var})
  endforeach(private_var)
endmacro(remake_debug)
