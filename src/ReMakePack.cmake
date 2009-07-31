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

# Generate packages from the ReMake project.
macro(remake_pack)
  remake_set(CPACK_GENERATOR ${REMAKE_PACK_GENERATORS})
  remake_set(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
    ${REMAKE_PROJECT_NAME} ALL /)
  remake_set(CPACK_SET_DESTDIR TRUE)

  remake_set(CPACK_PACKAGE_NAME ${REMAKE_PROJECT_NAME})
  remake_set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})
  remake_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${REMAKE_PROJECT_SUMMARY})
  remake_set(CPACK_PACKAGE_CONTACT ${REMAKE_PROJECT_CONTACT})

  include(CPack)

  remake_set(REMAKE_PACK_TARGET package)
  remake_set(REMAKE_PACK_INSTALL_TARGET package_install)

  add_custom_command(OUTPUT ${REMAKE_PACK_TARGET} 
    COMMAND make ${REMAKE_PACK_TARGET})
endmacro(remake_pack)

# Generate Debian package from the ReMake project.
macro(remake_pack_deb)
  remake_arguments(VAR ARCH ARGN argn ${ARGN})

  execute_process(COMMAND dpkg --print-architecture OUTPUT_VARIABLE deb_arch
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  remake_set(ARCH DEFAULT ${deb_arch})
  remake_set(deb_file 
    ${REMAKE_PROJECT_FILENAME}-${REMAKE_PROJECT_VERSION}-${ARCH})

  list(APPEND REMAKE_PACK_GENERATORS DEB)
  string(REPLACE ";" ", " replace "${argn}")
  remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${replace})
  remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${ARCH})
  remake_set(CPACK_PACKAGE_FILE_NAME ${deb_file})

  remake_pack()

  remake_target(${REMAKE_PACK_INSTALL_TARGET}
    COMMAND sudo dpkg --install ${deb_file}.deb
    DEPENDS ${REMAKE_PACK_TARGET})
endmacro(remake_pack_deb)
