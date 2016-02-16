############################################################################
#    Copyright (C) 2013 by Ralf Kaestner                                   #
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

### \brief ReMake distribution macros
#   The ReMake distribution macros facilitate automated distribution of
#   a ReMake project.
#
#   \variable REMAKE_DISTRIBUTE_ALIAS The name of the distribution on
#     the release build system.
#   \variable REMAKE_DISTRIBUTE_RELEASE_BUILD If true, the build is a
#     distribution's release build.

include(ReMakePrivate)
include(ReMakeFile)

if(NOT DEFINED REMAKE_DISTRIBUTE_CMAKE)
  remake_set(REMAKE_DISTRIBUTE_CMAKE ON)

  remake_set(REMAKE_DISTRIBUTE_TARGET_SUFFIX distribution)
  remake_set(REMAKE_DISTRIBUTE_ALL_TARGET distributions)

  remake_file(REMAKE_DISTRIBUTE_DIR ReMakeDistributions TOPLEVEL)
  remake_file_rmdir(${REMAKE_DISTRIBUTE_DIR})
  remake_file_mkdir(${REMAKE_DISTRIBUTE_DIR})

  if(NOT DEFINED REMAKE_DISTRIBUTE_RELEASE_BUILD)
    if(REMAKE_DISTRIBUTE_ALIAS)
      remake_set(REMAKE_DISTRIBUTE_RELEASE_BUILD ON
        CACHE BOOL "If true, this is a distribution's release build.")
    else(REMAKE_DISTRIBUTE_ALIAS)
      remake_set(REMAKE_DISTRIBUTE_RELEASE_BUILD OFF
        CACHE BOOL "If true, this is a distribution's release build.")
    endif(REMAKE_DISTRIBUTE_ALIAS)
  endif(NOT DEFINED REMAKE_DISTRIBUTE_RELEASE_BUILD)
else(NOT DEFINED REMAKE_DISTRIBUTE_CMAKE)
  return()
endif(NOT DEFINED REMAKE_DISTRIBUTE_CMAKE)

include(ReMakeComponent)
include(ReMakePack)
include(ReMakeDebian)

### \brief Distribute a ReMake project according to the Debian standards.
#   This macro configures source package distribution for a ReMake project
#   under the Debian standards.  It is currently deprecated but kept for
#   backward compatibility and simply invokes remake_debian_distribute(),
#   forwarding all arguments.
#   \required[list] arg The arguments to be passed on to
#     remake_debian_distribute(). See ReMakeDebian for details.
macro(remake_distribute_deb)
  message(DEPRECATION
    "This macro is deprecated in favor of remake_debian_distribute().")
  remake_debian_distribute(${ARGN})
endmacro(remake_distribute_deb)
