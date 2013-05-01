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

### \brief ReMake component macros
#   The ReMake component module provides basic functionalities for managing
#   component-based project structures.

if(NOT DEFINED REMAKE_COMPONENT_CMAKE)
  remake_set(REMAKE_COMPONENT_CMAKE ON)

  remake_set(REMAKE_COMPONENT_TARGET_SUFFIX component)
endif(NOT DEFINED REMAKE_COMPONENT_CMAKE)

### \brief Define a new ReMake component.
#   This macro defines a new ReMake component. It initializes a project flag
#   variable that can be evaluated by other modules, e.g. for enabling or
#   disabling component-specific build targets. Note that the value of this
#   build flag always defaults to ON. Furthermore, a new top-level target is
#   defined for the component. All component-specific build rules and commands
#   will then be declared to act as dependencies of that target. To facilitate
#   component-specific filenames, install name prefixes, and install
#   destinations, special project variables may be defined to override
#   project-wide variables. Any such variable will implicitly default to the
#   corresponding project setting.
#   \optional[value] name The name of the project component to be defined.
#   \optional[value] FILENAME:name An optional and valid filename that is
#     used to initialize the component-specific filename, defaults to the
#     filename conversion of ${REMAKE_PROJECT_FILENAME}-${COMPONENT_NAME}.
#   \optional[value] PREFIX:prefix The optional target prefix that, if
#     provided, is passed to remake_component_prefix().
#   \optional[value] INSTALL:dir The optional directory that shall be used as
#     the component's specific install prefix. If the directory corresponds
#     to a relative path, it will act as a suffix on the project-wide install
#     prefix. Otherwise, it will override this prefix for install rules
#     associated with the component.
#   \optional[value] LIBRARY_DESTINATION:dir The optional destination
#     directory of the component libraries.
#   \optional[value] EXECUTABLE_DESTINATION:dir The optional destination
#     directory of the component executables.
#   \optional[value] PLUGIN_DESTINATION:dir The optional destination
#     directory of the component plugins.
#   \optional[value] SCRIPT_DESTINATION:dir The optional destination
#     directory of the component scripts.
#   \optional[value] FILE_DESTINATION:dir The optional destination directory
#     of the component files.
#   \optional[value] CONFIGURATION_DESTINATION:dir The optional destination
#     directory of the component configuration files.
#   \optional[value] HEADER_DESTINATION:dir The optional destination
#     directory of the component development headers.
#   \optional[option] DEFAULT If present, this option declares the new
#     component to be the default, i.e. no cache variables will be created
#     that allows for the user to enable or disable the build or to specify
#     the component-specific install destination. Also,
#     ${REMAKE_DEFAULT_COMPONENT} is initialized with the name of the
#     component.
macro(remake_component component_name)
  remake_arguments(PREFIX component_ VAR FILENAME VAR PREFIX VAR INSTALL
    VAR LIBRARY_DESTINATION VAR EXECUTABLE_DESTINATION VAR PLUGIN_DESTINATION
    VAR SCRIPT_DESTINATION VAR FILE_DESTINATION VAR CONFIGURATION_DESTINATION
    VAR HEADER_DESTINATION OPTION DEFAULT ${ARGN})
  remake_file_name(component_default_filename ${component_name})
  remake_set(component_filename SELF DEFAULT
    ${REMAKE_PROJECT_FILENAME}-${component_default_filename})

  remake_project_get(COMPONENTS OUTPUT component_components)
  list(FIND component_components ${component_name} component_index)

  if(component_index LESS 0)
    remake_project_set(COMPONENTS ${component_components} ${component_name}
      CACHE INTERNAL "Install components defined by the project.")
    if(component_default)
      remake_set(REMAKE_DEFAULT_COMPONENT ${component_name})
      remake_component_set(${component_name} BUILD ON CACHE INTERNAL
        "Build ${component_name} component.")
    else(component_default)
      remake_component_set(${component_name} BUILD ON CACHE BOOL
        "Build ${component_name} component.")
      if(component_filename)
        remake_component_set(${component_name} FILENAME
          ${component_filename} CACHE INTERNAL
          "Filename defined for ${component_name} component.")
      endif(component_filename)
      if(DEFINED component_prefix)
        remake_component_prefix(${component_name}
          LIBRARY ${component_prefix}
          PLUGIN  ${component_prefix}
          EXECUTABLE ${component_prefix}
          SCRIPT ${component_prefix})
      endif(DEFINED component_prefix)
      if(component_install)
        remake_component_set(${component_name} INSTALL_PREFIX
          ${component_install} CACHE STRING
          "Install path prefix of ${component_name} component.")
      endif(component_install)
      if(component_library_destination)
        remake_component_set(${component_name} LIBRARY_DESTINATION
          ${component_library_destination} CACHE STRING
          "Install destination of ${component_name} component libraries.")
      endif(component_library_destination)
      if(component_executable_destination)
        remake_component_set(${component_name} EXECUTABLE_DESTINATION
          ${component_executable_destination} CACHE STRING
          "Install destination of ${component_name} component executables.")
      endif(component_executable_destination)
      if(component_plugin_destination)
        remake_component_set(${component_name} PLUGIN_DESTINATION
          ${component_plugin_destination} CACHE STRING
          "Install destination of ${component_name} component plugins.")
      endif(component_plugin_destination)
      if(component_script_destination)
        remake_component_set(${component_name} SCRIPT_DESTINATION
          ${component_script_destination} CACHE STRING
          "Install destination of ${component_name} component scripts.")
      endif(component_script_destination)
      if(component_file_destination)
        remake_component_set(${component_name} FILE_DESTINATION
          ${component_file_destination} CACHE STRING
          "Install destination of ${component_name} component files.")
      endif(component_file_destination)
      if(component_configuration_destination)
        remake_component_set(${component_name} CONFIGURATION_DESTINATION
          ${component_configuration_destination} CACHE STRING
          "Install destination of ${component_name} component configuration files.")
      endif(component_configuration_destination)
      if(component_header_destination)
        remake_component_set(${component_name} HEADER_DESTINATION
          ${component_header_destination} CACHE STRING
          "Install destination of ${component_name} component development headers.")
      endif(component_header_destination)
    endif(component_default)

    remake_component_get(${component_name} BUILD OUTPUT component_build)
    if(component_build)
      remake_target_name(component_all_target
        ${component_name} ${REMAKE_COMPONENT_TARGET_SUFFIX})
      remake_target(${component_all_target} ALL
        COMMENT "Building ${component_name} component")
    endif(component_build)
  endif(component_index LESS 0)
endmacro(remake_component)

### \brief Output a valid component name from a set of strings.
#   This macro is a helper macro to generates valid component names from
#   arbitrary strings. It replaces whitespace characters and CMake list
#   separators by scores and performs a lower-case conversion of the
#   result. Also, ${REMAKE_DEFAULT_COMPONENT} is automatically stripped
#   from the beginning of the name.
#   \required[value] variable The name of a variable to be assigned the
#     generated component name.
#   \required[list] string A list of strings to be concatenated to the
#     component name.
macro(remake_component_name component_var)
  string(REGEX REPLACE "^${REMAKE_DEFAULT_COMPONENT}[;]" ""
    component_args "${ARGN}")
  string(TOLOWER "${component_args}" component_lower)
  string(REGEX REPLACE "[ ;]" "-" ${component_var} "${component_lower}")
endmacro(remake_component_name)

### \brief Output a component-specific target name from a set of strings.
#   This macro is a helper macro to generate component-specific target names
#   from arbitrary strings. It therefore prepends the component name to the
#   set of strings and passes them to remake_target_name(). See ReMakeTarget
#   for details.
#   \required[value] variable The name of a variable to be assigned the
#     generated target name.
#   \required[list] string A list of strings to be concatenated to the
#     target name.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is used to generate the target name, defaults to
#     ${REMAKE_COMPONENT}.
macro(remake_component_target_name component_var)
  remake_arguments(PREFIX component_ VAR COMPONENT ARGN strings ${ARGN})
  remake_set(component_name FROM component_component
    DEFAULT ${REMAKE_COMPONENT})

  remake_target_name(${component_var} ${component_name} ${component_strings})
endmacro(remake_component_target_name)

### \brief Define the value of a ReMake component variable.
#   This macro defines a component variable matching the ReMake naming
#   conventions. The variable name is automatically prefixed with an
#   upper-case conversion of the component name. Thus, variables may
#   appear in the cache as project variables named after
#   ${COMPONENT_NAME}_COMPONENT_${VAR_NAME}. Additional arguments are
#   passed on to remake_project_set(). Note that the component needs to
#   be defined.
#   \required[value] name The name of the component to define the
#     variable for.
#   \optional[list] arg The arguments to be passed on to remake_project_set().
#      See ReMakeProject for details.
macro(remake_component_set component_name component_var)
  remake_project_get(COMPONENTS OUTPUT component_components)
  list(FIND component_components ${component_name} component_index)

  if(component_index GREATER -1)
    remake_var_name(component_global_var
      ${component_name} COMPONENT ${component_var})
    remake_project_set(${component_global_var} ${ARGN})
  else(component_index GREATER -1)
    message(FATAL_ERROR "Component ${component_name} undefined!")
  endif(component_index GREATER -1)
endmacro(remake_component_set)

### \brief Retrieve the value of a ReMake component variable.
#   This macro retrieves a component variable matching the ReMake
#   naming conventions. Specifically, variables named after
#   ${COMPONENT_NAME}_COMPONENT_${VAR_NAME} can be found by passing
#   ${VAR_NAME} to this macro. If such a component variable is undefined,
#   the macro will retrieve the corresponding project-wide variable by
#   calling remake_project_get() instead. By default, the macro defines
#   an output variable named ${VAR_NAME} which will be assigned the value
#   of the queried component variable. Note that the component needs to
#   be defined.
#   \required[value] name The name of the component to retrieve the
#     variable for.
#   \required[value] variable The name of the component variable to be
#     retrieved.
#   \optional[option] DESTINATION This option tells the macro to treat the
#     component variable as install destination. If the destination contains
#     a relative install path, it will be automatically prefixed by the
#     component's install prefix.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried component variable.
macro(remake_component_get component_name component_var)
  remake_arguments(PREFIX component_ OPTION DESTINATION VAR OUTPUT ${ARGN})

  remake_project_get(COMPONENTS OUTPUT component_components)
  list(FIND component_components ${component_name} component_index)

  if(component_index GREATER -1)
    remake_var_name(component_global_var
      ${component_name} COMPONENT ${component_var})
    remake_set(component_output SELF DEFAULT ${component_var})

    remake_project_get(${component_global_var} OUTPUT ${component_output})

    if(DEFINED ${component_output})
      if(component_destination)
        if(NOT IS_ABSOLUTE ${component_output})
          remake_component_get(${component_name} INSTALL_PREFIX
            OUTPUT ${component_install})
          get_filename_component(${component_output}
            ${component_install}/${${component_output}} ABSOLUTE)
        endif(NOT IS_ABSOLUTE ${component_output})
      endif(component_destination)
    else(DEFINED ${component_output})
      remake_project_get(${component_var} OUTPUT ${component_output}
        ${DESTINATION})
    endif(DEFINED ${component_output})
  else(component_index GREATER -1)
    message(FATAL_ERROR "Component ${component_name} undefined!")
  endif(component_index GREATER -1)
endmacro(remake_component_get)

### \brief Define the ReMake component prefix for target output.
#   This macro initializes the internal ReMake component prefix for libraries,
#   plugins, and executables produced by all targets defined for the specified
#   component. It gets invoked by remake_component() and needs not be called
#   directly from a CMakeLists.txt file.
#   \optional[value] name The name of the project component to define the
#     prefixes for.
#   \optional[value] LIBRARY:prefix The prefix that is used for producing
#     component libraries, extending library names to ${PREFIX}${LIB_NAME}.
#   \optional[value] PLUGIN:prefix The prefix that is used for producing
#     component plugins, extending plugin names to ${PREFIX}${PLUGIN_NAME}.
#   \optional[value] EXECUTABLE:prefix The prefix that is used for producing
#     component executables, extending executable names to
#     ${PREFIX}${EXECUTABLE_NAME}.
#   \optional[value] SCRIPT:prefix The prefix that is used for producing
#     component scripts, extending script names to ${PREFIX}${SCRIPT_NAME}.
macro(remake_component_prefix component_name)
  remake_arguments(PREFIX component_ VAR LIBRARY VAR PLUGIN VAR EXECUTABLE
    VAR SCRIPT ${ARGN})

  if(DEFINED component_library)
    remake_component_set(${component_name}
      LIBRARY_PREFIX FROM component_library
      CACHE INTERNAL "Name prefix of ${component_name} component libraries.")
  endif(DEFINED component_library)
  if(DEFINED component_plugin)
    remake_component_set(${component_name}
      PLUGIN_PREFIX FROM component_plugin
      CACHE INTERNAL "Name prefix of ${component_name} component plugins.")
  endif(DEFINED component_plugin)
  if(DEFINED component_executable)
    remake_component_set(${component_name}
      EXECUTABLE_PREFIX FROM component_executable
      CACHE INTERNAL "Name prefix of ${component_name} component executables.")
  endif(DEFINED component_executable)
  if(DEFINED component_script)
    remake_component_set(${component_name}
      SCRIPT_PREFIX FROM component_script
      CACHE INTERNAL "Name prefix of ${component_name} component scripts.")
  endif(DEFINED component_script)
endmacro(remake_component_prefix)

### \brief Switch the current ReMake component.
#   This macro changes the value of ${REMAKE_COMPONENT}. Thus, all future
#   calls to remake_component_build() or remake_component_install() will pass
#   the new value of ${REMAKE_COMPONENT} as the default install component for
#   targets. This is particularly useful in cases where entire subdirectories
#   shall be assigned to specific components.
#   \required[value] name The name of the component to be assigned to
#     ${REMAKE_COMPONENT}.
#   \optional[value] CURRENT:variable The name of an output variable that
#     will be assigned the current value of ${REMAKE_COMPONENT}. Note that
#     the caller of this marco might be responsible for restoring
#     ${REMAKE_COMPONENT} using its former value.
macro(remake_component_switch component_name)
  remake_arguments(PREFIX component_ VAR CURRENT ${ARGN})

  if(component_current)
    remake_set(${component_current} ${REMAKE_COMPONENT})
  endif(component_current)
  remake_component(${component_name})
  remake_set(REMAKE_COMPONENT ${component_name})
endmacro(remake_component_switch)

### \brief Specify component-specific rules to run at build time.
#   This macro defines component-specific build rules by calling CMake's
#   add_library() or add_executable() with the provided component name and
#   all additional arguments. The use of this macro is strongly encouraged
#   over the CMake standard macros since it allows for special treating
#   of component-specific rules.
#   \required[option] LIBRARY|EXECUTABLE The type of the target to be built.
#     Note that the macro will automatically invoke CMake's add_library() if
#     the type corresponds to LIBRARY. Likewise, if the type resolves to
#     EXECUTABLE, CMake's add_executable() will be called.
#   \required[value] target The name of the target to be defined.
#   \optional[list] arg The arguments to be passed on to CMake's
#     add_library() or add_executable() macro. See the CMake documentation
#     for further details.
#   \optional[value] COMPONENT:name The optional name of the component for
#     which install rules shall be defined, defaults to ${REMAKE_COMPONENT}.
#   \optional[value] OUTPUT:name The optional real name of the target that
#     will be set through CMake's OUTPUT_NAME property.
#   \optional[list] LINK:lib The list of libraries to be linked into the
#     build target.
macro(remake_component_build component_type component_target)
  remake_arguments(PREFIX component_ VAR COMPONENT VAR OUTPUT LIST LINK
    ARGN args ${ARGN})
  remake_set(component_name FROM component_component
    DEFAULT ${REMAKE_COMPONENT})

  remake_component(${component_name})
  remake_component_get(${component_name} BUILD OUTPUT component_build)
  if(component_build)
    if(${component_type} STREQUAL LIBRARY)
      add_library(${component_target} ${component_args})
    elseif(${component_type} STREQUAL EXECUTABLE)
      add_executable(${component_target} ${component_args})
    endif(${component_type} STREQUAL LIBRARY)

    remake_arguments(PREFIX component_ VAR OUTPUT ${ARGN})
    if(component_output)
      set_target_properties(${component_target}
        PROPERTIES OUTPUT_NAME ${component_output})
    endif(component_output)
    if(component_link)
      target_link_libraries(${component_target} ${component_link})
    endif(component_link)

    remake_target_name(component_all_target
      ${component_name} ${REMAKE_COMPONENT_TARGET_SUFFIX})
    add_dependencies(${component_all_target} ${component_target})
  endif(component_build)
endmacro(remake_component_build)

### \brief Specify a component-specific custom build rule.
#   This macro defines a component-specific custom build rule by calling
#   remake_target_add_command() for the top-level target of the component
#   with the provided name. The use of this macro is strongly encouraged
#   over the CMake standard macros since it allows for special treating
#   of component-specific rules.
#   \optional[list] arg The arguments to be passed on to
#     remake_target_add_command(). See ReMakeTarget for further details.
#   \optional[value] COMPONENT:name The optional name of the component
#     for which custom build rules shall be defined, defaults to
#     ${REMAKE_COMPONENT}.
macro(remake_component_add_command)
  remake_arguments(PREFIX component_ VAR COMPONENT ARGN args ${ARGN})
  remake_set(component_name FROM component_component
    DEFAULT ${REMAKE_COMPONENT})

  remake_component(${component_name})
  remake_component_get(${component_name} BUILD OUTPUT component_build)
  if(component_build)
    remake_target_name(component_all_target
      ${component_name} ${REMAKE_COMPONENT_TARGET_SUFFIX})
    remake_target_add_command(${component_all_target} ${component_args})
  endif(component_build)
endmacro(remake_component_add_command)

### \brief Add component-specific target dependencies.
#   This macro defines dependencies between the component target and other
#   component-specific top-level targets by calling CMake's add_dependencies().
#   \optional[value] COMPONENT:name The optional name of the component
#     for which the dependencies shall be defined, defaults to
#     ${REMAKE_COMPONENT}.
#   \optional[list] PROVIDES:target A list of component-specific top-level
#     targets that should depend on the component target.
#   \optional[list] DEPENDS:target A list of component-specific top-level
#     targets that the component target should depend on.
macro(remake_component_add_dependencies)
  remake_arguments(PREFIX component_ VAR COMPONENT LIST PROVIDES
    LIST DEPENDS ${ARGN})
  remake_set(component_name FROM component_component
    DEFAULT ${REMAKE_COMPONENT})

  remake_component(${component_name})
  remake_component_get(${component_name} BUILD OUTPUT component_build)
  if(component_build)
    remake_target_name(component_all_target
      ${component_name} ${REMAKE_COMPONENT_TARGET_SUFFIX})

    foreach(component_target ${component_provides})
      add_dependencies(${component_target} ${component_all_target})
    endforeach(component_target)
    if(component_depends)
      add_dependencies(${component_all_target} ${component_depends})
    endif(component_depends)
  endif(component_build)
endmacro(remake_component_add_dependencies)

### \brief Specify component-specific rules to run at install time.
#   This macro defines component-specific install rules by calling CMake's
#   install() with the provided component name and all additional arguments.
#   The use of this macro is strongly encouraged over the CMake standard
#   macro since it allows for special treatment of component-specific install
#   parameters, such as the install prefix provided for each component.
#   \optional[list] arg The arguments to be passed on to CMake's
#     install() macro.
#   \optional[value] DESTINATION:dir The install destination which will
#     be prefixed with the install destination defined for the component
#     and then passed on to CMake's install() macro. The special value
#     OFF entails for the resulting install destination to correspond to
#     the component's install destination.
#   \optional[value] COMPONENT:name The name of the component for which
#     install rules shall be defined, defaults to ${REMAKE_COMPONENT}.
macro(remake_component_install)
  remake_arguments(PREFIX component_ VAR COMPONENT VAR DESTINATION
    ARGN args ${ARGN})
  remake_set(component_name FROM component_component
    DEFAULT ${REMAKE_COMPONENT})
  remake_set(component_install_dest FROM component_destination)

  remake_component(${component_name})
  remake_component_get(${component_name} BUILD OUTPUT component_build)
  if(component_build)
    if(DEFINED component_install_dest)
      if(component_install_dest)
        if(NOT IS_ABSOLUTE ${component_install_dest})
          remake_component_get(${component_name} INSTALL_PREFIX OUTPUT
            component_install_prefix)
          if(component_install_prefix)
            remake_set(component_install_dest
              "${component_install_prefix}/${component_install_dest}")
          endif(component_install_prefix)
        endif(NOT IS_ABSOLUTE ${component_install_dest})
      else(component_install_dest)
        remake_component_get(${component_name} INSTALL_PREFIX OUTPUT
          component_install_prefix)
        if(NOT IS_ABSOLUTE ${component_install_prefix})
          remake_set(component_install_dest
            "${CMAKE_INSTALL_PREFIX}/${component_install_prefix}")
        else(NOT IS_ABSOLUTE ${component_install_prefix})
          remake_set(component_install_dest "${component_install_prefix}")
        endif(NOT IS_ABSOLUTE ${component_install_prefix})
      endif(component_install_dest)
    endif(DEFINED component_install_dest)

    if(component_install_dest)
      install(${component_args}
        DESTINATION ${component_install_dest}
        COMPONENT ${component_name})
    else(component_install_dest)
      install(${component_args}
      COMPONENT ${component_name})
    endif(component_install_dest)
  endif(component_build)
endmacro(remake_component_install)
