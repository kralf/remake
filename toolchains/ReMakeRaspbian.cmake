############################################################################
#    Copyright (C) 2013 by Ralf 'Decan' Kaestner                           #
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

### \brief ReMake Raspbian toolchain file
#   The ReMake Raspbian toolchain file configures the cross-build
#   environment for armv6k architectures such as the Raspberry Pi.
#   It requires the Linaro tools and binaries to be installed in
#   the standard location.

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR armv6k)

set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc-4.7)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++-4.7)

set(CMAKE_C_FLAGS "-marm -march=armv6 -mfpu=vfp -mfloat-abi=hard"
  CACHE STRING "Flags used by the compiler during all build types.")
set(CMAKE_CXX_FLAGS "-marm -march=armv6 -mfpu=vfp -mfloat-abi=hard"
  CACHE STRING "Flags used by the compiler during all build types.")

set(CMAKE_FIND_ROOT_PATH /usr/arm-linux-gnueabihf)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(REMAKE_PACK_DEBIAN_ARCHITECTURE armhf)
