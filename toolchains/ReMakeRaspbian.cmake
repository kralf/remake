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

### \brief ReMake Raspbian toolchain file
#   The ReMake Raspbian toolchain file configures the cross-build
#   environment for armv6 architectures such as the Raspberry Pi.
#   It requires the cross-compile toolchain and binaries to be installed
#   in the standard multi-arch locations.
#
#   \usage cmake -DCMAKE_TOOLCHAIN_FILE=ReMakeRaspbian <CMAKE_SOURCE_DIR>
#
#   The ReMake Raspbian toolchain may be used to build against foreign
#   chroot jails which have been installed via debootstrap. Therefore, the
#   variable ${RASPBIAN_ROOT} should be pointed to the root directory of
#   the jail.
#
#   \variable RASPBIAN_ROOT The path to the chroot jail containing the
#     foreign Raspbian (or compatible) binaries. Can be set as environment
#     variable or at first CMake run.

if(ENV{RASPBIAN_ROOT})
  set(RASPBIAN_ROOT $ENV{RASPBIAN_ROOT})
endif(ENV{RASPBIAN_ROOT})

if(RASPBIAN_ROOT)
  set(RASPBIAN_ROOT "${RASPBIAN_ROOT}" CACHE INTERNAL
    "Path to the chroot jail containing the Raspbian binaries.")
endif(RASPBIAN_ROOT)
set(RASPBIAN_LLVM_TRIPLET arm-linux-gnueabihf)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR armv6)

set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)

set(CMAKE_C_FLAGS "-marm -march=armv6 -mfpu=vfp -mfloat-abi=hard"
  CACHE STRING "Flags used by the compiler during all build types.")
set(CMAKE_CXX_FLAGS "-marm -march=armv6 -mfpu=vfp -mfloat-abi=hard"
  CACHE STRING "Flags used by the compiler during all build types.")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

if(RASPBIAN_ROOT)
  set(CMAKE_FIND_ROOT_PATH ${RASPBIAN_ROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

  set(REMAKE_FIND_PKG_CONFIG_SYSROOT_DIR ${RASPBIAN_ROOT}
    CACHE INTERNAL "The pkg-config system root directory.")
  set(REMAKE_FIND_PKG_CONFIG_DIR
    ${RASPBIAN_ROOT}/usr/lib/pkgconfig
    ${RASPBIAN_ROOT}/usr/lib/${RASPBIAN_LLVM_TRIPLET}/pkgconfig
    CACHE INTERNAL "The pkg-config search directory.")

  set(RASPBIAN_INCLUDE_DIRECTORIES
    /usr/${RASPBIAN_LLVM_TRIPLET}/include
    ${RASPBIAN_ROOT}/usr/include)
  set(RASPBIAN_LINK_DIRECTORIES
    ${RASPBIAN_ROOT}/lib
    ${RASPBIAN_ROOT}/usr/lib
    ${RASPBIAN_ROOT}/lib/${RASPBIAN_LLVM_TRIPLET}
    ${RASPBIAN_ROOT}/usr/lib/${RASPBIAN_LLVM_TRIPLET})

  set(CMAKE_EXE_LINKER_FLAGS "-L/usr/${RASPBIAN_LLVM_TRIPLET}/lib")
  set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} -Wl,-allow-shlib-undefined")
  string(REGEX REPLACE ";" ",-rpath-link=" RASPBIAN_RPATH
    "-Wl,-rpath-link=${RASPBIAN_LINK_DIRECTORIES}")
  set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} ${RASPBIAN_RPATH}")
  set(CMAKE_MODULE_LINKER_FLAGS "-L/usr/${RASPBIAN_LLVM_TRIPLET}/lib")
  set(CMAKE_SHARED_LINKER_FLAGS "-L/usr/${RASPBIAN_LLVM_TRIPLET}/lib")

  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}"
    CACHE STRING "Flags used by the linker.")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}"
    CACHE STRING "Flags used by the linker during the creation of dll's.")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}"
    CACHE STRING "Flags used by the linker during the creation of modules.")

  include_directories(SYSTEM ${RASPBIAN_INCLUDE_DIRECTORIES})
  link_directories(${RASPBIAN_LINK_DIRECTORIES})
else(RASPBIAN_ROOT)
  set(CMAKE_FIND_ROOT_PATH /usr/${RASPBIAN_LLVM_TRIPLET})
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
endif(RASPBIAN_ROOT)

set(REMAKE_PACK_DEBIAN_ARCHITECTURE armhf
  CACHE INTERNAL "The architecture used for creating Debian packages.")
