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

# Push the value of a variable to a list.
macro(remake_list_push list_name)
  list(APPEND ${list_name} ${ARGN})
endmacro(remake_list_push)

# Pop the value of a variable from a list. Use a given default value if the 
# list is empty.
macro(remake_list_pop list_name var_name)
  remake_arguments(VAR DEFAULT ${ARGN})

  list(LENGTH ${list_name} list_length)
  if(list_length)
    list(GET ${list_name} 0 ${var_name})
  else(list_length)
    set(${var_name} ${DEFAULT})
  endif(list_length)
endmacro(remake_list_pop)

# Check for values in a list.
macro(remake_list_contains list_name)
  remake_arguments(VAR ALL VAR ANY VAR MISSING ARGN list_values ${ARGN})
  if(ALL)
    remake_set(${ALL} TRUE)
  endif(ALL)
  if(ANY)
    remake_set(${ANY})
  endif(ANY)
  if(MISSING)
    remake_set(${MISSING})
  endif(MISSING)

  foreach(value ${list_values})
    list(FIND ${list_name} ${value} index)
    if(index LESS 0)
      remake_set(${ALL} FALSE)
      if(MISSING)
        remake_list_push(${MISSING} ${value})
      endif(MISSING)
    elseif(index LESS 0)
      remake_set(${ANY} TRUE)
    endif(index LESS 0)
  endforeach(value ${ARGN})
endmacro(remake_list_contains)
