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
macro(remake_pack pack_generator)
  if(NOT TARGET ${REMAKE_PACK_ALL_TARGET})
    remake_target(${REMAKE_PACK_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_PACK_ALL_TARGET})

  remake_arguments(PREFIX pack_ VAR NAME VAR COMPONENT ${ARGN})
  remake_set(pack_name SELF DEFAULT ${REMAKE_PROJECT_NAME})

  remake_set(pack_prefix ${pack_component})
  remake_set(pack_component SELF DEFAULT default)
  remake_file(${REMAKE_PACK_DIR}/${pack_component}.cpack pack_config)
  remake_file(${REMAKE_PACK_SOURCE_DIR}/${pack_component}.cpack 
    pack_src_config)
  remake_set(CPACK_OUTPUT_CONFIG_FILE ${pack_config})
  remake_set(CPACK_SOURCE_OUTPUT_CONFIG_FILE ${pack_src_config})

  remake_set(CPACK_GENERATOR ${pack_generator})
  remake_set(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
    ${REMAKE_PROJECT_NAME} ${pack_component} /)
  remake_set(CPACK_SET_DESTDIR TRUE)

  remake_set(CPACK_PACKAGE_NAME ${pack_name})
  remake_set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})
  remake_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${REMAKE_PROJECT_SUMMARY})
  remake_set(CPACK_PACKAGE_CONTACT ${REMAKE_PROJECT_CONTACT})

  include(CPack)

  remake_target_name(pack_target ${pack_prefix} ${REMAKE_PACK_TARGET})
  remake_target(${pack_target} COMMAND cpack --config ${pack_config})
  add_dependencies(${REMAKE_PACK_ALL_TARGET} ${pack_target})

  remake_var_regex(pack_variables "^CPACK_")
  foreach(pack_var ${pack_variables})
    remake_set(${pack_var})
  endforeach(pack_var)
endmacro(remake_pack)

# Generate Debian package from the ReMake project.
macro(remake_pack_deb)
  remake_arguments(PREFIX pack_ VAR ARCH VAR COMPONENT ARGN dependencies 
    ${ARGN})

  execute_process(COMMAND dpkg --print-architecture
    OUTPUT_VARIABLE pack_deb_arch OUTPUT_STRIP_TRAILING_WHITESPACE)
  remake_set(pack_arch SELF DEFAULT ${pack_deb_arch})
  remake_set(pack_prefix ${pack_component})
  remake_set(pack_suffix ${pack_component})

  if(pack_suffix)
    remake_file_name(pack_name ${REMAKE_PROJECT_FILENAME}-${pack_suffix})
    remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}-${pack_suffix}
      ${REMAKE_PROJECT_VERSION} ${pack_arch})
  else(pack_suffix)
    remake_file_name(pack_name ${REMAKE_PROJECT_FILENAME})
    remake_file_name(pack_file ${REMAKE_PROJECT_FILENAME}
      ${REMAKE_PROJECT_VERSION} ${pack_arch})
  endif(pack_suffix)

  string(REPLACE ";" ", " pack_replace "${pack_dependencies}")
  remake_set(CPACK_DEBIAN_PACKAGE_DEPENDS ${pack_replace})
  remake_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${pack_arch})
  remake_set(CPACK_PACKAGE_FILE_NAME deb/${pack_file})

  remake_pack(DEB ${COMPONENT} NAME ${pack_name})

  remake_target_name(pack_target ${pack_prefix} ${REMAKE_PACK_TARGET})
  remake_target_name(pack_install_target ${pack_prefix}
    ${REMAKE_PACK_INSTALL_TARGET})
  remake_target(${pack_install_target}
    COMMAND sudo dpkg --install deb/${pack_file}.deb
    DEPENDS ${pack_target})
endmacro(remake_pack_deb)
