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

# ReMake provides a set of CMake macros that have originally been written
# to facilitate the restructuring of GNU Automake/Autoconf projects.
#
# A key feature of ReMake is its branching concept. A branch is defined
# along with a list of dependencies that will automatically be resolved
# by ReMake.
#
# ReMake requires CMake version 2.6 or higher.

# Parse macro arguments. Return optional arguments and the list of arguments
# given pass the last optional argument.
macro(remake_parse_arguments)
  set(var_names)
  set(opt_names)
  set(argn_name)  
  set(arguments)

  set(push_var)
  foreach(arg ${ARGN})
    if(push_var)
      list(APPEND ${push_var} ${arg})
      set(push_var)
    else(push_var)
      if(arg STREQUAL VAR)
        set(push_var var_names)
      elseif(arg STREQUAL OPTION)
        set(push_var opt_names)
      elseif(arg STREQUAL ARGN)
        set(push_var argn_name)
      else(arg STREQUAL VAR)
       list(APPEND arguments ${arg})
      endif(arg STREQUAL VAR)
    endif(push_var)
  endforeach(arg)
  
  foreach(var_name ${var_names})
    set(${var_name})
  endforeach(var_name)
  foreach(opt_name ${opt_names})
    set(${opt_name} OFF)
  endforeach(opt_name)
  if(argn_name)
    set(${argn_name})
  endif(argn_name)

  set(var_name)
  foreach(arg ${arguments})
    if(var_name)
      list(APPEND ${var_name} ${arg})
      set(var_name)
    else(var_name)
      list(FIND var_names ${arg} var_found)
      list(FIND opt_names ${arg} opt_found)

      if(var_found GREATER -1)
        list(GET var_names ${var_found} var_name)
      elseif(opt_found GREATER -1)
        list(GET opt_names ${opt_found} opt_name)
        set(${opt_name} ON)
      else(var_found GREATER -1)
        list(APPEND ${argn_name} ${arg})
      endif(var_found GREATER -1)
    endif(var_name)
  endforeach(arg)
endmacro(remake_parse_arguments)

# Assign the value of one variable to another variable. Use a given default 
# value if the variable value is undefined.
macro(remake_assign var_name)
  remake_parse_arguments(VAR FROM VAR DEFAULT ${ARGN})

  if(FROM)
    if(${FROM})
      set(${var_name} ${${FROM}})
    else(${FROM})
      set(${var_name} ${DEFAULT})
    endif(${FROM})
  else(FROM)
    if(NOT ${var_name})
      set(${var_name} ${DEFAULT})
    endif(NOT ${var_name})
  endif(FROM)
endmacro(remake_assign)

# Define the ReMake project.
macro(remake_project name version release summary vendor contact home license)
  set(REMAKE_PROJECT_NAME ${name})
  string(TOLOWER ${REMAKE_PROJECT_NAME} REMAKE_PROJECT_LOWER_NAME)

  set(regex_replace "^([0-9]+)[.]?([0-9]*)[.]?([0-9]*)$")
  string(REGEX REPLACE ${regex_replace} "\\1" REMAKE_PROJECT_MAJOR ${version})
  string(REGEX REPLACE ${regex_replace} "\\2" REMAKE_PROJECT_MINOR ${version})
  string(REGEX REPLACE ${regex_replace} "\\3" REMAKE_PROJECT_PATCH ${version})
  if(NOT REMAKE_PROJECT_MAJOR)
    set(REMAKE_PROJECT_MAJOR 0)
  endif(NOT REMAKE_PROJECT_MAJOR)
  if(NOT REMAKE_PROJECT_MINOR)
    set(REMAKE_PROJECT_MINOR 0)
  endif(NOT REMAKE_PROJECT_MINOR)
  if(NOT REMAKE_PROJECT_PATCH)
    set(REMAKE_PROJECT_PATCH 0)
  endif(NOT REMAKE_PROJECT_PATCH)
  set(REMAKE_PROJECT_VERSION 
    ${REMAKE_PROJECT_MAJOR}.${REMAKE_PROJECT_MINOR}.${REMAKE_PROJECT_PATCH})
  set(REMAKE_PROJECT_RELEASE ${release})

  set(REMAKE_PROJECT_SUMMARY ${summary})
  set(REMAKE_PROJECT_VENDOR ${vendor})
  set(REMAKE_PROJECT_CONTACT ${contact})
  set(REMAKE_PROJECT_HOME ${home})
  set(REMAKE_PROJECT_LICENSE ${license})

  set(REMAKE_PROJECT_BUILD_SYSTEM ${CMAKE_SYSTEM_NAME})
  set(REMAKE_PROJECT_BUILD_ARCH ${CMAKE_SYSTEM_PROCESSOR})
  set(REMAKE_PROJECT_BUILD_TYPE ${CMAKE_BUILD_TYPE})

  set(REMAKE_PROJECT_LIBRARY_DESTINATION lib)
  set(REMAKE_PROJECT_PLUGIN_DESTINATION lib/${REMAKE_PROJECT_LOWER_NAME})
  set(REMAKE_PROJECT_EXECUTABLE_DESTINATION bin)
  set(REMAKE_PROJECT_SCRIPT_DESTINATION bin)
  set(REMAKE_PROJECT_FILE_DESTINATION share/${REMAKE_PROJECT_LOWER_NAME})
  set(REMAKE_PROJECT_HEADER_DESTINATION include/${REMAKE_PROJECT_LOWER_NAME})

  set(REMAKE_PROJECT_PACKAGE_GENERATORS)

  message("Project: ${REMAKE_PROJECT_NAME} "
    "version ${REMAKE_PROJECT_VERSION}, "
    "release ${REMAKE_PROJECT_RELEASE}")
  message("Summary: ${REMAKE_PROJECT_SUMMARY}")
  message("Vendor: ${REMAKE_PROJECT_VENDOR} (${REMAKE_PROJECT_CONTACT})")
  message("Home: ${REMAKE_PROJECT_HOME}")
  message("License: ${REMAKE_PROJECT_LICENSE}")

  project(${REMAKE_PROJECT_NAME})
endmacro(remake_project)

# Define the ReMake project prefix for libary, plugin, executable, script,
# and file names. By an empty argument list, this prefix defaults to the
# lower-case project name followed by a score.
macro(remake_project_prefix)
  remake_parse_arguments(VAR LIBRARY VAR PLUGIN VAR EXECUTABLE VAR SCRIPT 
    VAR FILE ARGN argn ${ARGN})
  string(TOLOWER ${REMAKE_PROJECT_NAME} lower_name)

  remake_assign(REMAKE_LIBRARY_PREFIX FROM LIBRARY
    DEFAULT ${REMAKE_PROJECT_LOWER_NAME}-)
  remake_assign(REMAKE_PLUGIN_PREFIX FROM PLUGIN
    DEFAULT ${REMAKE_PROJECT_LOWER_NAME}-)
  remake_assign(REMAKE_EXECUTABLE_PREFIX FROM EXECUTABLE
    DEFAULT ${REMAKE_PROJECT_LOWER_NAME}-)
  remake_assign(REMAKE_SCRIPT_PREFIX FROM SCRIPT
    DEFAULT ${REMAKE_PROJECT_LOWER_NAME}-)
  remake_assign(REMAKE_FILE_PREFIX FROM FILE
    DEFAULT ${REMAKE_PROJECT_LOWER_NAME}-)
endmacro(remake_project_prefix)

# Define the ReMake configuration header.
macro(remake_config source header)
  set(REMAKE_CONFIG_HEADER ${CMAKE_BINARY_DIR}/${header})
  configure_file(${CMAKE_SOURCE_DIR}/${source} ${REMAKE_CONFIG_HEADER})
  get_filename_component(REMAKE_CONFIG_DIR ${REMAKE_CONFIG_HEADER} PATH)
  include_directories(${REMAKE_CONFIG_DIR})
endmacro(remake_config)

# Define a ReMake option.
macro(remake_option variable_name description variable_value)
  option(${variable_name} "compile with ${description}" ${variable_value})
  if(${variable_name})
    message("-- Compiling with ${description}")
  else(${variable_name})
    message("-- NOT compiling with ${description}")
  endif(${variable_name})
endmacro(remake_option)

# Find files using a glob expression, omit hidden files from the list.
macro(remake_file variable_name)
  file(GLOB ${variable_name} ${ARGN})
  foreach(file_name ${${variable_name}})
    string(REGEX MATCH "^.*/[.].*$" regex_matched ${file_name})
    if(regex_matched)
      list(REMOVE_ITEM ${variable_name} ${file_name})
    endif(regex_matched)
  endforeach(file_name)
endmacro(remake_file)

# Find a library and its development headers.
macro(remake_find_library package lib_name includes)
  find_library(package_lib NAMES ${lib_name})
  find_file(package_includes NAMES ${includes})
  if(package_lib AND package_includes)
  else(package_lib AND package_includes)
    message(FATAL_ERROR "Missing ${package} support")
  endif(package_lib AND package_includes)
endmacro(remake_find_library)

# Add a library to the ReMake project. Link the library to a list of libraries.
macro(remake_add_library lib_name)
  remake_parse_arguments(VAR SUFFIX ARGN link_libs ${ARGN})

  remake_file(lib_sources *.cpp)
  remake_moc(moc_sources)
  add_library(${REMAKE_LIBRARY_PREFIX}${lib_name}${SUFFIX} SHARED 
    ${lib_sources} ${moc_sources})
  target_link_libraries(${REMAKE_LIBRARY_PREFIX}${lib_name}${SUFFIX} 
    ${link_libs})

  set(plugins ${REMAKE_PROJECT_PLUGIN_DESTINATION}/${lib_name}/*.so)
  add_definitions(-DPLUGINS="${plugins}")
endmacro(remake_add_library)

# Add a plugin to the ReMake project. Link the plugin to a list of plugins.
macro(remake_add_plugin lib_name plugin_name)
  remake_parse_arguments(VAR SUFFIX ARGN link_plugins ${ARGN})

  remake_file(plugin_sources *.c *.cpp)
  remake_moc(moc_sources)
  add_library(${REMAKE_PLUGIN_PREFIX}${plugin_name}${SUFFIX} SHARED
    ${plugin_sources} ${moc_sources})
  target_link_libraries(${REMAKE_PLUGIN_PREFIX}${plugin_name}${SUFFIX}
    ${link_plugins})
endmacro(remake_add_plugin)

# Add executables to the ReMake project. Link the executables to a list 
# of libraries.
macro(remake_add_executables)
  remake_parse_arguments(VAR SUFFIX ARGN link_libs ${ARGN})

  remake_file(exec_sources *.c *.cpp)
  foreach(exec_source ${exec_sources})
    get_filename_component(exec_name ${exec_source} NAME)
    string(REGEX REPLACE "[.].*$" "" exec_name ${exec_name})
    add_executable(${REMAKE_EXECUTABLE_PREFIX}${exec_name}${SUFFIX} 
      ${exec_source})
    target_link_libraries(${REMAKE_EXECUTABLE_PREFIX}${exec_name}${SUFFIX}
      ${link_libs})
  endforeach(exec_source)
endmacro(remake_add_executables)

# Add scripts to the ReMake project.
macro(remake_add_scripts)
  remake_parse_arguments(VAR SUFFIX ARGN glob_expressions ${ARGN})
  remake_file(scripts ${glob_expressions})
endmacro(remake_add_scripts)

# Add files to the ReMake project.
macro(remake_add_files)
  remake_parse_arguments(VAR SUFFIX VAR INSTALL ARGN glob_expressions ${ARGN})
  remake_assign(INSTALL DEFAULT ${REMAKE_PROJECT_FILE_DESTINATION})
  remake_file(files ${glob_expressions})

  foreach(file ${files})
    install(FILES ${files} DESTINATION ${INSTALL} COMPONENT default)
  endforeach(file)
endmacro(remake_add_files)

# Add headers to the ReMake project.
macro(remake_add_headers)
  remake_file(headers *.h *.hpp *.tpp)
  install(FILES ${headers} DESTINATION ${REMAKE_PROJECT_HEADER_DESTINATION}
    COMPONENT dev)
endmacro(remake_add_headers)

# Add a ReMake branch along with a list of dependencies for this branch. 
# Note that dependent branches must share the same root directory.
macro(remake_add_branch branch_name branch_compile)
  set(REMAKE_BRANCH_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
  set(REMAKE_BRANCH_NAME ${branch_name})
  set(REMAKE_BRANCH_DEPENDS ${ARGN})
  string(TOUPPER WITH_${branch_name} REMAKE_BRANCH_OPTION)
  remake_option(${REMAKE_BRANCH_OPTION} "${REMAKE_BRANCH_NAME} branch" 
    ${branch_compile})
  if(${REMAKE_BRANCH_OPTION})
    add_subdirectory(${REMAKE_BRANCH_NAME})
  endif(${REMAKE_BRANCH_OPTION})
endmacro(remake_add_branch)

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
    set(remake_branch_dir ${remake_branch_root}/${branch_name})
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
  set(target_fullname ${target_name}-${remake_branch})
  foreach(branch_name ${remake_branch} ${remake_branch_deps})
    set(remake_branch_dir ${remake_branch_root}/${branch_name})
    foreach(link_library ${ARGN})
      set(lib_fullname ${link_library}-${branch_name})
      if(target_fullname STREQUAL ${lib_fullname})
      else(target_fullname STREQUAL ${lib_fullname})
        if(TARGET ${lib_fullname})
          target_link_libraries(${target_fullname} ${lib_fullname})
        endif(TARGET ${lib_fullname})
      endif(target_fullname STREQUAL ${lib_fullname})
    endforeach(link_library)
  endforeach(branch_name)
endmacro(remake_branch_link_target)

# Add include directories to the current ReMake branch.
macro(remake_include include_dirs)
  foreach(include_dir ${ARGV})
    get_filename_component(absolute_path ${include_dir} ABSOLUTE)
    include_directories(${absolute_path})
  endforeach(include_dir)
endmacro(remake_include)

# Link a target in the current ReMake branch.
macro(remake_link_target target_name)
  target_link_libraries(${target_name}-${remake_branch} ${ARGN})
endmacro(remake_link_target)

# Turn on automatic meta-object processing.
macro(remake_auto_moc)
  if(QT4_FOUND)
    set(REMAKE_AUTOMOC ON)
  else(QT4_FOUND)
    set(REMAKE_AUTOMOC OFF)
  endif(QT4_FOUND)
endmacro(remake_auto_moc)

# Find meta-objects.
macro(remake_moc variable_name)
  set(${variable_name})
  if(REMAKE_AUTOMOC)
    remake_file(moc_headers *.hpp)
    qt4_wrap_cpp(${variable_name} ${moc_headers})
  endif(REMAKE_AUTOMOC)
endmacro(remake_moc)

# Generate packages from the ReMake project.
macro(remake_pack)
  set(CPACK_GENERATOR ${REMAKE_PROJECT_PACKAGE_GENERATORS})
  set(CPACK_INSTALL_CMAKE_PROJECTS ${CMAKE_BINARY_DIR}
    ${REMAKE_PROJECT_NAME} ALL /)
  set(CPACK_SET_DESTDIR TRUE)

  set(CPACK_PACKAGE_NAME ${REMAKE_PROJECT_NAME})
  set(CPACK_PACKAGE_VERSION ${REMAKE_PROJECT_VERSION})
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${REMAKE_PROJECT_SUMMARY})
  set(CPACK_PACKAGE_CONTACT ${REMAKE_PROJECT_CONTACT})

  include(CPack)

  add_custom_command(OUTPUT package COMMAND make package)
endmacro(remake_pack)

# Generate Debian packages from the ReMake project.
macro(remake_pack_deb)
  remake_parse_arguments(VAR ARCH ARGN argn ${ARGN})

  execute_process(COMMAND dpkg --print-architecture OUTPUT_VARIABLE DEB_ARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  remake_assign(ARCH DEFAULT ${DEB_ARCH})
  set(DEB_FILE ${REMAKE_PROJECT_LOWER_NAME}-${REMAKE_PROJECT_VERSION}-${ARCH})

  list(APPEND REMAKE_PROJECT_PACKAGE_GENERATORS DEB)
  string(REPLACE ";" ", " replace "${argn}")
  set(CPACK_DEBIAN_PACKAGE_DEPENDS ${replace})
  set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${ARCH})
  set(CPACK_PACKAGE_FILE_NAME ${DEB_FILE})

  remake_pack()

  add_custom_target(package_install 
    COMMAND sudo dpkg --install ${DEB_FILE}.deb
    DEPENDS package)
endmacro(remake_pack_deb)
