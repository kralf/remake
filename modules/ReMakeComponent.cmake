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

remake_set(REMAKE_COMPONENT_TARGET_SUFFIX component)

remake_file(REMAKE_COMPONENT_DIR ReMakeComponents TOPLEVEL)

### \brief Define a new ReMake component.
#   This macro defines a new ReMake component. It initializes a project flag
#   variable that can be evaluated by other modules, e.g. for enabling or
#   disabling component-specific build targets. Note that the value of this
#   build flag always defaults to ON. Furthermore, a new top-level target is
#   defined for the component. All component-specific build rules and commands
#   will then be declared to act as dependencies of that target.
#   \optional[value] name The name of the project component to be defined.
#   \optional[option] DEFAULT If present, this option declares the new
#     component to be the default, i.e. no cache variable will be created
#     that allows for the user to enable or disable the build. Also,
#     ${REMAKE_DEFAULT_COMPONENT} is initialized with the name of the
#     component.
macro(remake_component component_name)
  remake_arguments(PREFIX component_ OPTION DEFAULT ${ARGN})

  remake_file_glob(component_defs * WORKING_DIRECTORY ${REMAKE_COMPONENT_DIR}
    ${component_glob} RELATIVE)
  remake_list_contains(component_defs ANY component_defined ${component_name})

  if(NOT component_defined)
    remake_file_create(${REMAKE_COMPONENT_DIR}/${component_name} TOPLEVEL)
    if(component_default)
      remake_set(REMAKE_DEFAULT_COMPONENT ${component_name})
      remake_component_set(${component_name} BUILD ON BOOL)
    else(component_default)
      remake_component_set(${component_name} BUILD ON CACHE BOOL
        "Build ${component_name} component.")
    endif(component_default)

    remake_component_get(${component_name} BUILD OUTPUT component_build)
    if(component_build)
      remake_target_name(component_all_target
        ${component_name} ${REMAKE_COMPONENT_TARGET_SUFFIX})
      remake_target(${component_all_target} ALL
        COMMENT "Building ${component_name} component")
    endif(component_build)
  endif(NOT component_defined)
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
#   passed on to remake_project_set().
#   \required[value] name The name of the component to define the
#     variable for.
#   \optional[list] arg The arguments to be passed on to remake_project_set().
#      See ReMakeProject for details.
macro(remake_component_set component_name component_var)
  remake_file_glob(component_defs * WORKING_DIRECTORY ${REMAKE_COMPONENT_DIR}
    ${component_glob} RELATIVE)
  remake_list_contains(component_defs ANY component_defined ${component_name})

  if(component_defined)
    remake_var_name(component_global_var
      ${component_name} COMPONENT ${component_var})
    remake_project_set(${component_global_var} ${ARGN})
  endif(component_defined)
endmacro(remake_component_set)

### \brief Retrieve the value of a ReMake component variable.
#   This macro retrieves a component variable matching the ReMake
#   naming conventions. Specifically, variables named after
#   ${COMPONENT_NAME}_COMPONENT_${VAR_NAME} can be found by passing
#   ${VAR_NAME} to this macro. By default, the macro defines an output
#   variable named ${VAR_NAME} which will be assigned the value of the
#   queried component variable.
#   \required[value] name The name of the component to retrieve the
#     variable for.
#   \required[value] variable The name of the component variable to be
#     retrieved.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried component variable.
macro(remake_component_get component_name component_var)
  remake_arguments(PREFIX component_ VAR OUTPUT ${ARGN})

  remake_file_glob(component_defs * WORKING_DIRECTORY ${REMAKE_COMPONENT_DIR}
    ${component_glob} RELATIVE)
  remake_list_contains(component_defs ANY component_defined ${component_name})

  if(component_defined)
    remake_var_name(component_global_var
      ${component_name} COMPONENT ${component_var})
    if(component_output)
      remake_project_get(${component_global_var} OUTPUT ${component_output})
    else(component_output)
      remake_project_get(${component_global_var} OUTPUT ${component_var})
    endif(component_output)
  else(component_defined)
    if(component_output)
      remake_set(${component_output})
    else(component_output)
      remake_set(${component_var})
    endif(component_output)
  endif(component_defined)
endmacro(remake_component_get)

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
#   all additional arguments. The use of this macro is stronly encouraged
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
#   with the provided name. The use of this macro is stronly encouraged
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

### \brief Specifiy component-specific rules to run at install time.
#   This macro defines component-specific install rules by calling CMake's
#   install() with the provided component name and all additional arguments.
#   The use of this macro is stronly encouraged over the CMake standard
#   macro since it allows for special treating of component-specific rules.
#   \optional[list] arg The arguments to be passed on to CMake's
#     install() macro.
#   \optional[value] COMPONENT:name The name of the component for which
#     install rules shall be defined, defaults to ${REMAKE_COMPONENT}.
macro(remake_component_install)
  remake_arguments(PREFIX component_ VAR COMPONENT ARGN args ${ARGN})
  remake_set(component_name FROM component_component
    DEFAULT ${REMAKE_COMPONENT})

  remake_component(${component_name})
  remake_component_get(${component_name} BUILD OUTPUT component_build)
  if(component_build)
    install(${component_args} COMPONENT ${component_name})
  endif(component_build)
endmacro(remake_component_install)

remake_file_rmdir(${REMAKE_COMPONENT_DIR})
remake_file_mkdir(${REMAKE_COMPONENT_DIR})
