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
remake_set(REMAKE_PYTHON_BUILD_DIR ${REMAKE_PYTHON_DIR}/packages)
remake_set(REMAKE_PYTHON_EXT_DIR ${REMAKE_PYTHON_DIR}/extensions)
remake_set(REMAKE_PYTHON_DIST_DIR ${REMAKE_PYTHON_DIR}/distribution)
remake_set(REMAKE_PYTHON_COMPONENT_SUFFIX python)
remake_set(REMAKE_PYTHON_TARGET_SUFFIX python_distribution)
remake_set(REMAKE_PYTHON_EXT_PACKAGE extensions)

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

    remake_file(python_package_glob ${REMAKE_PYTHON_BUILD_DIR}/* TOPLEVEL)
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
#     install component that is passed to remake_python_build() and
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

  remake_python_add_modules(${REMAKE_PYTHON_ROOT_PACKAGE}
    ${python_globs}
    PACKAGE ${python_name}
    ${RECURSE})

  remake_file(python_build_dir ${REMAKE_PYTHON_BUILD_DIR} TOPLEVEL)
  remake_file(python_dist_dir ${REMAKE_PYTHON_DIST_DIR} TOPLEVEL)
  remake_file_mkdir(${python_build_dir}/${python_name})
  remake_file_mkdir(${python_dist_dir})

  # BEGIN REMOVE
  if(python_recurse)
    remake_file_glob(python_sources ${python_globs}
      RECURSE ${CMAKE_CURRENT_SOURCE_DIR})
  else(python_recurse)
    remake_file_glob(python_sources ${python_globs})
  endif(python_recurse)

  remake_set(python_directories
    "'${python_name}': '${CMAKE_CURRENT_SOURCE_DIR}'")
  string(REPLACE "." "/" python_output_dir ${python_name})
  remake_set(python_extensions_output_dir
    ${python_dist_dir}/${python_output_dir}/${REMAKE_PYTHON_EXT_PACKAGE})
  remake_list_string(python_sources python_output_relative
    REGEX REPLACE "^${CMAKE_CURRENT_SOURCE_DIR}" "${python_output_dir}")
  remake_list_string(python_output_relative python_modules_relative
    REGEX REPLACE ".py$" "")
  remake_list_string(python_modules_relative python_modules REPLACE "/" ".")
  # END REMOVE

  remake_python_package_get(${python_name} EXTENSIONS
    OUTPUT python_extensions)
  remake_set(python_extensions_depend)
  remake_set(python_extensions_output)
  if(python_extensions)
    remake_set(python_ext_package
      "${python_name}.${REMAKE_PYTHON_EXT_PACKAGE}")
    remake_file(python_ext_dir ${REMAKE_PYTHON_EXT_DIR}/${python_name}
      TOPLEVEL)
    remake_list_push(python_directories
      "'${python_ext_package}': '${python_ext_dir}'")
    remake_set(python_ext_constructors)

    remake_file_create(${python_ext_dir}/__init__.py)
    remake_list_push(python_extensions_output
      "${python_extensions_output_dir}/__init__.py")
    remake_list_push(python_extensions_output
      "${python_extensions_output_dir}/__init__.pyc")

    foreach(python_ext ${python_extensions})
      remake_python_extension_get(${python_name} ${python_ext} SOURCES
        OUTPUT python_ext_sources)
      remake_python_extension_get(${python_name} ${python_ext} MODULES
        OUTPUT python_ext_modules)
      remake_python_extension_get(${python_name} ${python_ext} OPTIONS
        OUTPUT python_ext_options)
      remake_python_extension_get(${python_name} ${python_ext} DEPENDS
        OUTPUT python_ext_depends)
      remake_python_extension_get(${python_name} ${python_ext} OUTPUTS
        OUTPUT python_ext_outputs)

      remake_list_push(python_sources ${python_ext_sources})
      string(REPLACE ";" "', '" python_ext_source_array
        "'${python_ext_sources}'")
      remake_set(python_ext_const
        "'${python_ext_package}._${python_ext}'"
        "[${python_ext_source_array}]")
      remake_list_push(python_extensions_depend ${python_ext_depends})

      foreach(python_ext_opt ${python_ext_options})
        remake_python_extension_get(${python_name} ${python_ext}
          ${python_ext_opt} OUTPUT python_ext_opt_params)
        string(REPLACE ";" "', '" python_ext_opt_param_array
          "'${python_ext_opt_params}'")
        remake_list_push(python_ext_const
          "${python_ext_opt}=[${python_ext_opt_param_array}]")
      endforeach(python_ext_opt)

      string(REPLACE ";" ", " python_ext_const_array "${python_ext_const}")
      remake_list_push(python_ext_constructors
        "Extension(${python_ext_const_array})")
      foreach(python_ext_module ${python_ext_modules})
        remake_list_push(python_modules
          "${python_ext_package}.${python_ext_module}")
      endforeach(python_ext_module)
      foreach(python_ext_ouput ${python_ext_outputs})
        remake_list_push(python_extensions_output
          "${python_extensions_output_dir}/${python_ext_ouput}")
      endforeach(python_ext_ouput)
    endforeach(python_ext)
  endif(python_extensions)

  # BEGIN NEW
  remake_python_package_get(${python_name} PACKAGES OUTPUT python_packages)
  remake_set(python_dirs)
  remake_set(python_mods)
  foreach(python_pkg ${python_packages})
    remake_python_package_get(${python_pkg} DIR OUTPUT python_pkg_dir)
    remake_python_package_get(${python_pkg} SOURCES OUTPUT python_pkg_sources)
    remake_debug(python_pkg python_pkg_dir python_pkg_sources)

    remake_list_push(python_dirs "'${python_pkg}': '${python_pkg_dir}'")
    string(REPLACE "." "/" python_output_dir ${python_pkg})
    remake_list_string(python_pkg_sources python_pkg_sources_relative
      REGEX REPLACE "^${python_pkg_dir}/" "")
    remake_list_string(python_pkg_sources_relative python_pkg_mods_relative
      REGEX REPLACE ".py$" "")
    remake_list_string(python_pkg_mods_relative python_pkg_mods
      REPLACE "/" ".")
    remake_list_push(python_mods ${python_pkg_mods})
  endforeach(python_pkg)
  # END NEW

  string(REGEX REPLACE "[.]$" "" python_summary ${REMAKE_PROJECT_SUMMARY})
  if(python_description)
    remake_set(python_summary "${python_summary} (${python_description})")
  endif(python_description)
  string(REPLACE ";" ", " python_dir_array "${python_dirs}")
  string(REPLACE ";" ", " python_ext_array "${python_ext_constructors}")
  string(REPLACE ";" "', '" python_mod_array "'${python_mods}'")

  remake_file(python_setup ${python_build_dir}/${python_name}/setup.py)
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
      package_dir={${python_dir_array}},
      ext_modules=[${python_ext_array}],
      py_modules=[${python_mod_array}]
    )\n")

  remake_set(python_egg_file_name
    "${python_name}-${REMAKE_PROJECT_VERSION}.egg-info")
  remake_set(python_egg_file "${python_dist_dir}/${python_egg_file_name}")
  remake_list_string(python_output_relative python_output REGEX REPLACE
    "^${python_output_dir}" "${python_dist_dir}/${python_output_dir}")
  remake_list_string(python_output python_output_compiled
    REGEX REPLACE ".py$" ".pyc")

  remake_python_build(${python_name}
    COMMAND ${PYTHON_EXECUTABLE} ${python_setup} --quiet build_ext
    COMMAND ${PYTHON_EXECUTABLE} ${python_setup} --quiet install
      --install-lib=${python_dist_dir}
    WORKING_DIRECTORY ${python_build_dir}/${python_name}
    DEPENDS ${python_sources} ${python_extensions_depend}
    COMMENT "Generating Python package ${python_name}"
    OUTPUT ${python_egg_file} ${python_output} ${python_output_compiled}
      ${python_extensions_output}
    ${COMPONENT})

  remake_project_get(PYTHON_MODULE_DESTINATION)
  foreach(python_file ${python_output} ${python_output_compiled}
    ${python_extensions_output})
    file(RELATIVE_PATH python_rename ${python_dist_dir} ${python_file})
    remake_python_install(
      FILES ${python_file}
      DESTINATION ${PYTHON_MODULE_DESTINATION}
      RENAME ${python_rename}
      ${COMPONENT})
  endforeach(python_file)

  string(REGEX REPLACE "/?[^/]+$" "" python_install_dir ${python_output_dir})
  string(REGEX REPLACE "(.*)[.]([^.]+)$" "\\2" python_egg_install
    ${python_name})
  remake_python_install(
    FILES ${python_egg_file}
    DESTINATION ${PYTHON_MODULE_DESTINATION}/${python_install_dir}
    RENAME "${python_egg_install}-${REMAKE_PROJECT_VERSION}.egg-info"
    ${COMPONENT})
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
#   \required[value] package The name of the Python package to retrieve the
#     variable for.
#   \required[value] variable The name of the Python package variable to
#     be retrieved.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried Python package variable.
macro(remake_python_package_get python_package python_var)
  remake_arguments(PREFIX python_ VAR OUTPUT ${ARGN})

  remake_var_name(python_global_var ${python_package} ${python_var})
  remake_set(python_global ${${python_global_var}})

  if(python_output)
    remake_set(${python_output} ${python_global})
  else(python_output)
    remake_set(${python_var} ${python_global})
  endif(python_output)
endmacro(remake_python_package_get)

### \brief Add modules to a Python package.
#   This macro does not actually add modules to an already defined Python
#   package, but appends a list of module source files to a Python package
#   variable named ${PACKAGE_NAME}_${SUBPACKAGE_NAME}_MODULES. In fact,
#   the list of modules passed to the macro will thus define a subpackage
#   of a Python package. Note that the list of modules needs to be defined
#   before the actual Python package. Furthermore, all modules belonging to
#   subpackage are required to be located in and below the same directory.
#   Be aware of the limited scope of Python package variables.
#   \required[value] subpackage The name of the Python package's subpackage
#     that will contain the modules. Note that following Python conventions,
#     modules are required to be grouped within directories. It is therefore
#     not possible to add modules to an already defined Python package.
#   \optional[list] glob A list of glob expressions resolving to the module
#     files that will be contained within the defined Python package's
#     subpackage, defaults to *.py. If the modules have to be generated, the
#     expressions cannot be resolved in place and shall therefore refer to
#     the actual names of the created files.
#   \optional[value] PACKAGE:package The name of the Python package to
#     add the sources to, defaults to the package name conversion of
#     ${REMAKE_COMPONENT}. Accordingly, the modules will then be situated
#     within the Python package ${PACKAGE_NAME}.${SUBPACKAGE_NAME}.
#   \optional[option] RECURSE If this option is given, module sources will
#     be searched recursively in and below ${CMAKE_CURRENT_SOURCE_DIR}.
#     Note that it therefore does not make sense to use this option on
#     generated modules.
#   \optional[option] GENERATED With this option being present, the macro
#     assumes that the module files do not yet exists but will be generated
#     during the run of CMake or the build process.
macro(remake_python_add_modules python_subpackage)
  remake_arguments(PREFIX python_ VAR PACKAGE OPTION GENERATED OPTION RECURSE
    ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})
  remake_set(python_globs SELF DEFAULT *.py)

  remake_python_package_set(${python_package} PACKAGES ${python_subpackage}
    APPEND)
  if(python_generated)
    remake_python_package_set(${python_package}.${python_subpackage} DIR
      ${CMAKE_CURRENT_BINARY_DIR})
    remake_python_package_set(${python_package}.${python_subpackage}
      MODULES ${python_globs})
  else(python_generated)
    remake_python_package_set(${python_package}.${python_subpackage} DIR
      ${CMAKE_CURRENT_SOURCE_DIR})
    if(python_recurse)
      remake_file_glob(python_modules ${python_globs}
        RECURSE ${CMAKE_CURRENT_SOURCE_DIR})
    else(python_recurse)
      remake_file_glob(python_modules ${python_globs})
    endif(python_recurse)
    remake_python_package_set(${python_package}.${python_subpackage}
      MODULES ${python_modules})
  endif(python_generated)
endmacro(remake_python_add_modules)

### \brief Add extension to a Python package.
#   This macro does not actually add an extension to an already defined
#   Python package, but appends an extension to a Python package variable named
#   ${PACKAGE_NAME}_EXTENSIONS. Note that the list of extensions needs to be
#   defined before the actual Python package and can later be recovered by
#   calling remake_python_get_extensions(). Also, be aware of the limited scope
#   of Python package variables.
#   \required[value] name The name of the Python extension to be added. Note
#     that some Python extensions follow special naming conventions.
#   \required[list] glob A list of glob expressions resolving to the
#     source files of the Python package extension. The filenames will be
#     appended to the Python package extension variable named
#     ${PACKAGE_NAME}_${EXTENSION_NAME}_SOURCES.
#   \optional[value] PACKAGE:package The name of the Python package to
#     which the extension will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}.
#   \optional[list] MODULES:module An optional list of modules that will
#     be created for this Python package extension, defaulting to the
#     name of the extension.
#   \optional[list] OPTIONS:option An optional list of options for the
#     extension that will be appended to the Python package extension
#     variable named ${PACKAGE_NAME}_${EXTENSION_NAME}_OPTIONS.
#   \optional[list] DEPENDS:depend An optional list of dependencies for
#     the extension that will be appended to the Python package extension
#     variable named ${PACKAGE_NAME}_${EXTENSION_NAME}_DEPENDS.
#   \optional[list] OUTPUT:filename An optional list of output filenames
#     for the extension that will be appended to the Python package
#     extension variable named ${PACKAGE_NAME}_${EXTENSION_NAME}_OUTPUTS.
macro(remake_python_add_extension python_name)
  remake_arguments(PREFIX python_ VAR PACKAGE LIST MODULES LIST OPTIONS
    LIST DEPENDS LIST OUTPUT ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})
  remake_set(python_modules SELF DEFAULT ${python_name})

  remake_file(python_ext_dir ${REMAKE_PYTHON_EXT_DIR}/${python_package}
    TOPLEVEL)
  remake_file_mkdir(${python_ext_dir})

  remake_file_link(${REMAKE_PYTHON_EXT_DIR}/${python_package}
    ${python_globs} OUTPUT python_sources TOPLEVEL)

  remake_python_package_set(${python_package} EXTENSIONS ${python_name} APPEND)
  remake_python_extension_set(${python_package} ${python_name} SOURCES
    ${python_sources} APPEND)
  remake_python_extension_set(${python_package} ${python_name} MODULES
    ${python_modules} APPEND)
  remake_python_extension_set(${python_package} ${python_name} OPTIONS
    ${python_options} APPEND)
  remake_python_extension_set(${python_package} ${python_name} DEPENDS
    ${python_depends} APPEND)
  remake_python_extension_set(${python_package} ${python_name} OUTPUTS
    ${python_output} APPEND)
endmacro(remake_python_add_extension)

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
#   \required[value] package The name of the Python package to retrieve the
#     extension variable for.
#   \required[value] extension The name of the Python package extension to
#     retrieve the variable for.
#   \required[value] variable The name of the Python package extension
#     variable to be retrieved.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried Python package extension
#     variable.
macro(remake_python_extension_get python_package python_extension python_var)
  remake_var_name(python_package_var ${python_extension} ${python_var})
  remake_python_package_get(${python_package} ${python_package_var}
    ${python_var} ${ARGN})
endmacro(remake_python_extension_get)

### \brief Add Python SWIG extension.
#   This macro defines Python extensions using the Simplified Wrapper and
#   Interface Generator (SWIG). It takes a list of SWIG interface definitions
#   and calls remake_python_add_extension() with all parameters necessary to
#   build the extension modules. Note that SWIG requires all header files
#   which have been included into the interfaces to be available in the
#   include search path. Therefore, remake_include() should be invoked prior
#   to calling this macro.
#   \required[list] glob A list of glob expressions resolving to the
#     SWIG interface files, defaulting to *.i. Note that the extensions will
#     be stripped from the filenames to define the names of the Python
#     extensions.
#   \required[list] LINK:lib The list of libraries to be linked into the
#     interface library target.
#   \optional[value] PACKAGE:package The name of the Python package to
#     which the extension will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}.
macro(remake_python_swig)
  remake_arguments(PREFIX python_ VAR PACKAGE LIST LINK ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})
  remake_set(python_globs SELF DEFAULT *.i)

  remake_find_executable(swig)

  remake_set(python_swig_include_flags)
  get_property(python_include_dirs DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  foreach(python_include_dir ${python_include_dirs})
    remake_list_push(python_swig_include_flags "-I${python_include_dir}")
  endforeach(python_include_dir)

  remake_set(python_library_dirs)
  remake_set(python_libraries)
  remake_set(python_depends)
  foreach(python_library ${python_link})
    get_property(python_lib_name TARGET ${python_library}
      PROPERTY OUTPUT_NAME)
    get_property(python_lib_location TARGET ${python_library}
      PROPERTY LOCATION)
    get_filename_component(python_lib_path ${python_lib_location} PATH)

    remake_list_push(python_library_dirs ${python_lib_path})
    remake_list_push(python_libraries ${python_lib_name})
  endforeach(python_library)

  remake_file_glob(python_swig_sources ${python_globs})
  foreach(python_src ${python_swig_sources})
    get_filename_component(python_src_name_we ${python_src} NAME_WE)

    remake_python_add_extension(${python_src_name_we} ${python_src}
      ${PACKAGE}
      DEPENDS ${python_depends}
      OUTPUT _${python_src_name_we}.so ${python_src_name_we}.py
        ${python_src_name_we}.pyc
      OPTIONS swig_opts include_dirs library_dirs libraries)

    remake_python_extension_set(${python_package} ${python_src_name_we}
      swig_opts -modern -c++ ${python_swig_include_flags})
    remake_python_extension_set(${python_package} ${python_src_name_we}
      include_dirs ${python_include_dirs})
    remake_python_extension_set(${python_package} ${python_src_name_we}
      library_dirs ${python_library_dirs})
    remake_python_extension_set(${python_package} ${python_src_name_we}
      libraries ${python_libraries})
  endforeach(python_src)
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
macro(remake_python_build python_package)
  remake_arguments(PREFIX python_ VAR COMPONENT ARGN generate_args ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})

  remake_target_name(python_target
    ${python_package} ${REMAKE_PYTHON_TARGET_SUFFIX})
  remake_component_add_command(
    ${python_generate_args} AS ${python_target}
    COMPONENT ${python_component})
endmacro(remake_python_build)

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
