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
include(ReMakeComponent)
include(ReMakeFind)
include(ReMakeFile)
include(ReMakeGenerate)
include(ReMakeList)
include(ReMakeTarget)
include(ReMakeQt3)
include(ReMakeQt4)
include(ReMakeDoc)
include(ReMakePack)
include(ReMakePython)
include(ReMakeSVN)
include(ReMakeTest)
include(ReMakeVersion OPTIONAL)

include(ReMakePrivate)

### \brief ReMake convenience macros
#   ReMake provides a set of CMake macros that have originally been written to
#   facilitate the restructuring of GNU Automake/Autoconf projects.
#
#   A key feature of ReMake is its branching concept. A branch is defined
#   along with a list of dependencies that is automatically resolved
#   by ReMake.
#
#   ReMake requires CMake version 2.6.2 or higher.

### \brief Set the minimum required version of ReMake for a module.
#   In analogy to CMake's cmake_minimum_required() macro, this macro
#   compares ReMake's version against the version requirements of a
#   custom ReMake module. A fatal error will be risen if the current
#   version of ReMake is lower than the requested minimum version.
#   \required[value] VERSION:version The required minimum version of
#     ReMake as requested by the module.
macro(remake_minimum_required)
  remake_arguments(PREFIX remake_ VAR VERSION ${ARGN})

  if(${REMAKE_VERSION} VERSION_LESS ${remake_version})
    message(FATAL_ERROR "ReMake ${remake_version} or higher is required. "
      "You are running version ${REMAKE_VERSION}")
  endif(${REMAKE_VERSION} VERSION_LESS ${remake_version})
endmacro(remake_minimum_required)

### \brief Add a list of ReMake modules.
#   This macro includes a list of custom ReMake modules. It evaluates glob
#   expressions to locate the module files and calls CMake's include() to
#   read code from the files. Note that CMake variables defined within modules
#   will only be valid in directories below the ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the modules sources, defaulting to *.cmake.
macro(remake_add_modules)
  remake_arguments(PREFIX remake_ ARGN globs ${ARGN})
  remake_set(remake_globs SELF DEFAULT *.cmake)

  remake_file_glob(remake_modules ${remake_globs})
  foreach(remake_module ${remake_modules})
    include(${remake_module})
  endforeach(remake_module)
endmacro(remake_add_modules)

### \brief Add a shared library target.
#   This macro automatically defines build rules for a shared library
#   target from a list of glob expressions. In addition, the macro takes a
#   list of libraries that are linked into the library target. Also, the
#   library source directory is automatically added to the include path,
#   thus allowing for the library headers to be found from subdirectories.
#   \required[value] name The name of the shared library target to be defined.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the library sources, defaulting to *.c
#     and *.cpp.
#   \optional[value] TYPE:type The type of the library target to be created,
#     defaulting to SHARED. See the CMake documentation for a list of valid
#     library types.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the library's install destination, defaults to the project's
#     ${LIBRARY_DESTINATION}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] PREFIX:prefix An optional library name prefix,
#     defaults to the project's ${LIBRARY_PREFIX}. Note that passing OFF
#     here results in an empty prefix.
#   \optional[value] SUFFIX:suffix An optional library name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     shared library target.
macro(remake_add_library remake_name)
  remake_arguments(PREFIX remake_ VAR TYPE VAR INSTALL VAR COMPONENT
    VAR PREFIX VAR SUFFIX ARGN globs LIST LINK ${ARGN})
  remake_set(remake_type SELF DEFAULT SHARED)
  remake_set(remake_globs SELF DEFAULT *.c DEFAULT *.cpp)

  remake_project_get(LIBRARY_PREFIX)
  remake_project_get(LIBRARY_DESTINATION)
  remake_project_get(PLUGIN_DESTINATION)
  remake_set(remake_install SELF DEFAULT ${LIBRARY_DESTINATION})
  if(NOT DEFINED remake_prefix)
    remake_set(remake_prefix ${LIBRARY_PREFIX})
  endif(NOT DEFINED remake_prefix)
  if(NOT remake_prefix)
    remake_set(remake_prefix)
  endif(NOT remake_prefix)

  if(REMAKE_BRANCH_BUILD)
    remake_set(remake_suffix ${REMAKE_BRANCH_SUFFIX})
    remake_branch_link(remake_link TARGET ${remake_name} ${remake_link})
    if(remake_link)
      remake_set(LINK LINK ${remake_link})
    endif(remake_link)
    remake_branch_add_targets(${remake_name})
  endif(REMAKE_BRANCH_BUILD)

  remake_file_glob(remake_sources ${remake_globs})
  remake_target_get_sources(remake_target_sources ${remake_name})
  remake_include()

  remake_set(remake_plugins
    ${PLUGIN_DESTINATION}/${remake_name}/*${CMAKE_SHARED_LIBRARY_SUFFIX})
  if(IS_ABSOLUTE ${PLUGIN_DESTINATION})
    remake_define(PLUGINS QUOTED "${remake_plugins}")
  else(IS_ABSOLUTE ${PLUGIN_DESTINATION})
    remake_define(PLUGINS QUOTED "${CMAKE_INSTALL_PREFIX}/${remake_plugins}")
  endif(IS_ABSOLUTE ${PLUGIN_DESTINATION})

  remake_component_build(
    LIBRARY ${remake_name}${remake_suffix}
    ${remake_type} ${remake_sources} ${remake_target_sources}
    OUTPUT ${remake_prefix}${remake_name}${remake_suffix}
    ${LINK} ${COMPONENT})
  remake_component_install(
    TARGETS ${remake_name}${remake_suffix}
    LIBRARY DESTINATION ${remake_install}
    ${COMPONENT})
endmacro(remake_add_library)

### \brief Add a plugin library target.
#   This macro automatically defines build rules for a plugin library
#   target from a list of glob expressions. In addition, the macro takes a
#   list of libraries that are linked into the plugin library target.
#   \required[value] name The name of the plugin library target to be defined.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the plugin sources, defaulting to *.c
#     and *.cpp.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] PREFIX:prefix An optional plugin name prefix,
#     defaults to the project's ${PLUGIN_PREFIX}. Note that passing OFF
#     here results in an empty prefix.
#   \optional[value] SUFFIX:suffix An optional plugin name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     plugin library target.
macro(remake_add_plugin remake_name)
  remake_arguments(PREFIX remake_ VAR COMPONENT VAR PREFIX VAR SUFFIX
    ARGN globs LIST LINK ${ARGN})
  remake_set(remake_globs SELF DEFAULT *.c DEFAULT *.cpp)

  remake_project_get(PLUGIN_PREFIX)
  if(NOT DEFINED remake_prefix)
    remake_set(remake_prefix ${PLUGIN_PREFIX})
  endif(NOT DEFINED remake_prefix)
  if(NOT remake_prefix)
    remake_set(remake_prefix)
  endif(NOT remake_prefix)

  get_property(remake_definitions DIRECTORY PROPERTY COMPILE_DEFINITIONS)
  remake_list_values(remake_definitions remake_plugins PLUGINS)
  if(remake_plugins)
    string(REGEX REPLACE "\"(.*)/[^/]*\"" "\\1" remake_plugins
      ${remake_plugins})
  else(remake_plugins)
    remake_project_get(PLUGIN_DESTINATION OUTPUT remake_plugins)
  endif(remake_plugins)

  if(REMAKE_BRANCH_BUILD)
    remake_set(remake_suffix ${REMAKE_BRANCH_SUFFIX})
    remake_branch_link(remake_link TARGET ${remake_name} ${remake_link})
    if(remake_link)
      remake_set(LINK LINK ${remake_link})
    endif(remake_link)
    remake_branch_add_targets(${remake_name})
  endif(REMAKE_BRANCH_BUILD)

  remake_file_glob(remake_sources ${remake_globs})
  remake_target_get_sources(remake_target_sources ${remake_name})

  remake_component_build(
    LIBRARY ${remake_name}${remake_suffix}
    SHARED ${remake_sources} ${remake_target_sources}
    OUTPUT ${remake_prefix}${remake_name}${remake_suffix}
    ${LINK} ${COMPONENT})
  remake_component_install(
    TARGETS ${remake_name}${remake_suffix}
    LIBRARY DESTINATION ${remake_plugins}
    ${COMPONENT})
endmacro(remake_add_plugin)

### \brief Add a single executable target.
#   This macro automatically defines build rules for a single executable target
#   from a list of glob expressions. One target is added that combines all
#   executable sources resolved from the glob expressions. The target bears
#   the specified name. In addition, the macro takes a list of libraries that
#   are linked into the executable target.
#   \required[value] name The name of the executable target to be defined.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the executable's sources, defaulting to *.c
#     and *.cpp.
#   \optional[option] TESTING With this option being present, the executable is
#     assumed to be a testing binary. Consequently, a call to remake_test()
#     creates a testing target for this executable. See ReMakeTest for details.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the executable's install destination, defaults to the project's
#     ${EXECUTABLE_DESTINATION}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] PREFIX:prefix An optional executable name prefix,
#     defaults to the project's ${EXECUTABLE_PREFIX}. Note that passing
#     OFF here results in an empty prefix.
#   \optional[value] SUFFIX:suffix An optional executable name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     executable target.
macro(remake_add_executable remake_name)
  remake_arguments(PREFIX remake_ OPTION TESTING VAR INSTALL VAR COMPONENT
    VAR PREFIX VAR SUFFIX ARGN globs LIST LINK ${ARGN})
  remake_set(remake_globs SELF DEFAULT *.c DEFAULT *.cpp)

  remake_project_get(EXECUTABLE_PREFIX)
  remake_project_get(EXECUTABLE_DESTINATION)
  remake_set(remake_install SELF DEFAULT ${EXECUTABLE_DESTINATION})
  if(NOT DEFINED remake_prefix)
    remake_set(remake_prefix ${EXECUTABLE_PREFIX})
  endif(NOT DEFINED remake_prefix)
  if(NOT remake_prefix)
    remake_set(remake_prefix)
  endif(NOT remake_prefix)

  if(REMAKE_BRANCH_BUILD)
    remake_set(remake_suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_BUILD)

  if(REMAKE_BRANCH_BUILD)
    remake_branch_add_targets(${remake_name})
    remake_branch_link(remake_link ${remake_link})
    if(remake_link)
      remake_set(LINK LINK ${remake_link})
    endif(remake_link)
  endif(REMAKE_BRANCH_BUILD)

  remake_file_glob(remake_sources ${remake_globs})
  remake_target_get_sources(remake_target_sources ${remake_name})

  remake_component_build(
    EXECUTABLE ${remake_name}${remake_suffix}
    ${remake_sources} ${remake_target_sources}
    OUTPUT ${remake_prefix}${remake_name}${remake_suffix}
    ${LINK} ${COMPONENT})
  remake_component_install(
    TARGETS ${remake_name}${remake_suffix}
    RUNTIME DESTINATION ${remake_install}
    ${COMPONENT})

  if(remake_testing)
    remake_test(${remake_name}${remake_suffix})
  endif(remake_testing)
endmacro(remake_add_executable)

### \brief Add multiple executable targets.
#   This macro calls remake_add_executable() to define build rules for
#   executable targets from a list of glob expressions. One target is added
#   for each executable source resolved from the glob expressions. The
#   targets bear the name of the  source file without the file extension.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the executables' sources, defaulting to *.c
#     and *.cpp.
#   \optional[option] TESTING With this option being present, the executables
#     are assumed to be a testing binary. Consequently, a call to remake_test()
#     creates a testing target for these executables. See ReMakeTest for
#     details.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the executables' install destinations, defaults to the project's
#     ${EXECUTABLE_DESTINATION}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] PREFIX:prefix An optional executable name prefix,
#     defaults to the project's ${EXECUTABLE_PREFIX}. Note that passing
#     OFF here results in an empty prefix.
#   \optional[value] SUFFIX:suffix An optional executable name suffix, forced
#     to ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     executable targets.
macro(remake_add_executables)
  remake_arguments(PREFIX remake_ OPTION TESTING VAR INSTALL VAR COMPONENT
    VAR PREFIX VAR SUFFIX ARGN globs LIST LINK ${ARGN})
  remake_set(remake_globs SELF DEFAULT *.c DEFAULT *.cpp)

  remake_file_glob(remake_sources ${remake_globs})
  foreach(remake_source ${remake_sources})
    get_filename_component(remake_name ${remake_source} NAME_WE)
    remake_add_executable(${remake_name} ${remake_source}
      ${TESTING} ${INSTALL} ${COMPONENT} ${PREFIX} ${SUFFIX} ${LINK})
  endforeach(remake_source)
endmacro(remake_add_executables)

### \brief Add header install rules.
#   This macro automatically defines install rules for header files from
#   a list of glob expressions. The install destination of each header file
#   is its relative-path location below ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the header files, defaulting to *.h, *.hpp,
#     and *.tpp.
#   \optional[option] RECURSE If this option is given, header files will
#     be searched recursively in and below ${CMAKE_CURRENT_SOURCE_DIR}. In
#     addtion, for each header the install destination will be appended by its
#     relative-path location below ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the headers' install destination, defaults to the project's
#     ${HEADER_DESTINATION}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(), defaults to
#     ${REMAKE_COMPONENT}-dev. See ReMakeComponent and the CMake documentation
#     for details.
macro(remake_add_headers)
  remake_arguments(PREFIX remake_ OPTION RECURSE VAR INSTALL VAR COMPONENT
    ARGN globs ${ARGN})
  remake_set(remake_globs SELF DEFAULT *.h DEFAULT *.hpp DEFAULT *.tpp)
  remake_component_name(remake_default_component ${REMAKE_COMPONENT} dev)
  remake_set(remake_component SELF DEFAULT ${remake_default_component})

  remake_project_get(HEADER_DESTINATION DESTINATION)
  remake_set(remake_install SELF DEFAULT ${HEADER_DESTINATION})
  if(NOT IS_ABSOLUTE ${remake_install})
    remake_set(remake_install ${HEADER_DESTINATION}/${remake_install})
  endif(NOT IS_ABSOLUTE ${remake_install})

  if(remake_recurse)
    remake_file_glob(
      remake_headers ${remake_globs}
      RECURSE ${CMAKE_CURRENT_SOURCE_DIR})

    foreach(remake_header ${remake_headers})
      if(remake_recurse)
        get_filename_component(remake_header_path ${remake_header} PATH)
        file(RELATIVE_PATH remake_header_dir ${CMAKE_CURRENT_SOURCE_DIR}
          ${remake_header_path})
        remake_set(remake_header_install ${remake_install}/${remake_header_dir})
      endif(remake_recurse)

      remake_component_install(
        FILES ${remake_header}
        DESTINATION ${remake_header_install}
        COMPONENT ${remake_component})
    endforeach(remake_header)
  else(remake_recurse)
    remake_file_glob(remake_headers ${remake_globs})

    remake_component_install(
      FILES ${remake_headers}
      DESTINATION ${remake_install}
      COMPONENT ${remake_component})
  endif(remake_recurse)
endmacro(remake_add_headers)

### \brief Add script install rules.
#   This macro automatically defines install rules for script files from
#   a list of glob expressions.
#   \required[list] glob A list of glob expressions that are resolved in
#     order to find the scripts.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] PREFIX:prefix An optional prefix that is prepended
#     to the script names during installation, defaults to the project's
#     ${SCRIPT_PREFIX}. Note that passing OFF here results in an empty
#     prefix.
#   \optional[value] SUFFIX:suffix An optional suffix that is prepended
#     to the script names during installation, forced to
#     ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
macro(remake_add_scripts)
  remake_arguments(PREFIX remake_ VAR COMPONENT VAR PREFIX VAR SUFFIX
    ARGN globs ${ARGN})

  remake_project_get(SCRIPT_PREFIX)
  remake_project_get(SCRIPT_DESTINATION)
  if(NOT DEFINED remake_prefix)
    remake_set(remake_prefix ${SCRIPT_PREFIX})
  endif(NOT DEFINED remake_prefix)
  if(NOT remake_prefix)
    remake_set(remake_prefix)
  endif(NOT remake_prefix)

  if(REMAKE_BRANCH_BUILD)
    remake_set(remake_suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_BUILD)

  remake_file_glob(remake_scripts ${remake_globs})
  foreach(remake_script ${remake_scripts})
    remake_file_suffix(remake_script_suffixed
      ${remake_script} ${remake_suffix} STRIP)
    remake_component_install(
      PROGRAMS ${remake_script}
      DESTINATION ${SCRIPT_DESTINATION}
      RENAME ${remake_prefix}${remake_script_suffixed}
      ${COMPONENT})
  endforeach(remake_script)
endmacro(remake_add_scripts)

### \brief Add configuration file install rules.
#   This macro automatically defines install rules for configuration targets
#   from a list of glob expressions. As opposed to regular file targets,
#   configuration targets are automatically configured by remake_file_install()
#   prior to the install stage.
#   \required[list] glob A list of glob expressions that are resolved in
#     order to find the configuration file templates.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the configuration files' install destination, defaults to the project's
#     ${CONFIGURATION_DESTINATION}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] SUFFIX:suffix An optional suffix that is prepended
#     to the configuration file names during installation, forced to
#     ${REMAKE_BRANCH_SUFFIX} if defined within a ReMake branch.
macro(remake_add_configurations)
  remake_arguments(PREFIX remake_ VAR INSTALL VAR COMPONENT VAR SUFFIX
    ARGN globs ${ARGN})

  remake_project_get(CONFIGURATION_DESTINATION DESTINATION)
  remake_set(remake_install SELF DEFAULT ${CONFIGURATION_DESTINATION})
  if(NOT IS_ABSOLUTE ${remake_install})
    remake_set(remake_install ${CONFIGURATION_DESTINATION}/${remake_install})
  endif(NOT IS_ABSOLUTE ${remake_install})

  if(REMAKE_BRANCH_BUILD)
    remake_set(remake_suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_BUILD)

  remake_file_configure(${remake_globs} OUTPUT remake_configs)

  foreach(remake_config ${remake_configs})
    file(RELATIVE_PATH remake_config_relative ${CMAKE_CURRENT_BINARY_DIR}
      ${remake_config})
    remake_file_suffix(remake_config_suffixed
      ${remake_config_relative} ${remake_suffix} STRIP)
    remake_component_install(
      FILES ${remake_config}
      DESTINATION ${remake_install}
      RENAME ${remake_config_suffixed}
      ${COMPONENT})
  endforeach(remake_config)
endmacro(remake_add_configurations)

### \brief Add file install rules.
#   This macro automatically defines install rules for file targets
#   from a list of glob expressions.
#   \required[list] glob A list of glob expressions that are resolved in
#     order to find the files.
#   \optional[option] RECURSE If this option is given, file targets will
#     be searched recursively in and below ${CMAKE_CURRENT_SOURCE_DIR}. In
#     addtion, for each file the install destination will be appended by its
#     relative-path location below ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] EXCLUDE:filename An optional list of file names
#     that shall be excluded from the list of file targets, defaulting to
#     CMakeLists.txt.
#   \optional[value] INSTALL:dirname The directory that shall be passed
#     as the files' install destination, defaults to the project's
#     ${FILE_DESTINATION}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install(). See
#     ReMakeComponent and the CMake documentation for details.
#   \optional[value] SUFFIX:suffix An optional suffix that is prepended
#     to the file names during installation, forced to ${REMAKE_BRANCH_SUFFIX}
#     if defined within a ReMake branch.
macro(remake_add_files)
  remake_arguments(PREFIX remake_ OPTION RECURSE LIST EXCLUDE VAR INSTALL
    VAR COMPONENT VAR SUFFIX
    ARGN globs ${ARGN})
  remake_set(remake_exclude SELF DEFAULT CMakeLists.txt)

  remake_project_get(FILE_DESTINATION DESTINATION)
  remake_set(remake_install SELF DEFAULT ${FILE_DESTINATION})
  if(NOT IS_ABSOLUTE ${remake_install})
    remake_set(remake_install ${FILE_DESTINATION}/${remake_install})
  endif(NOT IS_ABSOLUTE ${remake_install})

  if(REMAKE_BRANCH_BUILD)
    remake_set(remake_suffix ${REMAKE_BRANCH_SUFFIX})
  endif(REMAKE_BRANCH_BUILD)

  if(remake_recurse)
    remake_file_glob(
      remake_files ${remake_globs}
      RECURSE ${CMAKE_CURRENT_SOURCE_DIR}
      EXCLUDE ${remake_exclude})
  else(remake_recurse)
    remake_file_glob(
      remake_files ${remake_globs}
      EXCLUDE ${remake_exclude})
    remake_set(remake_file_install ${remake_install})
  endif(remake_recurse)

  foreach(remake_file ${remake_files})
    remake_file_suffix(remake_suffixed ${remake_file} ${remake_suffix} STRIP)
    if(remake_recurse)
      get_filename_component(remake_file_path ${remake_file} PATH)
      file(RELATIVE_PATH remake_file_dir ${CMAKE_CURRENT_SOURCE_DIR}
        ${remake_file_path})
      remake_set(remake_file_install ${remake_install}/${remake_file_dir})
    endif(remake_recurse)

    remake_component_install(
      FILES ${remake_file}
      DESTINATION ${remake_file_install}
      RENAME ${remake_suffixed}
      ${COMPONENT})
  endforeach(remake_file)
endmacro(remake_add_files)

### \brief Add subdirectories.
#   This macro includes subdirectories of the working directory from a list
#   of glob expressions. The directories are added for CMake processing.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the directories, defaulting to *. Note that
#     the correct behavior of directory inclusion might be sensitive to order.
#     In some cases, it is therefore useful to specify directories in the
#     correct order of inclusion.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_switch() before subdirectory
#     inclusion, defaults to ${REMAKE_COMPONENT}. See ReMakeComponent for
#     details.
#   \optional[value] IF:variable The name of a variable that conditions
#     directory inclusion.
macro(remake_add_directories)
  remake_arguments(PREFIX remake_ VAR COMPONENT VAR IF ARGN globs ${ARGN})
  remake_set(remake_component SELF DEFAULT ${REMAKE_COMPONENT})
  remake_set(remake_globs SELF DEFAULT *)
  
  if(remake_if)
    remake_set(remake_option FROM ${remake_if})
  else(remake_if)
    remake_set(remake_option ON)
  endif(remake_if)

  if(remake_option)
    remake_file_glob(remake_dirs DIRECTORIES ${remake_globs})
    foreach(remake_dir ${remake_dirs})
      remake_component_switch(${remake_component}
        CURRENT remake_current_component)
      remake_component_get(${remake_component} BUILD OUTPUT remake_build)
      if(remake_build)
        add_subdirectory(${remake_dir})
      endif(remake_build)
      remake_component_switch(${remake_current_component})
    endforeach(remake_dir)
  endif(remake_option)
endmacro(remake_add_directories)

### \brief Add generated code to an existing target.
#   This macro adds generated code to an exisitng target, using the requested
#   generator for source code generation. Additional arguments passed to the
#   macro are forwarded to the selected generator.
#   \required[option] FLEX|BISON|CUSTOM The generator to be called for source
#     code generation.
#   \required[list] arg The arguments to be forwared to the source code
#     generator. See ReMakeGenerate for details.
macro(remake_add_generated remake_generator)
  if(${remake_generator} MATCHES "FLEX")
    remake_generate_flex(${ARGN})
  elseif(${remake_generator} MATCHES "BISON")
    remake_generate_bison(${ARGN})
  elseif(${remake_generator} MATCHES "CUSTOM")
    remake_generate_custom(${ARGN})
  endif(${remake_generator} MATCHES "FLEX")
endmacro(remake_add_generated)

### \brief Add a documentation target.
#   This macro adds a documentation target, using the requested generator
#   for document generation. Additional arguments passed to the macro are
#   forwarded to the selected generator.
#   \required[option] SOURCE|CONFIGURE|DOYXGEN|GROFF|CUSTOM The generator to
#     be used for document generation.
#   \required[list] arg The arguments to be forwared to the document
#     generator. See ReMakeDoc for details.
macro(remake_add_documentation remake_generator)
  if(${remake_generator} MATCHES "SOURCE")
    remake_doc_source(${ARGN})
  elseif(${remake_generator} MATCHES "CONFIGURE")
    remake_doc_configure(${ARGN})
  elseif(${remake_generator} MATCHES "DOXYGEN")
    remake_doc_doxygen(${ARGN})
  elseif(${remake_generator} MATCHES "GROFF")
    remake_doc_groff(${ARGN})
  elseif(${remake_generator} MATCHES "CUSTOM")
    remake_doc_custom(${ARGN})
  endif(${remake_generator} MATCHES "SOURCE")
endmacro(remake_add_documentation)

### \brief Add a package build target.
#   This macro adds a package build target, using the requested generator
#   for package generation. Additional arguments passed to the macro are
#   forwarded to the selected generator.
#   \optional[var] GENERATOR:generator The generator to be used for package
#     generation, defaults to DEB.
#   \required[list] arg The arguments to be forwared to the package
#     generator. See ReMakeOack for details.
#   \optional[value] IF:variable The name of a variable that conditions
#     package generation.
macro(remake_add_package)
  remake_arguments(PREFIX remake_ VAR GENERATOR VAR IF ARGN args ${ARGN})
  remake_set(remake_generator SELF DEFAULT DEB)

  if(remake_if)
    remake_set(remake_option FROM ${remake_if})
  else(remake_if)
    remake_set(remake_option ON)
  endif(remake_if)

  if(remake_option)
    if(${remake_generator} MATCHES "DEB")
      remake_pack_deb(${remake_args})
    endif(${remake_generator} MATCHES "DEB")
  endif(remake_option)
endmacro(remake_add_package)

### \brief Add directories to the include path.
#   This macro adds a list of directories to the compiler's include path.
#   As opposed to CMake's include_directories(), the macro converts
#   directory names into absolute-path names before passing them as
#   arguments to include_directories(). If defined within a ReMake branch,
#   the macro calls remake_branch_include() instead.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the directories to be added to the compiler's
#     include path, defaults to the current directory.
macro(remake_include)
  remake_arguments(PREFIX remake_ ARGN globs ${ARGN})
  remake_set(remake_globs SELF DEFAULT ${CMAKE_CURRENT_SOURCE_DIR})

  if(REMAKE_BRANCH_BUILD)
    remake_branch_include(remake_dirs ${remake_globs})
  else(REMAKE_BRANCH_BUILD)
    remake_file_glob(remake_dirs DIRECTORIES ${remake_globs})
  endif(REMAKE_BRANCH_BUILD)

  include_directories(${remake_dirs})
endmacro(remake_include)

### \brief Add a flag to the compiler command line.
#   This macro defines a variable and appends a flag to the compiler command
#   line for sources in the current directory or below. If the flag variable
#   is Boolean and ON, -D${VARIABLE} is added to the compile definitions.
#   For regular string values, the list of compile definitions is extended by
#   -D${VARIABLE}=${VALUE}.
#   \required[value] variable The name of the flag variable to be defined and
#     added to the compiler command line.
#   \optional[option] QUOTED If this option is present, the flag variable is
#     assumed to be of type string and quotes are added to the compiler
#     definition.
#   \required[list] value A list of values to be passed on to remake_set().
#     See ReMakePrivate for correct usage.
macro(remake_define remake_var)
  remake_arguments(PREFIX remake_ OPTION QUOTED ARGN values ${ARGN})

  remake_set(${remake_var} ${remake_values})
  if(${remake_var})
    if(remake_quoted)
      add_definitions(-D${remake_var}="${${remake_var}}")
    else(remake_quoted)
      if(${remake_var} MATCHES "ON")
        add_definitions(-D${remake_var})
      else(${remake_var} MATCHES "ON")
        add_definitions(-D${remake_var}=${${remake_var}})
      endif(${remake_var} MATCHES "ON")
    endif(remake_quoted)
  endif(${remake_var})
endmacro(remake_define)
