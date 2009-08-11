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

include(ReMakeProject)
include(ReMakeBranch)
include(ReMakeFind)
include(ReMakeFile)
include(ReMakeList)
include(ReMakeTarget)
include(ReMakeQt4)
include(ReMakeDoc)
include(ReMakePack)

include(ReMakePrivate)

### \brief ReMake convenience macros
#   ReMake provides a set of CMake macros that have originally been written to 
#   facilitate the restructuring of GNU Automake/Autoconf projects.
#
#   A key feature of ReMake is its branching concept. A branch is defined
#   along with a list of dependencies that is automatically resolved
#   by ReMake.
#
#   ReMake requires CMake version 2.6 or higher.

### \brief Add a library target.
#   Automatically identify library objects in the current directory and 
#   link the library to a list of libraries provided.
#   \required[value] name The name of the library target to be added.
#   \optional[value] SUFFIX:suffix An optional library name suffix.
#   \optional[list] lib The list of libraries the target library is to be 
#     linked against.
macro(remake_add_library lib_name)
  remake_arguments(VAR SUFFIX ARGN link_libs ${ARGN})
  remake_project_get(LIBRARY_DESTINATION)
  remake_project_get(PLUGIN_DESTINATION)

  remake_file_glob(lib_sources *.cpp)
  remake_moc(moc_sources)
  add_library(${REMAKE_LIBRARY_PREFIX}${lib_name}${suffix} SHARED 
    ${lib_sources} ${moc_sources})
  target_link_libraries(${REMAKE_LIBRARY_PREFIX}${lib_name}${suffix} 
    ${link_libs})

  remake_set(plugins ${PLUGIN_DESTINATION}/${lib_name}/*.so)
  if(IS_ABSOLUTE ${PLUGIN_DESTINATION})
    add_definitions(-DPLUGINS="${plugins}")
  else(IS_ABSOLUTE ${PLUGIN_DESTINATION})
    add_definitions(-DPLUGINS="${CMAKE_INSTALL_PREFIX}/${plugins}")
  endif(IS_ABSOLUTE ${PLUGIN_DESTINATION})
endmacro(remake_add_library)

### \brief Add a plugin library target.
#   Automatically identify plugin library objects and link the plugin to a 
#   list of libraries provided.
macro(remake_add_plugin lib_name plugin_name)
  remake_arguments(VAR SUFFIX ARGN link_plugins ${ARGN})
  remake_project_get(PLUGIN_DESTINATION)

  remake_file_glob(plugin_sources *.c *.cpp)
  remake_moc(moc_sources)
  add_library(${REMAKE_PLUGIN_PREFIX}${plugin_name}${suffix} SHARED
    ${plugin_sources} ${moc_sources})
  target_link_libraries(${REMAKE_PLUGIN_PREFIX}${plugin_name}${suffix}
    ${link_plugins})
endmacro(remake_add_plugin)

### \brief Add executable targets.
#   Automatically identify executable objects and link the executable to a 
#   list of libraries provided.
macro(remake_add_executables)
  remake_arguments(VAR SUFFIX ARGN link_libs ${ARGN})
  remake_project_get(EXECUTABLE_DESTINATION)

  remake_file_glob(exec_sources *.c *.cpp)
  foreach(exec_source ${exec_sources})
    get_filename_component(exec_name ${exec_source} NAME)
    string(REGEX REPLACE "[.].*$" "" exec_name ${exec_name})
    add_executable(${REMAKE_EXECUTABLE_PREFIX}${exec_name}${suffix} 
      ${exec_source})
    target_link_libraries(${REMAKE_EXECUTABLE_PREFIX}${exec_name}${suffix}
      ${link_libs})
  endforeach(exec_source)
endmacro(remake_add_executables)

### \brief Add script targets.
macro(remake_add_scripts)
  remake_project_get(SCRIPT_DESTINATION)

  remake_arguments(VAR SUFFIX ARGN globs ${ARGN})
  remake_file_glob(scripts ${globs})
endmacro(remake_add_scripts)

### \brief Add file targets.
macro(remake_add_files)
  remake_arguments(VAR INSTALL ARGN globs ${ARGN})
  remake_project_get(FILE_DESTINATION)
  remake_set(install SELF DEFAULT ${FILE_DESTINATION})

  remake_file_glob(files ${globs})
  foreach(file ${files})
    install(FILES ${files} DESTINATION ${install} COMPONENT default)
  endforeach(file)
endmacro(remake_add_files)

### \brief Add header targets.
macro(remake_add_headers)
  remake_project_get(HEADER_DESTINATION)

  remake_file_glob(headers *.h *.hpp *.tpp)
  install(FILES ${headers} DESTINATION ${HEADER_DESTINATION}
    COMPONENT dev)
endmacro(remake_add_headers)

### \brief Add a documentation target.
#   This macro adds a documentation target, using the requested generator
#   for document generation. Additional arguments passed to the macro are
#   forwarded to the selected generator.
#   \required[option] DOYXGEN|GROFF|CUSTOM The generator to be used for 
#     document generation.
#   \required[list] arg The arguments to be forwared to the document
#     generator. See ReMakeDoc for details.
macro(remake_add_documentation doc_generator)
  if(${doc_generator} MATCHES "DOXYGEN")
    remake_doc_doxygen(${ARGN})
  elseif(${doc_generator} MATCHES "GROFF")
    remake_doc_groff(${ARGN})
  elseif(${doc_generator} MATCHES "CUSTOM")
    remake_doc_custom(${ARGN})
  endif(${doc_generator} MATCHES "DOXYGEN")
endmacro(remake_add_documentation)

### \brief Add directories to the include path.
macro(remake_include include_dirs)
  foreach(include_dir ${ARGV})
    get_filename_component(absolute_path ${include_dir} ABSOLUTE)
    include_directories(${absolute_path})
  endforeach(include_dir)
endmacro(remake_include)
