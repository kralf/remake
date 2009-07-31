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

# Add a ReMake branch along with a list of dependencies for this branch. 
# Note that dependent branches must share the same root directory.
macro(remake_branch branch_name branch_compile)
  remake_set(REMAKE_BRANCH_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
  remake_set(REMAKE_BRANCH_NAME ${branch_name})
  remake_set(REMAKE_BRANCH_DEPENDS ${ARGN})
  string(TOUPPER WITH_${branch_name} REMAKE_BRANCH_OPTION)
  remake_option(${REMAKE_BRANCH_OPTION} "${REMAKE_BRANCH_NAME} branch" 
    ${branch_compile})
  if(${REMAKE_BRANCH_OPTION})
    add_subdirectory(${REMAKE_BRANCH_NAME})
  endif(${REMAKE_BRANCH_OPTION})
endmacro(remake_branch)

# Add a library to the current ReMake branch. Link the library to a list of 
# libraries contained in all branches for which dependencies have been defined.
macro(remake_branch_add_library lib_name)
  remake_branch_depends(${lib_name} lib_depends ${ARGN})
  remake_add_library(${lib_name} SUFFIX -${REMAKE_BRANCH_NAME} ${lib_depends})
endmacro(remake_branch_add_library)

# Add a plugin to the current ReMake branch. Link the plugin to a list of 
# plugins contained in all branches for which dependencies have been defined.
macro(remake_branch_add_plugin plugin_name)
  remake_branch_depends(${plugin_name} plugin_depends ${ARGN})
  remake_add_plugin(${plugin_name} SUFFIX -${REMAKE_BRANCH_NAME}
    ${plugin_depends})
endmacro(remake_branch_add_plugin)

# Add executables to the current ReMake branch. Link the executables to a 
# list of libraries contained in all branches for which dependencies have 
# been defined.
macro(remake_branch_add_executables)
  remake_branch_depends(exec_depends ${ARGN})
  remake_add_executables(SUFFIX -${REMAKE_BRANCH_NAME} ${exec_depends})
endmacro(remake_branch_add_executables)

# Add include directories to the current ReMake branch. Include a list of 
# directories contained in all branches for which dependencies have been 
# defined.
macro(remake_branch_include include_dirs)
  foreach(branch_name ${remake_branch} ${remake_branch_deps})
    remake_set(remake_branch_dir ${remake_branch_root}/${branch_name})
    foreach(dir_name ${ARGV})
      if(IS_ABSOLUTE ${dir_name})
        include_directories(${remake_branch_dir}${dir_name})
      else(IS_ABSOLUTE ${dir_name})
        get_filename_component(absolute_path
          ${CMAKE_CURRENT_SOURCE_DIR}/${dir_name} ABSOLUTE)
        string(REGEX REPLACE "^${remake_branch_root}/${remake_branch}/" 
          "${remake_branch_dir}/" branch_path ${absolute_path})
        include_directories(${branch_path})
      endif(IS_ABSOLUTE ${dir_name})
    endforeach(dir_name)
  endforeach(branch_name)
endmacro(remake_branch_include)

# Link a target in the current ReMake branch. Link the target to a list of 
# libraries contained in all branches for which dependencies have been defined.
macro(remake_branch_link_target target_name)
  remake_set(target_fullname ${target_name}-${remake_branch})
  foreach(branch_name ${remake_branch} ${remake_branch_deps})
    remake_set(remake_branch_dir ${remake_branch_root}/${branch_name})
    foreach(link_library ${ARGN})
      remake_set(lib_fullname ${link_library}-${branch_name})
      if(target_fullname STREQUAL ${lib_fullname})
      else(target_fullname STREQUAL ${lib_fullname})
        if(TARGET ${lib_fullname})
          target_link_libraries(${target_fullname} ${lib_fullname})
        endif(TARGET ${lib_fullname})
      endif(target_fullname STREQUAL ${lib_fullname})
    endforeach(link_library)
  endforeach(branch_name)
endmacro(remake_branch_link_target)
