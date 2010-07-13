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

include(ReMakeFile)
include(ReMakeComponent)

include(ReMakePrivate)

### \brief ReMake Python macros
#   The ReMake Python macros provide convenient targets for the distribution
#   of Python modules and extensions using generators such as the Simplified
#   Wrapper and Interface Generator (SWIG).

remake_set(REMAKE_PYTHON_DIR ReMakePython)
remake_set(REMAKE_PYTHON_PACKAGE_DIR ${REMAKE_PYTHON_DIR}/packages)
remake_set(REMAKE_PYTHON_DIST_DIR ${REMAKE_PYTHON_DIR}/distribution)
remake_set(REMAKE_PYTHON_COMPONENT_SUFFIX python)
remake_set(REMAKE_PYTHON_TARGET_SUFFIX python_package)

### \brief Configure Python package distribution.
#   This macro discovers the Python installation and configures Python
#   package distribution. It initializes a project variable named
#   PYTHON_MODULE_DESTINATION that holds the default install destination
#   of all packages and defaults to the local Python distribution root. The
#   macro should be called in the project root's CMakeLists.txt file, before
#   any other Python macro.
#   \optional[value] SOURCES:dir The directory containing the project's
#     Python sources, defaults to python.
macro(remake_python)
  remake_arguments(PREFIX python_ VAR SOURCES ${ARGN})
  remake_set(python_sources SELF DEFAULT python)

  if(NOT DEFINED PYTHON_FOUND)
    remake_find_executable(python)

    if(PYTHON_FOUND)
      remake_set(python_command
        "from distutils.sysconfig import *"
        "print get_python_lib()")
      execute_process(
        COMMAND ${PYTHON_EXECUTABLE} -c "${python_command}"
        OUTPUT_VARIABLE python_destination
        OUTPUT_STRIP_TRAILING_WHITESPACE)

      if(python_destination)
        remake_project_set(PYTHON_MODULE_DESTINATION ${python_destination}
          CACHE PATH "Install destination of Python modules.")
      endif(python_destination)
    endif(PYTHON_FOUND)
  endif(NOT DEFINED PYTHON_FOUND)

  if(PYTHON_FOUND)
    get_filename_component(REMAKE_PYTHON_SOURCE_DIR ${python_sources}
      ABSOLUTE)
    if(EXISTS ${REMAKE_PYTHON_SOURCE_DIR})
      remake_add_directories(${REMAKE_PYTHON_SOURCE_DIR})
    endif(EXISTS ${REMAKE_PYTHON_SOURCE_DIR})

    remake_file(python_package_glob ${REMAKE_PYTHON_PACKAGE_DIR}/* TOPLEVEL)
    remake_file_glob(python_package_dirs DIRECTORIES ${python_package_glob})
    remake_set(python_packages)
    remake_set(python_package_paths)
    foreach(python_package_dir ${python_package_dirs})
      get_filename_component(python_package ${python_package_dir} NAME)
      remake_list_push(python_packages ${python_package})
    endforeach(python_package_dir)

    if(python_packages)
      list(SORT python_packages)
      string(REPLACE ";" ", " python_package_names "${python_packages}")
      message(STATUS "Python package(s): ${python_package_names}")
    else(python_packages)
      message(STATUS "Python package(s): none defined")
    endif(python_packages)
  endif(PYTHON_FOUND)
endmacro(remake_python)

### \brief Output a valid Python package name from a ReMake component name.
#   This macro is a helper macro to generates valid Python package names
#   from a ReMake component name. It automatically prepends
#   ${REMAKE_PROJECT_FILENAME} to the component name, replaces scores by
#   periods and then performs a lower-case conversion of the result. Also,
#   ${REMAKE_PYTHON_COMPONENT_SUFFIX} is automatically stripped
#   from the end of the name.
#   \required[value] variable The name of a variable to be assigned the
#     generated package name.
#   \required[value] component The ReMake component name that shall be
#     converted to a Python package name.
macro(remake_python_package_name python_var python_component)
  string(REGEX REPLACE "[-]" "." python_prepended
    "${REMAKE_PROJECT_FILENAME}.${python_component}")
  string(REGEX REPLACE ".${REMAKE_PYTHON_COMPONENT_SUFFIX}$" ""
    python_stripped "${python_prepended}")
  string(TOLOWER "${python_stripped}" ${python_var})
endmacro(remake_python_package_name)

### \brief Define a Python package for distribution.
#   This macro defines a Python package and selects it for distribution.
#   It takes a Python-compliant package name and a list of module sources that
#   will be built into the package. Before a package is defined, additional
#   sources may be assigned to it by calling remake_python_add_sources().
#   Analogously, several extensions can be specified through calls to
#   remake_python_add_extension(). Multiple definitions of a package are not
#   allowed and result in a fatal error.
#   \optional[list] glob An optional list of glob expressions that will
#     be resolved in order to find the module sources of the package,
#     defaults to *.py.
#   \optional[value] NAME:name The optional name of the Python package
#     to be distributed, defaults to the package name conversion of
#     ${REMAKE_COMPONENT}.
#   \optional[value] DESCRIPTION:string An optional description of the
#     package content that is appended to the project summary when
#     generating the package description.
#   \optional[option] RECURSE If this option is given, module sources will
#     be searched recursively in and below ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_python_generate() and
#     remake_python_install() for defining the build and install rules,
#     respectively.
macro(remake_python_package)
  remake_arguments(PREFIX python_ VAR NAME VAR DESCRIPTION OPTION RECURSE
    VAR COMPONENT ARGN globs ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})
  remake_python_package_name(python_default_name ${python_component})
  remake_set(python_name SELF DEFAULT ${python_default_name})
  remake_set(python_globs SELF DEFAULT *.py)

  remake_file(python_package_dir
    ${REMAKE_PYTHON_PACKAGE_DIR}/${python_name} TOPLEVEL)
  if(NOT EXISTS ${python_package_dir})
    remake_file_mkdir(${python_package_dir})
    if(python_recurse)
      remake_file_glob(python_sources ${python_globs}
        RECURSE ${CMAKE_CURRENT_SOURCE_DIR})
    else(python_recurse)
      remake_file_glob(python_sources ${python_globs})
    endif(python_recurse)
    remake_python_get_sources(python_package_sources ${python_name})
    remake_list_push(python_source ${python_package_sources})

    string(REPLACE "." "/" python_output_dir ${python_name})
    remake_list_string(python_sources python_output_relative
      REGEX REPLACE "^${CMAKE_CURRENT_SOURCE_DIR}" "${python_output_dir}")
    remake_list_string(python_output_relative python_modules_relative
      REGEX REPLACE ".py$" "")
    remake_list_string(python_modules_relative python_modules REPLACE "/" ".")

    string(REGEX REPLACE "[.]$" "" python_summary ${REMAKE_PROJECT_SUMMARY})
    if(python_description)
      remake_set(python_summary "${python_summary} (${python_description})")
    endif(python_description)
    string(REPLACE ";" "', '" python_module_array "'${python_modules}'")

    remake_file(python_setup ${python_package_dir}/setup.py)
    remake_file_create(${python_setup})
    remake_file_write(${python_setup}
      "from distutils.core import setup, Extension")
    remake_file_write(${python_setup}
      "\nsetup(
        name='${python_name}',
        version='${REMAKE_PROJECT_VERSION}',
        description='${python_summary}',
        author='${REMAKE_PROJECT_AUTHORS}',
        author_email='${REMAKE_PROJECT_CONTACT}',
        url='${REMAKE_PROJECT_HOME}',
        license='${REMAKE_PROJECT_LICENSE}',
        package_dir={'${python_name}': '${CMAKE_CURRENT_SOURCE_DIR}'},
        py_modules=[${python_module_array}]
      )\n")
    remake_file(python_dist_dir ${REMAKE_PYTHON_DIST_DIR}/${python_name}
      TOPLEVEL)

    remake_set(python_egg_file_name
      "${python_name}-${REMAKE_PROJECT_VERSION}.egg-info")
    remake_set(python_egg_file "${python_dist_dir}/${python_egg_file_name}")
    remake_list_string(python_output_relative python_output REGEX REPLACE
      "^${python_output_dir}" "${python_dist_dir}/${python_output_dir}")
    remake_list_string(python_output python_output_compiled
      REGEX REPLACE ".py$" ".pyc")

    remake_python_generate(${python_name}
      COMMAND ${PYTHON_EXECUTABLE} ${python_setup} --quiet install
        --install-lib=${python_dist_dir}
      WORKING_DIRECTORY ${python_package_dir}
      DEPENDS ${python_sources}
      COMMENT "Generating Python package ${python_name}"
      OUTPUT ${python_egg_file} ${python_output} ${python_output_compiled}
      ${COMPONENT})

    remake_project_get(PYTHON_MODULE_DESTINATION)
    string(REGEX REPLACE "/?[^/]+$" "" python_install_dir ${python_output_dir})
    remake_python_install(
      DIRECTORY ${python_dist_dir}/${python_output_dir}
      DESTINATION ${PYTHON_MODULE_DESTINATION}/${python_install_dir}
      ${COMPONENT})
    
    string(REGEX REPLACE "(.*)[.]([^.]+)$" "\\2" python_egg_install
      ${python_name})
    remake_python_install(
      FILES ${python_egg_file}
      DESTINATION ${PYTHON_MODULE_DESTINATION}/${python_install_dir}
      RENAME "${python_egg_install}-${REMAKE_PROJECT_VERSION}.egg-info"
      ${COMPONENT})
  else(NOT EXISTS ${python_package_dir})
    message(FATAL_ERROR "Python package ${python_name} multiply defined")
  endif(NOT EXISTS ${python_package_dir})
endmacro(remake_python_package)

### \brief Define the value of a Python package variable.
#   This macro defines a Python package variable matching the ReMake naming
#   conventions. The variable name is automatically prefixed with an
#   upper-case conversion of the package name. Thus, variables may appear as
#   {PACKAGE_NAME}_${VAR_NAME}. Additional arguments are passed on to
#   remake_set().
#   \required[value] package The name of the Python package for which the
#     variable shall be defined.
#   \required[value] variable The name of the Python package variable to be
#     defined.
#   \optional[list] arg The arguments to be passed on to remake_set(). See
#     ReMakePrivate for details.
#   \optional[option] APPEND With this option being present, the arguments
#     will be appended to an already existing definition of the Python
#     package variable.
macro(remake_python_package_set python_package python_var)
  remake_arguments(PREFIX python_ OPTION APPEND ARGN args ${ARGN})

  remake_var_name(python_global_var ${python_package} ${python_var})
  if(python_append)
    remake_list_push(${python_global_var} ${python_args})
  else(python_append)
    remake_set(${python_global_var} ${python_args})
  endif(python_append)
endmacro(remake_python_package_set)

### \brief Retrieve the value of a Python package variable.
#   This macro retrieves a Python package variable matching the ReMake
#   naming conventions. Specifically, variables named
#   ${PACKAGE_NAME}_${VAR_NAME} can be found by passing ${VAR_NAME} to
#   this macro. By default, the macro defines an output variable named
#   ${VAR_NAME} which will be assigned the value of the queried Package
#   variable.
#   \required[value] variable The name of the Python package variable to
#     be retrieved.
#   \required[value] package The name of the Python package to retrieve the
#     variable for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried Python package variable.
macro(remake_python_package_get python_var python_package)
  remake_arguments(PREFIX python_ VAR OUTPUT ${ARGN})

  remake_var_name(python_global_var ${python_package} ${python_var})
  remake_set(python_global ${${python_global_var}})

  if(python_output)
    remake_set(${python_output} ${python_global})
  else(python_output)
    remake_set(${python_var} ${python_global})
  endif(python_output)
endmacro(remake_python_package_get)

### \brief Add sources to a Python package.
#   This macro does not actually add sources to an already defined Python
#   package, but appends a list of source files to a Python package variable
#   named ${PACKAGE_NAME}_SOURCES. Note that the list of sources needs to be
#   defined before the actual Python package and can later be recovered by
#   calling remake_python_get_sources(). Also, be aware of the scope of the
#   ${PACKAGE_NAME}_SOURCES variable.
#   \required[value] package The name of the Python package to add the
#     sources to.
#   \required[list] source A list of source filenames to be appended to
#     the Python package's sources.
macro(remake_python_add_sources python_package)
  remake_python_package_set(${python_package} SOURCES ${ARGN} APPEND)
endmacro(remake_python_add_sources)

### \brief Retrieve sources for a Python package.
#   This macro retrieves a list of source files from a Python package
#   variable named ${PACKAGE_NAME}_SOURCES, usually defined by
#   remake_python_add_sources().
#   \required[value] variable The name of a variable to be assigned the list
#     of sources for the Python package.
#   \required[value] package The name of the Python package to retrieve the
#     sources for.
macro(remake_python_get_sources python_var python_package)
  remake_python_package_get(SOURCES ${python_package} output ${python_var})
endmacro(remake_python_get_sources)

### \brief Add Python extension.
#   This macro does not actually add an extension to an already defined
#   Python package, but appends an extension to a Python package variable named
#   ${PACKAGE_NAME}_EXTENSIONS. Note that the list of extensions needs to be
#   defined before the actual Python package and can later be recovered by
#   calling remake_python_get_extensions(). Also, be aware of the scope of the
#   ${PACKAGE_NAME}_EXTENSIONS variable.
#   \required[value] name The name of the Python extension to be added. Note
#     that some Python extensions follow special naming conventions.
#   \required[list] glob A list of glob expressions that will be resolved
#     in order to find and append the source files of the extension to
#     the Python package extension variable named
#     ${PACKAGE_NAME}_${EXTENSION_NAME}_SOURCES.
#   \optional[value] PACKAGE:package The name of the Python package to
#     which the extension will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}.
#   \optional[list] OPTIONS:option An optional list of options for the
#     extension that will be appended to the Python package extension
#     variable named ${PACKAGE_NAME}_${EXTENSION_NAME}_OPTIONS.
macro(remake_python_extension python_name)
  remake_arguments(PREFIX python_ VAR PACKAGE LIST OPTIONS ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})

  remake_file_glob(python_sources ${python_globs})
  remake_python_package_set(${python_package} EXTENSIONS ${python_name} APPEND)
  remake_python_extension_set(${python_package} ${python_name} SOURCES
    ${python_sources} APPEND)
  remake_python_extension_set(${python_package} ${python_name} OPTIONS
    ${python_options} APPEND)
endmacro(remake_python_extension)

### \brief Define the value of a Python package extension variable.
#   This macro defines a Python package extension variable matching the ReMake
#   conventions. The variable name is automatically prefixed with an
#   upper-case conversion of the package name and the extension name. Thus,
#   variables may appear as ${PACKAGE_NAME}_${EXTENSION_NAME}_${VAR_NAME}.
#   Additional arguments are passed on to remake_set().
#   \required[value] package The name of the Python package for which the
#     extension variable shall be defined.
#   \required[value] extension The name of the Python package extension for
#     which the variable shall be defined.
#   \required[value] variable The name of the Python package extension variable
#     to be defined.
#   \optional[list] arg The arguments to be passed on to remake_set(). See
#     ReMakePrivate for details.
#   \optional[option] APPEND With this option being present, the arguments
#     will be appended to an already existing definition of the Python
#     package extension variable.
macro(remake_python_extension_set python_package python_extension python_var)
  remake_var_name(python_package_var ${python_extension} ${python_var})
  remake_python_package_set(${python_package} ${python_package_var} ${ARGN})
endmacro(remake_python_extension_set)

### \brief Retrieve the value of a Python package extension variable.
#   This macro retrieves a Python package extension variable matching
#   the ReMake naming conventions. Specifically, variables named
#   ${PACKAGE_NAME}_${EXTENSION_NAME}_${VAR_NAME} can be found by passing
#   ${VAR_NAME} to this macro. By default, the macro defines an output
#   variable named ${VAR_NAME} which will be assigned the value of the
#   queried Package extension variable.
#   \required[value] variable The name of the Python package extension
#     variable to be retrieved.
#   \required[value] package The name of the Python package to retrieve the
#     extension variable for.
#   \required[value] extension The name of the Python package extension to
#     retrieve the variable for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried Python package extension
#     variable.
macro(remake_python_extension_get python_var python_package python_extension)
  remake_var_name(python_package_var ${python_extension} ${python_var})
  remake_python_package_get(${python_var} ${python_package}
    ${python_package_var} ${ARGN})
endmacro(remake_python_extension_get)

macro(remake_python_swig)
# check for swig
#   remake_python_extension(${ARGN} *.i)
endmacro(remake_python_swig)

### \brief Add Python package build rule.
#   This macro is a helper macro to define Python package build rules. Note
#   that the macro gets invoked by other macros defined in this module. In
#   most cases, it will therefore not be necessary to call it directly from a
#   CMakeLists.txt file.
#   \required[value] package The name of the Python package to be built.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_component_add_command(),
#     defaults to ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \optional[list] arg Additional arguments to be passed on to
#     remake_component_add_command(). See ReMakeComponent for details.
macro(remake_python_generate python_package)
  remake_arguments(PREFIX python_ VAR COMPONENT ARGN generate_args ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})

  remake_target_name(python_target
    ${python_package} ${REMAKE_PYTHON_TARGET_SUFFIX})
  remake_component_add_command(
    ${python_generate_args} AS ${python_target}
    COMPONENT ${python_component})
endmacro(remake_python_generate)

### \brief Add Python package install rule.
#   This macro is a helper macro to define Python package install rules. Note
#   that the macro gets invoked by other macros defined in this module. In
#   most cases, it will therefore not be necessary to call it directly from a
#   CMakeLists.txt file.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_component_install(),
#     defaults to ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \optional[list] arg Additional arguments to be passed on to
#     remake_component_install(). See ReMakeComponent for details.
macro(remake_python_install)
  remake_arguments(PREFIX python_ VAR COMPONENT ARGN install_args ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})

  remake_component_install(
    ${python_install_args}
    COMPONENT ${python_component})
endmacro(remake_python_install)

remake_file_rmdir(${REMAKE_PYTHON_PACKAGE_DIR} TOPLEVEL)
