############################################################################
#    Copyright (C) 2013 by Ralf Kaestner                                   #
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

if(NOT DEFINED REMAKE_PYTHON_CMAKE)
  remake_set(REMAKE_PYTHON_CMAKE ON)

  remake_set(REMAKE_PYTHON_DIR ReMakePython)
  remake_set(REMAKE_PYTHON_DISTRIBUTION_DIR ${REMAKE_PYTHON_DIR}/distributions)
  remake_set(REMAKE_PYTHON_PACKAGE_DIR ${REMAKE_PYTHON_DIR}/packages)
  remake_set(REMAKE_PYTHON_COMPONENT_SUFFIX python)
  remake_set(REMAKE_PYTHON_ALL_TARGET python_distributions)
  remake_set(REMAKE_PYTHON_TARGET_SUFFIX python_distribution)
  remake_set(REMAKE_PYTHON_EXT_PACKAGE extensions)

  remake_file_rmdir(${REMAKE_PYTHON_DISTRIBUTION_DIR} TOPLEVEL)
  remake_file_rmdir(${REMAKE_PYTHON_PACKAGE_DIR} TOPLEVEL)

  remake_project_unset(PYTHON_DISTRIBUTIONS CACHE)
  remake_project_unset(PYTHON_PACKAGES CACHE)
endif(NOT DEFINED REMAKE_PYTHON_CMAKE)

### \brief Configure Python package distribution.
#   This macro discovers the Python installation and configures Python
#   package distribution. It initializes a project variable named
#   PYTHON_MODULE_DESTINATION that holds the default install destination
#   of all packages and defaults to the local Python distribution root. Note
#   that the macro automatically gets invoked by the macros defined in this
#   module. It needs not be called directly from a CMakeLists.txt file.
macro(remake_python)
  if(NOT PYTHON_FOUND)
    remake_find_executable(python)

    if(PYTHON_FOUND)
      remake_set(python_command
        "from distutils.sysconfig import *"
        "print get_python_lib()")
      execute_process(
        COMMAND ${PYTHON_EXECUTABLE} -c "${python_command}"
        RESULT_VARIABLE python_result
        OUTPUT_VARIABLE python_destination
        ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

      if(NOT python_result)
        if(python_destination MATCHES "^${CMAKE_INSTALL_PREFIX}/.*$")
          string(REGEX REPLACE "^${CMAKE_INSTALL_PREFIX}/(.*)$" "\\1"
            python_destination ${python_destination})
        endif(python_destination MATCHES "^${CMAKE_INSTALL_PREFIX}/.*$")

        remake_project_set(PYTHON_MODULE_DESTINATION ${python_destination}
          CACHE PATH "Install destination of Python modules.")
      endif(NOT python_result)
    endif(PYTHON_FOUND)
  endif(NOT PYTHON_FOUND)

  if(PYTHON_FOUND)
    remake_file_mkdir(${REMAKE_PYTHON_DISTRIBUTION_DIR} TOPLEVEL)
    remake_file_mkdir(${REMAKE_PYTHON_PACKAGE_DIR} TOPLEVEL)
  endif(PYTHON_FOUND)
endmacro(remake_python)

### \brief Output a Python distribution name from a ReMake component name.
#   This macro is a helper macro to generates valid Python distribution names
#   from a ReMake component name. It prepends ${REMAKE_PROJECT_FILENAME} to
#   the component name and then performs a lower-case conversion of the
#   result. Also, ${REMAKE_PYTHON_COMPONENT_SUFFIX} is automatically stripped
#   from the end of the name.
#   \required[value] variable The name of a variable to be assigned the
#     generated distribution name.
#   \required[value] component The ReMake component name that shall be
#     converted to a Python distribution name.
macro(remake_python_distribution_name python_var python_component)
  string(REGEX REPLACE ".${REMAKE_PYTHON_COMPONENT_SUFFIX}$" ""
    python_stripped "${REMAKE_PROJECT_FILENAME}-${python_component}")
  string(TOLOWER "${python_stripped}" ${python_var})
endmacro(remake_python_distribution_name)

### \brief Distribute a collection of Python packages.
#   This macro creates a Python distribution from a collection of previously
#   defined Python packages. It takes a Python-compliant distribution name
#   and a list of Python packages that will be built into the distribution.
#   Note that multiple definitions of a distribution are not allowed and
#   result in a fatal error.
#   \optional[value] NAME:name The optional name of the Python distribution
#     defaults to the distribution name conversion of ${REMAKE_COMPONENT}.
#   \required[list] PACKAGES:pkg The optional list of Python packages
#     to be distributed, defaulting to the package name conversion of
#     ${REMAKE_COMPONENT}.
#   \optional[value] DESCRIPTION:string An optional description of the
#     distribution content that is appended to the project summary when
#     generating the distribution's description.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_python_build() and
#     remake_python_install() for defining the distributions build and
#     install rules, respectively. If no component name is provided, it
#     will default to ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
macro(remake_python_distribute)
  remake_arguments(PREFIX python_ VAR NAME LIST PACKAGES VAR DESCRIPTION
    VAR COMPONENT ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})
  remake_python_distribution_name(python_default_name ${python_component})
  remake_set(python_name SELF DEFAULT ${python_default_name})
  remake_python_package_name(python_default_pkg ${python_component})
  remake_set(python_packages SELF DEFAULT ${python_default_pkg})

  remake_python()

  remake_project_get(PYTHON_DISTRIBUTIONS OUTPUT python_distributions)
  list(FIND python_distributions ${python_name} python_index)
  if(NOT python_index LESS 0)
    message(FATAL_ERROR "Python distribution ${python_name} multiply defined!")
  endif(NOT python_index LESS 0)
  remake_project_set(
    PYTHON_DISTRIBUTIONS ${python_distributions} ${python_name}
    CACHE INTERNAL "Python distributions defined by the project.")

  remake_file(python_dist_conf_dir
    ${REMAKE_PYTHON_DISTRIBUTION_DIR}/${python_name} TOPLEVEL)
  remake_file_mkdir(${python_dist_conf_dir})

  string(REGEX REPLACE "[.]$" "" python_summary ${REMAKE_PROJECT_SUMMARY})
  if(python_description)
    remake_set(python_summary "${python_summary} (${python_description})")
  endif(python_description)

  remake_unset(python_directories python_modules python_extensions
    python_depends python_built python_clean)
  foreach(python_package ${python_packages})
    remake_python_package_get(${python_package} DIRECTORY OUTPUT
      python_pkg_dir)
    remake_list_push(python_directories
      "'${python_package}': '${python_pkg_dir}'")
    remake_python_package_get(${python_package} MODULES OUTPUT
      python_pkg_mods)

    foreach(python_pkg_mod ${python_pkg_mods})
      remake_list_push(python_modules "${python_package}.${python_pkg_mod}")
      string(REGEX REPLACE "[.]" "/" python_pkg_src ${python_pkg_mod})
      remake_list_push(python_depends
        "${python_pkg_dir}/${python_pkg_src}.py")
      string(REGEX REPLACE "[.]" "/" python_pkg_out
        "${python_package}.${python_pkg_mod}")
      remake_list_push(python_built "${python_pkg_out}.py"
        "${python_pkg_out}.pyc")
    endforeach(python_pkg_mod)
    if(NOT python_modules)
      message(STATUS
        "Warning: No modules in Python package ${python_package}!")
    endif(NOT python_modules)

    remake_python_package_get(${python_package} EXTENSIONS OUTPUT
      python_pkg_exts)
    foreach(python_extension ${python_pkg_exts})
      remake_python_extension_get(${python_package} ${python_extension}
        SOURCES OUTPUT python_ext_srcs)
      remake_python_extension_get(${python_package} ${python_extension}
        MODULES OUTPUT python_ext_mods)
      remake_python_extension_get(${python_package} ${python_extension}
        OPTIONS OUTPUT python_ext_opts)
      remake_python_extension_get(${python_package} ${python_extension}
        DEPENDS OUTPUT python_ext_deps)
      remake_python_extension_get(${python_package} ${python_extension}
        OUTPUTS OUTPUT python_ext_outs)
      remake_python_extension_get(${python_package} ${python_extension}
        CLEAN OUTPUT python_ext_clean)

      remake_list_push(python_depends ${python_ext_srcs} ${python_ext_deps})
      string(REPLACE ";" "', '" python_ext_sources "'${python_ext_srcs}'")
      remake_set(python_ext_const "'${python_package}._${python_extension}'"
        "['${python_ext_srcs}']")
      foreach(python_ext_opt ${python_ext_opts})
        remake_python_extension_get(${python_package} ${python_extension}
          ${python_ext_opt} OUTPUT python_ext_opt_pars)
        string(REPLACE ";" "', '" python_ext_option
          "'${python_ext_opt_pars}'")
        remake_list_push(python_ext_const
          "${python_ext_opt}=[${python_ext_option}]")
      endforeach(python_ext_opt)
      string(REPLACE ";" ", " python_ext_constructor "${python_ext_const}")
      remake_list_push(python_extensions
        "Extension(${python_ext_constructor})")

      foreach(python_ext_mod ${python_ext_mods})
        remake_list_push(python_modules "${python_package}.${python_ext_mod}")
        string(REGEX REPLACE "[.]" "/" python_ext_out
          "${python_package}.${python_ext_mod}")
        remake_list_push(python_built "${python_ext_out}.py"
          "${python_ext_out}.pyc")
      endforeach(python_ext_mod)
      foreach(python_ext_out ${python_ext_outs})
        if(IS_ABSOLUTE ${python_ext_out})
          remake_list_push(python_clean ${python_ext_out})
        else(IS_ABSOLUTE ${python_ext_out})
          string(REGEX REPLACE "[.]" "/" python_build_dir ${python_package})
          remake_list_push(python_built ${python_build_dir}/${python_ext_out})
        endif(IS_ABSOLUTE ${python_ext_out})
      endforeach(python_ext_out)
      remake_list_push(python_clean ${python_ext_clean})
    endforeach(python_extension)
  endforeach(python_package)

  string(REPLACE "-" "_" python_egg ${python_name})
  string(REGEX REPLACE "[^0-9.]" "_" python_version ${REMAKE_PROJECT_VERSION})
  remake_list_push(python_built "${python_egg}-${python_version}.egg-info")
  remake_list_push(python_clean "${python_dist_conf_dir}/build")

  string(REPLACE ";" ", " python_package_dir "${python_directories}")
  string(REPLACE ";" ", " python_ext_modules "${python_extensions}")
  string(REPLACE ";" "', '" python_py_modules "'${python_modules}'")

  remake_file(python_setup ${python_dist_conf_dir}/setup.py)
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
      package_dir={${python_package_dir}},
      ext_modules=[${python_ext_modules}],
      py_modules=[${python_py_modules}]
    )\n")

  remake_python_build(${python_name}
    COMMAND ${PYTHON_EXECUTABLE} ${python_setup} --quiet build_ext
    COMMAND ${PYTHON_EXECUTABLE} ${python_setup} --quiet install
      --install-lib=${CMAKE_CURRENT_BINARY_DIR}
    WORKING_DIRECTORY ${python_dist_conf_dir}
    DEPENDS ${python_depends}
    COMMENT "Building Python distribution ${python_name}"
    OUTPUT ${python_built} ${python_clean}
    ${COMPONENT})

  remake_component_get(${python_component} PYTHON_MODULE_DESTINATION
    OUTPUT python_module_destination)
  foreach(python_install ${python_built})
    get_filename_component(python_destination ${python_install} PATH)
    remake_python_install(
      FILES ${CMAKE_CURRENT_BINARY_DIR}/${python_install}
      DESTINATION ${python_module_destination}/${python_destination}
      ${COMPONENT})
  endforeach(python_install)

  message(STATUS "Python distribution: ${python_name}")
endmacro(remake_python_distribute)

### \brief Output a valid Python package name from a ReMake component name.
#   This macro is a helper macro to generates valid Python package names from
#   a ReMake component name. It prepends ${REMAKE_PROJECT_FILENAME} to the
#   component name, replaces scores by periods and then performs a lower-case
#   conversion of the result. Also, ${REMAKE_PYTHON_COMPONENT_SUFFIX} is
#   automatically stripped from the end of the name.
#   \required[value] variable The name of a variable to be assigned the
#     generated package name.
#   \required[value] component The ReMake component name that shall be
#     converted to a Python package name.
macro(remake_python_package_name python_var python_component)
  string(REGEX REPLACE "[-_]" "." python_prepended
    "${REMAKE_PROJECT_FILENAME}.${python_component}")
  string(REGEX REPLACE ".${REMAKE_PYTHON_COMPONENT_SUFFIX}$" ""
    python_stripped "${python_prepended}")
  string(TOLOWER "${python_stripped}" ${python_var})
endmacro(remake_python_package_name)

### \brief Define a Python package.
#   This macro defines a Python package that may later be selected for
#   distribution. It takes a Python-compliant package name and a list of
#   module sources that will be built into the package. Additional modules
#   may later be assigned to it by calling remake_python_add_modules().
#   Analogously, several extensions can be specified through calls to
#   remake_python_add_extension(). Note that multiple definitions of a
#   package are not allowed and result in a fatal error.
#   \optional[value] NAME:name The optional name of the Python package
#     to be defined, defaults to the package name conversion of
#     ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#   \optional[value] DIRECTORY:dir The optional root directory of the
#     defined package, defaulting to ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] glob An optional list of glob expressions that will
#     be resolved in order to find the module sources of the package,
#     defaults to *.py.
#   \optional[option] RECURSE If this option is given, module sources will
#     be searched recursively in and below ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[option] GENERATED With this option being present, the macro
#     assumes that the module sources do not yet exists but will be generated
#     during the run of CMake or the build process.
macro(remake_python_package)
  remake_arguments(PREFIX python_ VAR NAME VAR DIRECTORY OPTION GENERATED
    OPTION RECURSE ARGN globs ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_name ${python_default_component})
  remake_set(python_name SELF DEFAULT ${python_default_name})
  remake_set(python_directory SELF DEFAULT ${CMAKE_CURRENT_SOURCE_DIR})
  if(NOT python_generated)
    remake_set(python_globs SELF DEFAULT *.py)
  endif(NOT python_generated)

  remake_python()

  remake_project_get(PYTHON_PACKAGES OUTPUT python_packages)
  list(FIND python_packages ${python_name} python_index)
  if(NOT python_index LESS 0)
    message(FATAL_ERROR "Python package ${python_name} multiply defined!")
  endif(NOT python_index LESS 0)
  remake_project_set(PYTHON_PACKAGES ${python_packages} ${python_name}
    CACHE INTERNAL "Python packages defined by the project.")

  remake_file(python_pkg_conf_dir ${REMAKE_PYTHON_PACKAGE_DIR}/${python_name}
    TOPLEVEL)
  remake_file_mkdir(${python_pkg_conf_dir})
  remake_python_package_unset(${python_name} MODULES CACHE)
  remake_python_package_unset(${python_name} EXTENSIONS CACHE)
  remake_python_package_set(${python_name} DIRECTORY ${python_directory}
    CACHE INTERNAL "Build directory of Python package ${python_name}.")

  remake_python_add_modules(PACKAGE ${python_name} ${python_globs}
    ${GENERATED} ${RECURSE})
endmacro(remake_python_package)

### \brief Define the value of a Python package variable.
#   This macro defines a Python package variable matching the ReMake
#   naming conventions. The variable name is automatically prefixed with
#   an upper-case conversion of the package name. Thus, variables may
#   appear in the cache as project variables named after
#   ${PACKAGE_NAME}_PYTHON_PACKAGE_${VAR_NAME}. Additional arguments are
#   passed on to remake_project_set(). Note that the Python package needs
#   to be defined.
#   \required[value] name The name of the Python package for which the
#     variable shall be defined.
#   \required[value] variable The name of the package variable to be
#     defined.
#   \optional[list] arg The arguments to be passed on to remake_project_set().
#      See ReMakeProject for details.
macro(remake_python_package_set python_name python_var)
  remake_project_get(PYTHON_PACKAGES OUTPUT python_pkg_packages)
  list(FIND python_pkg_packages ${python_name} python_pkg_index)

  if(python_pkg_index GREATER -1)
    remake_var_name(python_pkg_package_var ${python_name} PYTHON_PACKAGE
      ${python_var})
    remake_project_set(${python_pkg_package_var} ${ARGN})
  else(python_pkg_index GREATER -1)
    message(FATAL_ERROR "Python package ${python_name} undefined!")
  endif(python_pkg_index GREATER -1)
endmacro(remake_python_package_set)

### \brief Undefine the value of a Python package variable.
#   This macro undefines a Python package variable which has been defined by
#   remake_python_package_set. The variable name is automatically prefixed with
#   an upper-case conversion of the package name. Additional arguments are
#   passed on to remake_project_unset().
#   \required[value] name The name of the Python package for which the
#     variable shall be undefined.
#   \required[value] variable The name of the Python package variable to be
#     undefined.
#   \optional[list] arg The arguments to be passed on to
#     remake_project_unset(). See ReMakeProject for details.
macro(remake_python_package_unset python_name python_var)
  remake_var_name(python_pkg_package_var ${python_name} PYTHON_PACKAGE
    ${python_var})
  remake_project_unset(${python_pkg_package_var} ${ARGN})
endmacro(remake_python_package_unset)

### \brief Retrieve the value of a Python package variable.
#   This macro retrieves a Python package variable matching the ReMake
#   naming conventions. Specifically, project variables named after
#   ${PACKAGE_NAME}_PYTHON_PACKAGE_${VAR_NAME} can be found by passing
#   ${VAR_NAME} to this macro. Note that the Python package needs
#   to be defined.
#   \required[value] name The name of the Python package to retrieve the
#     variable value for.
#   \required[value] variable The name of the package variable to retrieve
#     the value for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried package variable.
macro(remake_python_package_get python_name python_var)
  remake_arguments(PREFIX python_pkg_ VAR OUTPUT ${ARGN})

  remake_project_get(PYTHON_PACKAGES OUTPUT python_pkg_packages)
  list(FIND python_pkg_packages ${python_name} python_pkg_index)

  if(python_pkg_index GREATER -1)
    remake_var_name(python_pkg_package_var ${python_name} PYTHON_PACKAGE
      ${python_var})
    remake_set(python_pkg_output SELF DEFAULT ${python_var})

    remake_project_get(${python_pkg_package_var} OUTPUT ${python_pkg_output})
  else(python_pkg_index GREATER -1)
    message(FATAL_ERROR "Python package ${python_name} undefined!")
  endif(python_pkg_index GREATER -1)
endmacro(remake_python_package_get)

### \brief Add modules to a Python package.
#   This macro adds a collection of modules to an already defined Python
#   package. Note that all modules belonging to a Python package are required
#   to be located in and below the package directory. An incompliant module
#   location will thus result in a fatal error.
#   \optional[value] PACKAGE:package The name of the defined Python package
#     to add the modules to, defaulting to the package name conversion of
#     ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#   \optional[list] glob A list of glob expressions resolving to the module
#     sources that will be built into the specified Python package, defaults
#     to *.py. If the modules have to be generated, the expressions cannot
#     be resolved in place and shall therefore refer to the actual names of
#     the created source files.
#   \optional[option] RECURSE If this option is given, module sources will
#     be searched recursively in and below ${CMAKE_CURRENT_SOURCE_DIR}.
#     Note that for generated modules, the option will be ignored.
#   \optional[option] GENERATED With this option being present, the macro
#     assumes that the module sources do not yet exists but will be generated
#     during the run of CMake or the build process.
macro(remake_python_add_modules)
  remake_arguments(PREFIX python_ VAR PACKAGE OPTION GENERATED OPTION RECURSE
    ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})
  if(NOT python_generated)
    remake_set(python_globs SELF DEFAULT *.py)
  endif(NOT python_generated)

  remake_python()

  remake_python_package_get(${python_package} DIRECTORY OUTPUT python_pkg_dir)
  if(python_generated)
    remake_set(python_mod_sources ${python_globs})
  else(python_generated)
    if(python_recurse)
      remake_file_glob(python_mod_sources ${python_globs}
        WORKING_DIRECTORY ${python_pkg_dir}
        RECURSE ${CMAKE_CURRENT_SOURCE_DIR})
    else(python_recurse)
      remake_file_glob(python_mod_sources ${python_globs}
        WORKING_DIRECTORY ${python_pkg_dir})
    endif(python_recurse)
  endif(python_generated)

  remake_unset(python_modules)
  foreach(python_mod_src ${python_mod_sources})
    string(REPLACE "+" "\\+" python_pkg_dir_escaped ${python_pkg_dir})
    if(python_mod_src MATCHES "^${python_pkg_dir_escaped}/.*")
      string(REGEX REPLACE "^${python_pkg_dir_escaped}/" "" python_module
        ${python_mod_src})
      string(REGEX REPLACE ".py$" "" python_module ${python_module})
      string(REPLACE "/" "." python_module ${python_module})
      remake_list_push(python_modules ${python_module})
    else(python_mod_src MATCHES "^${python_pkg_dir_escaped}/.*")
      message(FATAL_ERROR
        "Python modules must be located below the package path!")
    endif(python_mod_src MATCHES "^${python_pkg_dir_escaped}/.*")
  endforeach(python_mod_src)
  remake_python_package_set(${python_package} MODULES ${python_modules}
    APPEND CACHE INTERNAL "Modules of Python package ${python_package}.")
endmacro(remake_python_add_modules)

### \brief Add an extension to a Python package.
#   This macro adds an extension to an already defined Python package.
#   Note that multiple definitions of an extension are not allowed and
#   result in a fatal error.
#   \required[value] name The name of the Python extension to be added. Note
#     that some Python extensions follow special naming conventions.
#   \required[list] glob A list of glob expressions resolving to the
#     source files of the Python package extension.
#   \optional[value] PACKAGE:package The name of the Python package to
#     which the extension will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#   \optional[list] MODULES:module An optional list of modules that will
#     be created for this Python package extension, defaulting to the
#     name of the extension.
#   \optional[list] OPTIONS:option An optional list of build options for
#     the defined Python extension.
#   \optional[list] DEPENDS:depend An optional list of file or target
#     dependencies for the Python extension.
#   \optional[list] OUTPUT:filename An optional list naming all non-module
#     output files that will be generated when building the Python extension
#     and should be included in the package. Note that for relative-path
#     filenames, the corresponding files will be assumed to reside in the
#     package distribution path located under ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[list] CLEAN:filename An optional list naming all non-module
#     output files that will be generated when building the Python extension
#     and should not be included in the package.
macro(remake_python_add_extension python_name)
  remake_arguments(PREFIX python_ VAR PACKAGE LIST MODULES LIST OPTIONS
    LIST DEPENDS LIST OUTPUT LIST CLEAN ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})
  remake_set(python_modules SELF DEFAULT ${python_name})

  remake_python()

  remake_python_package_get(${python_package} EXTENSIONS OUTPUT
    python_extensions)
  list(FIND python_extensions ${python_name} python_index)
  if(NOT python_index LESS 0)
    remake_set(python_message
      "Python extension ${python_name} multiply defined")
    message(FATAL_ERROR "${python_message} in package ${python_package}!")
  endif(NOT python_index LESS 0)
  remake_python_package_set(${python_package}
    EXTENSIONS ${python_extensions} ${python_name}
    CACHE INTERNAL "Python extensions defined by package ${python_package}.")

  remake_set(python_description
    "Python extension ${python_name} in package ${python_package}")
  remake_file_glob(python_ext_sources ${python_globs})
  remake_python_extension_set(
    ${python_package} ${python_name} SOURCES ${python_ext_sources}
    CACHE INTERNAL "Sources files of ${python_description}.")
  remake_python_extension_set(
    ${python_package} ${python_name} MODULES ${python_modules}
    CACHE INTERNAL "Modules generated by ${python_description}.")
  remake_python_extension_set(
    ${python_package} ${python_name} OPTIONS ${python_options}
    CACHE INTERNAL "Options of ${python_description}.")
  remake_python_extension_set(
    ${python_package} ${python_name} DEPENDS ${python_depends}
    CACHE INTERNAL "Dependencies of ${python_description}.")
  remake_python_extension_set(
    ${python_package} ${python_name} OUTPUTS ${python_output}
    CACHE INTERNAL "Output files of ${python_description}.")
  remake_python_extension_set(
    ${python_package} ${python_name} CLEAN ${python_clean}
    CACHE INTERNAL "Cleanup files of ${python_description}.")
endmacro(remake_python_add_extension)

### \brief Define the value of a Python extension variable.
#   This macro defines a Python extension variable matching the ReMake naming
#   conventions. The variable name is automatically prefixed with an upper-case
#   conversion of the extension name and passed to remake_python_package_set().
#   Thus, variables may appear in the cache as Python package variables named
#   after ${NAME}_EXTENSION_${VAR_NAME}. Additional arguments are passed
#   on to remake_project_set(). Note that both the Python extension and the
#   Python package need to be defined.
#   \required[value] package The name of the Python package for which the
#     Python extension is defined.
#   \required[value] name The name of the Python extension for which the
#     variable shall be defined.
#   \required[value] variable The name of the extension variable to be
#     defined.
#   \optional[list] arg The arguments to be passed on to remake_project_set().
#      See ReMakeProject for details.
macro(remake_python_extension_set python_package python_name python_var)
  remake_python_package_get(${python_package} EXTENSIONS OUTPUT
    python_ext_extensions)
  list(FIND python_ext_extensions ${python_name} python_ext_index)

  if(python_ext_index GREATER -1)
    remake_var_name(python_ext_extension_var ${python_name} EXTENSION
      ${python_var})
    remake_python_package_set(${python_package} ${python_ext_extension_var}
      ${ARGN})
  else(python_ext_index GREATER -1)
    remake_set(python_ext_message "Python extension ${python_name} undefined")
    message(FATAL_ERROR "${python_ext_message} in package ${python_package}!")
  endif(python_ext_index GREATER -1)
endmacro(remake_python_extension_set)

### \brief Retrieve the value of a Python extension variable.
#   This macro retrieves a Python extension variable matching the ReMake
#   naming conventions. Specifically, Python package variables named after
#   ${NAME}_EXTENSION_${VAR_NAME} can be found by passing ${VAR_NAME} to
#   this macro. Note that both the Python extension and the Python package
#   need to be defined.
#   \required[value] package The name of the Python package for which the
#     Python extension is defined.
#   \required[value] name The name of the Python extension to retrieve
#     the variable value for.
#   \required[value] variable The name of the extension variable to retrieve
#     the value for.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried extension variable.
macro(remake_python_extension_get python_package python_name python_var)
  remake_arguments(PREFIX python_ext_ VAR OUTPUT ${ARGN})

  remake_python_package_get(${python_package} EXTENSIONS OUTPUT
    python_ext_extensions)
  list(FIND python_ext_extensions ${python_name} python_ext_index)

  if(python_ext_index GREATER -1)
    remake_var_name(python_ext_extension_var ${python_name} EXTENSION
      ${python_var})
    remake_set(python_ext_output SELF DEFAULT ${python_var})

    remake_python_package_get(${python_package} ${python_ext_extension_var}
      OUTPUT ${python_ext_output})
  else(python_ext_index GREATER -1)
    remake_set(python_ext_message "Python extension ${python_name} undefined")
    message(FATAL_ERROR "${python_ext_message} in package ${python_package}!")
  endif(python_ext_index GREATER -1)
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
#     which the SWIG extension will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
macro(remake_python_swig)
  remake_arguments(PREFIX python_ VAR PACKAGE LIST LINK ARGN globs ${ARGN})
  remake_component_name(python_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_python_package_name(python_default_package ${python_component})
  remake_set(python_package SELF DEFAULT ${python_default_package})
  remake_set(python_globs SELF DEFAULT *.i)

  if(NOT SWIG_FOUND)
    remake_find_executable(swig)
  endif(NOT SWIG_FOUND)

  remake_set(python_swig_include_flags)
  get_property(python_include_dirs DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  foreach(python_include_dir ${python_include_dirs})
    remake_list_push(python_swig_include_flags "-I${python_include_dir}")
  endforeach(python_include_dir)

  remake_unset(python_libraries python_library_dirs python_depends)
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
    get_filename_component(python_extension ${python_src} NAME_WE)

    remake_python_add_extension(${python_extension} ${python_src}
      PACKAGE ${python_package}
      DEPENDS ${python_depends}
      OUTPUT _${python_extension}.so
      CLEAN ${CMAKE_CURRENT_SOURCE_DIR}/${python_extension}.py
        ${CMAKE_CURRENT_SOURCE_DIR}/${python_extension}_wrap.cpp
      OPTIONS swig_opts include_dirs library_dirs libraries)

    remake_set(python_description
      "Python SWIG extension ${python_extension}")
    remake_set(python_description
      "${python_description} in package ${python_package}")
    remake_python_extension_set(${python_package} ${python_extension}
      SWIG_OPTS -modern -c++ ${python_swig_include_flags}
      CACHE INTERNAL "SWIG options of ${python_description}.")
    remake_python_extension_set(${python_package} ${python_extension}
      INCLUDE_DIRS ${python_include_dirs}
      CACHE INTERNAL "Include directories of ${python_description}.")
    remake_python_extension_set(${python_package} ${python_extension}
      LIBRARY_DIRS ${python_library_dirs}
      CACHE INTERNAL "Library directories of ${python_description}.")
    remake_python_extension_set(${python_package} ${python_extension}
      LIBRARIES ${python_libraries}
      CACHE INTERNAL "Link libraries of ${python_description}.")
  endforeach(python_src)
endmacro(remake_python_swig)

### \brief Add Python distribution build rule.
#   This macro is a helper macro to define Python distribution build rules.
#   Note that the macro gets invoked by other macros defined in this module.
#   In most cases, it will therefore not be necessary to call it directly
#   from a CMakeLists.txt file.
#   \required[value] distribution The name of the Python distribution to be
#     built.
#   \optional[value] COMPONENT:component The optional name of the
#     install component that is passed to remake_component_add_command(),
#     defaults to ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \optional[list] arg Additional arguments to be passed on to
#     remake_component_add_command(). See ReMakeComponent for details.
macro(remake_python_build python_distribution)
  remake_arguments(PREFIX python_ VAR COMPONENT ARGN generate_args ${ARGN})
  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})

  if(NOT TARGET ${REMAKE_PYTHON_ALL_TARGET})
    remake_target(${REMAKE_PYTHON_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_PYTHON_ALL_TARGET})

  remake_target_name(python_target
    ${python_distribution} ${REMAKE_PYTHON_TARGET_SUFFIX})
  remake_component_add_command(
    ${python_generate_args} AS ${python_target}
    COMPONENT ${python_component})
  add_dependencies(${REMAKE_PYTHON_ALL_TARGET} ${python_target})
endmacro(remake_python_build)

### \brief Add Python distribution install rule.
#   This macro is a helper macro to define Python distribution install rules.
#   Note that the macro gets invoked by other macros defined in this module.
#   In most cases, it will therefore not be necessary to call it directly
#   from a CMakeLists.txt file.
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
