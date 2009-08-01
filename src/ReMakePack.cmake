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

remake_set(REMAKE_PACK_ALL_TARGET packages)
remake_set(REMAKE_PACK_TARGET package)
remake_set(REMAKE_PACK_INSTALL_TARGET package_install)

remake_set(REMAKE_PACK_DIR ReMakePackages)
remake_set(REMAKE_PACK_SOURCE_DIR ReMakeSourcePackages)

# Generate packages from the ReMake project. This macro takes optional
# arguments giving the package name and the project component the package 
# will be generated from.
macro(remake_pack generator)
  if(NOT TARGET ${REMAKE_PACK_ALL_TARGET})
    remake_target(${REMAKE_PACK_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_PACK_ALL_TARGET})

  remake_arguments(VAR NAME VAR COMPONENT ${ARGN})
  remake_set(NAME DEFAULT ${REMAKE_PROJECT_NAME})

  remake_set(component FROM COMPONENT DEFAULT default)
  remake_file(${REMAKE_PACK_DIR}/${component}.cpack pack_config)
  remake_file(${REMAKE_PACK_SOURCE_DIR}/${component}.cpack src_pack_config)
  remake_set(CPACK_OUTPUT_CONFIG_FILE ${pack_config})
  remake_set(CPACK_SOURCE_OUTPUT_CONFIG_FILE ${src_pack_config})

  remake_set(CPACK_GENERATOR ${generator})
  remake_set(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
    ${REMAKE_PROJECT_NAME} ${component} /)
  remake_set(CPACK_SET_DESTDIR TRUE)

  remake_set(CPACK_PACKAGE_NAME ${NAME})
  remake_set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})
  remake_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${REMAKE_PROJECT_SUMMARY})
  remake_set(CPACK_PACKAGE_CONTACT ${REMAKE_PROJECT_CONTACT})

  include(CPack)

  remake_target_name(target ${COMPONENT} ${REMAKE_PACK_TARGET})
  remake_target(${target} COMMAND cpack --config ${pack_config})
  add_dependencies(${REMAKE_PACK_ALL_TARGET} ${target})

  remake_var_regex(cpack_variables "^CPACK_")
  foreach(cpack_var ${cpack_variables})
    remake_set(${cpack_var})
  endforeach(cpack_var)
endmacro(remake_pack)

# Generate Debian package from the ReMake project.
macro(remake_pack_deb)
  remake_arguments(VAR ARCH VAR COMPONENT ARGN dependencies ${ARGN})

  execute_process(COMMAND dpkg --print-architecture OUTPUT_VARIABLE deb_arch
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  remake_set(ARCH DEFAULT ${deb_arch})
  if(COMPONENT)
    remake_file_name(package_name ${REMAKE_PROJECT_FILENAME}-${COMPONENT})
    remake_file_name(file_name ${REMAKE_PROJECT_FILENAME}-${COMPONENT}
      ${REMAKE_PROJECT_VERSION} ${ARCH})
  else(COMPONENT)
    remake_file_name(package_name ${REMAKE_PROJECT_FILENAME})
    remake_file_name(file_name ${REMAKE_PROJECT_FILENAME}
      ${REMAKE_PROJECT_VERSION} ${ARCH})
  endif(COMPONENT)

  string(REPLACE ";" ", " replace "${dependencies}")
  remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${replace})
  remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${ARCH})
  remake_set(CPACK_PACKAGE_FILE_NAME deb/${file_name})

  remake_pack(DEB ${ARG_COMPONENT} NAME ${package_name})

  remake_target_name(target ${COMPONENT} ${REMAKE_PACK_TARGET})
  remake_target_name(install_target ${COMPONENT} ${REMAKE_PACK_INSTALL_TARGET})
  remake_target(${install_target}
    COMMAND sudo dpkg --install deb/${file_name}.deb
    DEPENDS ${target})
endmacro(remake_pack_deb)
