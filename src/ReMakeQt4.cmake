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

# Turn on Qt4 meta-object processing.
macro(remake_qt4)
  if(NOT DEFINED QT4_FOUND)
    find_package(Qt4 QUIET)
    set(REMAKE_QT4_MOC ${QT4_FOUND} CACHE BOOL "Process Qt4 meta-objects.")
  endif(NOT DEFINED QT4_FOUND)
endmacro(remake_qt4)

# Find Qt4 meta-objects.
macro(remake_qt4_moc var_name)
  remake_qt4()

  set(${var_name})
  if(REMAKE_QT4_MOC)
    remake_file(moc_headers *.hpp)
    qt4_wrap_cpp(${var_name} ${moc_headers})
  endif(REMAKE_QT4_MOC)
endmacro(remake_qt4_moc)
