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

### \brief ReMake list macros
#   The ReMake list macros are a set of helper macros to simplify
#   operations over lists in ReMake.

### \brief Append values to the back of a list.
#   This macro appends a list of values to the back of a list.
#   \required[value] list The name of the list to append values to.
#   \required[list] value A list of values that will be appended to the list.
macro(remake_list_push list_name)
  list(APPEND ${list_name} ${ARGN})
endmacro(remake_list_push)

### \brief Remove values from the front of a list.
#   This macro removes a list of values from the front of the list and
#   assigns the removed values to output variables.
#   \required[value] list The name of the list to remove the values from.
#   \required[list] var A list of variables to assign removed list values to. 
#     The number of variables provided determines the number of elements to
#     be removed from the list.
#   \optional[value] SPLIT:value An optional split string that marks the
#     element boundaries of the list, defaults to the semi-colon.
#   \optional[value] DEFAULT:value An optional default value that is assigned
#     to an output variable only if the requested list element does not exist.
macro(remake_list_pop list_name)
  remake_arguments(PREFIX list_ VAR SPLIT VAR DEFAULT ARGN vars ${ARGN})

  while(list_vars)
    list(GET list_vars 0 list_variable)
    list(REMOVE_AT list_vars 0)

    if(${list_name})
      remake_set(${list_variable})
      while(${list_name})
        list(GET ${list_name} 0 list_element)
        list(REMOVE_AT ${list_name} 0)
  
        if(list_split)
          if(list_element MATCHES ${list_split})
            break()
          else(list_element MATCHES ${list_split})
            list(APPEND ${list_variable} ${list_element})
          endif(list_element MATCHES ${list_split})
        else(list_split)
          remake_set(${list_variable} ${list_element})
          break()
        endif(list_split)
      endwhile(${list_name})
    else(${list_name})
      remake_set(${list_variable} ${list_default})
    endif(${list_name})
  endwhile(list_vars)
endmacro(remake_list_pop)

### \brief Search a list for existing values.
#   This macro iterates a list in order to determine missing list values.
#   \required[value] list The name of the list to be searched for existing
#     values.
#   \optional[value] ALL:variable The name of an optional output variable that
#     is set to TRUE only if all the values provided are contained in the list.
#   \optional[value] ANY:variable The name of an optional output variable that
#     is set to TRUE only if any of the values provided is contained in the 
#     list.
#   \optional[value] CONTAINED:variable The name of an optional variable to
#     hold the list of values contained in the list.
#   \optional[value] MISSING:variable The name of an optional variable to
#     hold the list of values not contained in the list.
#   \requiredl[list] value The list of values to be searched for.
macro(remake_list_contains list_name)
  remake_arguments(PREFIX list_ VAR ALL VAR ANY VAR CONTAINED VAR MISSING
    ARGN values ${ARGN})

  if(list_all)
    remake_set(${list_all} TRUE)
  endif(list_all)
  if(list_any)
    remake_set(${list_any})
  endif(list_any)
  if(list_contained)
    remake_set(${list_contained})
  endif(list_contained)
  if(list_missing)
    remake_set(${list_missing})
  endif(list_missing)

  foreach(list_value ${list_values})
    list(FIND ${list_name} ${list_value} list_index)
    if(list_index LESS 0)
      remake_set(${list_all} FALSE)
      if(list_missing)
        remake_list_push(${list_missing} ${list_value})
      endif(list_missing)
    else(list_index LESS 0)
      remake_set(${list_any} TRUE)
      if(list_contained)
        remake_list_push(${list_contained} ${list_value})
      endif(list_contained)
    endif(list_index LESS 0)
  endforeach(list_value)
endmacro(remake_list_contains)