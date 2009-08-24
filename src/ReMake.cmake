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
include(ReMakeSVN)

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

### \brief Add a shared library target.
#   This macro automatically defines build rules for a shared library
#   target from a list of glob expressions. In addition, the macro takes a
#   list of libraries that are linked into the library target. Also, the
#   library source directory is automatically added to the include path,
#   thus allowing for the library headers to be found from subdirectories.
#   \required[value] name The name of the shared library target to be defined.
#   \optional[value] SUFFIX:suffix An optional library name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the library sources, defaulting to *.c
#     and *.cpp.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     shared library target.
macro(remake_add_library name)
  remake_arguments(VAR SUFFIX ARGN globs LIST LINK ${ARGN})
  remake_set(globs SELF DEFAULT *.c DEFAULT *.cpp)
  remake_project_get(LIBRARY_PREFIX)
  remake_project_get(PLUGIN_PREFIX)
  remake_project_get(LIBRARY_DESTINATION)
  remake_project_get(PLUGIN_DESTINATION)

  if(REMAKE_BRANCH_COMPILE)
    remake_set(suffix ${REMAKE_BRANCH_SUFFIX})
    remake_branch_link(link TARGET ${name} ${link})
    remake_branch_add_targets(${name})
  endif(REMAKE_BRANCH_COMPILE)

  remake_include()
  remake_file_glob(sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${globs})
#   remake_moc(moc_sources)
  add_library(${name}${suffix} SHARED ${sources})
  set_target_properties(${name}${suffix} PROPERTIES OUTPUT_NAME
    ${LIBRARY_PREFIX}${name}${suffix})
  if(link)
    target_link_libraries(${name}${suffix} ${link})
  endif(link)

  remake_set(plugin_suffix ${CMAKE_SHARED_LIBRARY_SUFFIX})
  remake_set(plugins
    ${PLUGIN_DESTINATION}/${name}/${PLUGIN_PREFIX}*${plugin_suffix})
  if(IS_ABSOLUTE ${PLUGIN_DESTINATION})
    add_definitions(-DPLUGINS="${plugins}")
  else(IS_ABSOLUTE ${PLUGIN_DESTINATION})
    add_definitions(-DPLUGINS="${CMAKE_INSTALL_PREFIX}/${plugins}")
  endif(IS_ABSOLUTE ${PLUGIN_DESTINATION})

  install(TARGETS ${name}${suffix}
    LIBRARY DESTINATION ${LIBRARY_DESTINATION}
    COMPONENT default)
endmacro(remake_add_library)

### \brief Add a plugin library target.
#   This macro automatically defines build rules for a plugin library
#   target from a list of glob expressions. In addition, the macro takes a
#   list of libraries that are linked into the plugin library target.
#   \required[value] name The name of the plugin library target to be defined.
#   \optional[value] SUFFIX:suffix An optional plugin name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the plugin sources, defaulting to *.c
#     and *.cpp.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     plugin library target.
macro(remake_add_plugin name)
  remake_arguments(VAR SUFFIX ARGN globs LIST LINK ${ARGN})
  remake_set(globs SELF DEFAULT *.c DEFAULT *.cpp)
  remake_project_get(PLUGIN_PREFIX)
  get_property(definitions DIRECTORY PROPERTY COMPILE_DEFINITIONS)
  remake_list_values(definitions plugins PLUGINS)
  if(plugins)
    string(REGEX REPLACE "\"(.*)/[^/]*\"" "\\1" plugins ${plugins})
  else(plugins)
    remake_project_get(PLUGIN_DESTINATION OUTPUT plugins)
  endif(plugins)

  if(REMAKE_BRANCH_COMPILE)
    remake_set(suffix ${REMAKE_BRANCH_SUFFIX})
    remake_branch_link(link TARGET ${name} ${link})
    remake_branch_add_targets(${name})
  endif(REMAKE_BRANCH_COMPILE)

  remake_file_glob(sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${globs})
#   remake_moc(moc_sources)
  add_library(${name}${suffix} SHARED ${sources})
  set_target_properties(${name}${suffix} PROPERTIES OUTPUT_NAME
    ${PLUGIN_PREFIX}${name}${suffix})
  if(link)
    target_link_libraries(${name}${suffix} ${link})
  endif(link)

  install(TARGETS ${name}${suffix}
    LIBRARY DESTINATION ${plugins}
    COMPONENT default)
endmacro(remake_add_plugin)

### \brief Add executable targets.
#   This macro automatically defines build rules for executable targets from
#   a list of glob expressions. One target is added for each executable source
#   resolved from the glob expressions. The target bears the name of the
#   source file without the file extension. In addition, the macro takes a
#   list of libraries that are linked into the executable targets.
#   \optional[value] SUFFIX:suffix An optional executable name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the executable sources, defaulting to *.c
#     and *.cpp.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     executable targets.
macro(remake_add_executables)
  remake_arguments(VAR SUFFIX ARGN globs LIST LINK ${ARGN})
  remake_set(globs SELF DEFAULT *.c DEFAULT *.cpp)
  remake_project_get(EXECUTABLE_PREFIX)
  remake_project_get(EXECUTABLE_DESTINATION)

  if(REMAKE_BRANCH_COMPILE)
    remake_set(suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_COMPILE)

  remake_file_glob(sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${globs})
  remake_branch_link(link ${link})
  foreach(source ${sources})
    get_filename_component(name ${source} NAME_WE)
    if(REMAKE_BRANCH_COMPILE)
      remake_branch_add_targets(${name})
    endif(REMAKE_BRANCH_COMPILE)
    add_executable(${name}${suffix} ${source})
    set_target_properties(${name}${suffix} PROPERTIES OUTPUT_NAME
      ${EXECUTABLE_PREFIX}${name}${suffix})
    if(link)
      target_link_libraries(${name}${suffix} ${link})
    endif(link)

    install(TARGETS ${name}${suffix}
      RUNTIME DESTINATION ${EXECUTABLE_DESTINATION}
      COMPONENT default)
  endforeach(source)
endmacro(remake_add_executables)

### \brief Add header install rules.
#   This macro automatically defines install rules for header files from
#   a list of glob expressions. The install destination of each header file 
#   is its relative-path location below ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the header files, defaulting to *.h, *.hpp,
#     and *.tpp.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the headers' install destination. For each header file, the
#     install destination defaults to its relative-path location below
#     ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to CMake's install() macro, defaults to dev.
#     See the CMake documentation for details.
macro(remake_add_headers)
  remake_arguments(VAR INSTALL VAR COMPONENT ARGN globs ${ARGN})
  remake_set(globs SELF DEFAULT *.h DEFAULT *.hpp DEFAULT *.tpp)
  remake_set(component SELF DEFAULT dev)
  remake_project_get(HEADER_DESTINATION)

  foreach(glob ${globs})
    remake_file_glob(headers RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${glob})
    get_filename_component(header_dir ${glob} PATH)
    remake_set(header_dir FROM install DEFAULT ${header_dir})

    install(FILES ${headers}
      DESTINATION ${HEADER_DESTINATION}/${header_dir}
      COMPONENT ${component})
  endforeach(glob)
endmacro(remake_add_headers)

### \brief Add script install rules.
#   This macro automatically defines install rules for script files from
#   a list of glob expressions.
#   \required[list] glob A list of glob expressions that are resolved in
#     order to find the scripts.
#   \optional[value] SUFFIX:suffix An optional suffix that is prepended
#     to the script names during installation, forced to
#     ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
macro(remake_add_scripts)
  remake_arguments(VAR SUFFIX ARGN globs ${ARGN})
  remake_project_get(SCRIPT_DESTINATION)

  if(REMAKE_BRANCH_COMPILE)
    remake_set(suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_COMPILE)

  remake_file_glob(scripts RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${globs})
  foreach(script ${scripts})
    remake_file_suffix(script_suffixed ${script} ${suffix})
    install(PROGRAMS ${script}
      DESTINATION ${SCRIPT_DESTINATION}
      COMPONENT default
      RENAME ${script_suffixed})
  endforeach(script)
endmacro(remake_add_scripts)

### \brief Add configuration file install rules.
#   This macro automatically defines install rules for configuration targets
#   from a list of glob expressions. As opposed to regular file targets,
#   configuration targets are automatically configured by remake_file_install()
#   prior to the install stage.
#   \required[list] glob A list of glob expressions that are resolved in
#     order to find the configuration file templates.
#   \optional[value] SUFFIX:suffix An optional suffix that is prepended
#     to the configuration file names during installation, forced to
#     ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
macro(remake_add_configurations)
  remake_arguments(VAR SUFFIX ARGN globs ${ARGN})
  remake_project_get(CONFIGURATION_DESTINATION)

  if(REMAKE_BRANCH_COMPILE)
    remake_set(suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_COMPILE)

  remake_file_configure(${globs} OUTPUT configurations)
  foreach(config ${configurations})
    file(RELATIVE_PATH config_relative ${CMAKE_CURRENT_BINARY_DIR} ${config})
    remake_file_suffix(config_suffixed ${config_relative} ${suffix})
    install(FILES ${config}
      DESTINATION ${CONFIGURATION_DESTINATION}
      COMPONENT default
      RENAME ${config_suffixed})
  endforeach(config)
endmacro(remake_add_configurations)

### \brief Add file install rules.
#   This macro automatically defines install rules for file targets
#   from a list of glob expressions.
#   \required[list] glob A list of glob expressions that are resolved in
#     order to find the files.
#   \optional[value] SUFFIX:suffix An optional suffix that is prepended
#     to the file names during installation, forced to ${REMAKE_BRANCH_SUFFIX}
#     if defined within a ReMake branch.
#   \optional[value] INSTALL:dirname The directory that shall be passed as
#     the files' install destination, defaults to ${PROJECT_FILE_DESTINATION}.
macro(remake_add_files)
  remake_arguments(VAR SUFFIX VAR INSTALL ARGN globs ${ARGN})
  remake_project_get(FILE_DESTINATION)
  remake_set(install SELF DEFAULT ${FILE_DESTINATION})

  if(REMAKE_BRANCH_COMPILE)
    remake_set(suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_COMPILE)

  remake_file_glob(files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${globs})
  foreach(file ${files})
    remake_file_suffix(file_suffixed ${file} ${suffix})
    install(FILES ${file}
      DESTINATION ${install}
      COMPONENT default
      RENAME ${file_suffixed})
  endforeach(file)
endmacro(remake_add_files)

### \brief Add subdirectories.
#   This macro includes subdirectories of the working directory from a list
#   of glob expressions. The directories are added for CMake processing.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the directories, defaulting to *. Note that
#     the correct behavior of directory inclusion might be sensitive to order.
#     In some cases, it is therefore useful to specify directories in the
#     correct order of inclusion.
#   \optional[value] IF:option The name of a project option variable that
#     conditions directory inclusion. See ReMakeProject for the correct usage
#     of ReMake project options.
macro(remake_add_directories)
  remake_arguments(VAR IF ARGN globs ${ARGN})
  remake_set(globs SELF DEFAULT *)

  if(if)
    remake_project_get(${if} OUTPUT option)
  else(if)
    remake_set(option ON)
  endif(if)

  if(option)
    remake_file_glob(files ${globs})
    remake_set(directories)

    foreach(file ${files})
      if(IS_DIRECTORY ${file})
        remake_list_push(directories ${file})
      endif(IS_DIRECTORY ${file})
    endforeach(file)
    foreach(dir ${directories})
      add_subdirectory(${dir})
    endforeach(dir)
  endif(option)
endmacro(remake_add_directories)

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
#   This macro adds a list of directories to the compiler's include path.
#   As opposed to CMake's include_directories(), the macro converts
#   directory names into absolute-path names before passing them as
#   arguments to include_directories(). If defined within a ReMake branch, 
#   the macro calls remake_branch_include() instead.
#   \optional[list] dirname The directories to be added to the compiler's
#     include path, defaults to the current directory.
macro(remake_include)
  remake_arguments(ARGN directories ${ARGN})
  remake_set(directories SELF DEFAULT .)

  if(REMAKE_BRANCH_COMPILE)
    remake_branch_include(directories ${directories})
  endif(REMAKE_BRANCH_COMPILE)

  foreach(directory ${directories})
    get_filename_component(directory ${directory} ABSOLUTE)
    include_directories(${directory})
  endforeach(directory)
endmacro(remake_include)
