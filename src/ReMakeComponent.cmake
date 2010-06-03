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

remake_set(REMAKE_COMPONENT_DIR ReMakeComponents)

### \brief Define a new ReMake component.
#   This macro defines a new ReMake component. It initializes a project flag
#   variable that can be evaluated by other modules, e.g. for enabling or
#   disabling component-specific build targets. Note that the value of this
#   build flag always defaults to ON.
#   \optional[value] name The name of the project component to be defined.
#   \optional[option] DEFAULT If present, this option declares the new
#     component to be the default, i.e. no cache variable will be created
#     that allows for the user to enable or disable the build. Also,
#     ${REMAKE_DEFAULT_COMPONENT} is initialized with the name of the
#     component.
macro(remake_component component_name)
  remake_arguments(PREFIX component_ OPTION DEFAULT ${ARGN})

  remake_file_read(component_defs ${REMAKE_COMPONENT_FILE} TOPLEVEL)
  remake_list_contains(component_defs ANY component_defined ${component_name})

  if(NOT component_defined)
    remake_var_name(component_option BUILD ${component_name})
    if(component_default)
      remake_set(REMAKE_DEFAULT_COMPONENT ${component_name})
      remake_project_set(${component_option} ON BOOL)
    else(component_default)
      remake_project_set(${component_option} ON CACHE BOOL
        "Build ${component_name} component.")
    endif(component_default)

    remake_file_write(${REMAKE_COMPONENT_FILE} TOPLEVEL ${component_name})
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

### \brief Retrieve the value of a component build flag.
#   This macro retrieves the build flag for a ReMake component. It can be
#   evaluated in order to enable or disable component-specific build targets.
#   \required[value] name The name of the component to retrieve the build
#     flag for.
#   \required[value] variable The name of an output variable that will be
#     assigned the value of the component's build flag.
macro(remake_component_build component_name component_var)
  remake_file_read(component_defs ${REMAKE_COMPONENT_FILE} TOPLEVEL)
  remake_list_contains(component_defs ANY component_defined
    ${component_name})

  if(component_defined)
    remake_var_name(component_option BUILD ${component_name})
    remake_project_get(${component_option} OUTPUT ${component_var})
  else(component_defined)
    remake_set(${component_var} OFF)
  endif(component_defined)
endmacro(remake_component_build)

### \brief Set the ReMake component.
#   This macro changes the value of ${REMAKE_COMPONENT}. Thus, all future
#   calls to remake_component_install() will pass the new value of
#   ${REMAKE_COMPONENT} as the default install component for targets. This
#   is particularly useful in cases where entire subdirectories shall be
#   assigned to specific components.
#   \required[value] name The name of the component to be assigned to
#     ${REMAKE_COMPONENT}.
#   \optional[value] CURRENT:variable The name of an output variable that
#     will be assigned the current value of ${REMAKE_COMPONENT}. Note that
#     the caller of this marco might be responsible for restoring
#     ${REMAKE_COMPONENT} using its former value.
macro(remake_component_set component_name)
  remake_arguments(PREFIX component_ VAR CURRENT ${ARGN})

  if(component_current)
    remake_set(${component_current} ${REMAKE_COMPONENT})
  endif(component_current)
  remake_set(REMAKE_COMPONENT ${component_name})
endmacro(remake_component_set)

### \brief Specifiy component-specific rules to run at install time.
#   This macro defines component-specific install rules by calling CMake's
#   install() with the provided component name and all additional arguments.
#   \optional[value] COMPONENT:name The name of the component for which
#     install rules shall be defined, defaults to ${REMAKE_COMPONENT}.
#   \optional[list] arg The arguments to be passed on to CMake's
#     install() macro.
macro(remake_component_install)
  remake_arguments(PREFIX component_ VAR COMPONENT ARGN args ${ARGN})

  remake_set(component_component SELF DEFAULT ${REMAKE_COMPONENT})
  install(${component_args} COMPONENT ${component_component})
endmacro(remake_component_install)

remake_file(REMAKE_COMPONENT_FILE ${REMAKE_COMPONENT_DIR}/defined)
remake_file_create(${REMAKE_COMPONENT_FILE})
