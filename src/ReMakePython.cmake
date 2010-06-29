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

### \brief Configure Python module distribution.
#   This macro discovers the Python installation and configures Python
#   module distribution. It initializes a project variable named
#   ${PROJECT_PYTHON_MODULE_DESTINATION} that holds the default install
#   destination of all modules and defaults to the local Python
#   distribution root. The macro should be called in the project root's
#   CMakeLists.txt file, before any other Python macro.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install() for
#     installing the Python project info file (egg-info), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \optional[value] MODULES:dir The directory containing the project's
#     Python modules, defaults to python.
macro(remake_python)
  remake_arguments(PREFIX python_ VAR COMPONENT VAR MODULES ${ARGN})

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
    remake_set(REMAKE_PYTHON_TARGET python-modules)

    remake_project_get(PYTHON_MODULE_DESTINATION)
    remake_set(REMAKE_PYTHON_MODULE_DIR ${python_modules} DEFAULT python)
    if(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PYTHON_MODULE_DIR})
      remake_add_directories(${REMAKE_PYTHON_MODULE_DIR})
    endif(EXISTS ${CMAKE_SOURCE_DIR}/${REMAKE_PYTHON_MODULE_DIR})

    remake_file(python_package_glob ${REMAKE_PYTHON_PACKAGE_DIR}/* TOPLEVEL)
    remake_file_glob(python_package_dirs DIRECTORIES ${python_package_glob})
    remake_set(python_packages)
    remake_set(python_package_paths)
    foreach(python_package_dir ${python_package_dirs})
      get_filename_component(python_package ${python_package_dir} NAME)
      remake_list_push(python_packages ${python_package})
      remake_list_push(python_package_paths "'${python_package}':
        '${python_package_dir}'")
    endforeach(python_package_dir)

    if(python_packages)
      remake_component_name(python_default_component ${REMAKE_COMPONENT}
        ${REMAKE_PYTHON_COMPONENT_SUFFIX})
      remake_set(python_component SELF DEFAULT ${python_default_component})
      remake_component(${python_component})
      remake_component_build(${python_component} python_build)

      if(python_build)
        string(REPLACE ";" ", " python_package_names "${python_packages}")
        message(STATUS "Python package(s): ${python_package_names}")
        string(REGEX REPLACE "[.]$" "" python_summary ${REMAKE_PROJECT_SUMMARY})
        string(REPLACE ";" "', '" python_package_array "'${python_packages}'")
        string(REPLACE ";" ", " python_package_path_array
          "${python_package_paths}")

        remake_file_create(${REMAKE_PYTHON_SETUP_FILE} TOPLEVEL)
        remake_file_write(${REMAKE_PYTHON_SETUP_FILE} TOPLEVEL
          "from distutils.core import setup, Extension")
        remake_file_write(${REMAKE_PYTHON_SETUP_FILE}
          "\nsetup(
            name='${REMAKE_PROJECT_FILENAME}',
            version='${REMAKE_PROJECT_VERSION}',
            description='${python_summary}',
            author='${REMAKE_PROJECT_AUTHORS}',
            author_email='${REMAKE_PROJECT_CONTACT}',
            url='${REMAKE_PROJECT_HOME}',
            license='${REMAKE_PROJECT_LICENSE}',
            packages=[${python_package_array}],
            package_dir={${python_package_path_array}})")

        remake_file(python_dist_dir ${REMAKE_PYTHON_DIST_DIR} TOPLEVEL)
        remake_target(${REMAKE_PYTHON_TARGET} ALL)
        remake_target_add_command(${REMAKE_PYTHON_TARGET}
          COMMAND ${PYTHON_EXECUTABLE} ${REMAKE_PYTHON_SETUP_FILE} install
            --install-lib=${python_dist_dir})

        remake_project_get(PYTHON_MODULE_DESTINATION)
        remake_set(python_egg_info
          ${REMAKE_PROJECT_FILENAME}-${REMAKE_PROJECT_VERSION}.egg-info)
        remake_component_install(
          FILES ${python_dist_dir}/${python_egg_info}
          DESTINATION ${PYTHON_MODULE_DESTINATION}
          COMPONENT ${python_component})
      endif(python_build)
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

### \brief Distribute a Python package.
#   This macro defines a Python package and selects it for distribution.
#   It takes a Python-compliant package name and a list of modules that
#   will be added to the package. Once a package has been defined, additional
#   modules may be assigned to it by calling remake_python_modules(). Multiple
#   definitions of a package are not allowed and result in a fatal error.
#   \optional[value] NAME:name The optional name of the Python package
#     to be distributed, defaults to the package name conversion of
#     ${REMAKE_COMPONENT}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install() for
#     installing the package files, defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \optional[list] MODULES:glob An optional list of glob expressions
#     that is passed to remake_python_modules() and will be resolved in
#     order to find the module sources of the package, defaults to *.py.
macro(remake_python_package)
  remake_arguments(PREFIX python_ VAR NAME VAR COMPONENT LIST MODULES ${ARGN})
  remake_set(python_modules SELF DEFAULT *.py)

  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})
  remake_component(${python_component})
  remake_component_build(${python_component} python_build)

  if(python_build)
    remake_python_package_name(python_default_name ${python_component})
    remake_set(python_name SELF DEFAULT ${python_default_name})

    remake_file(python_package_dir ${REMAKE_PYTHON_PACKAGE_DIR}/${python_name}
      TOPLEVEL)
    if(NOT EXISTS ${python_package_dir})
      remake_file_mkdir(${python_package_dir})

      remake_python_modules(
        ${python_name}
        ${python_modules}
        COMPONENT ${python_component})
    else(NOT EXISTS ${python_package_dir})
      message(FATAL_ERROR "Python package ${python_name} multiply defined")
    endif(NOT EXISTS ${python_package_dir})
  endif(python_build)
endmacro(remake_python_package)

### \brief Distribute a list of Python modules.
#   This macro assigns a list of Python modules to a package which has already
#   been defined through a call to remake_python_package(). The attempt to
#   pass an undefined package will result in a fatal error.
#   \optional[value] PACKAGE:package The name of the defined Python package
#     to which the modules will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}.
#   \optional[option] ROOT If provided, this option tells the macro to assign
#     the modules to Python's root package. If a package name is specified in
#     addition, it will be ignored.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install() for
#     installing the extension module files, defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \optional[list] glob A list of glob expressions that is resolved in
#     order to find the module sources, defaults to *.py.
macro(remake_python_modules)
  remake_arguments(PREFIX python_ VAR PACKAGE OPTION ROOT VAR COMPONENT
    ARGN globs ${ARGN})
  remake_set(python_globs SELF DEFAULT *.py)

  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})
  remake_component(${python_component})
  remake_component_build(${python_component} python_build)

  if(python_build)
    if(python_root)
      remake_set(python_package)
    else(python_root)
      remake_python_package_name(python_default_package ${python_component})
      remake_set(python_package SELF DEFAULT ${python_default_package})
    endif(python_root)

    remake_file(python_package_dir
      ${REMAKE_PYTHON_PACKAGE_DIR}/${python_package} TOPLEVEL)
    if(EXISTS ${python_package_dir})
      remake_file_copy(${python_package_dir} ${python_globs})

      string(REGEX REPLACE "[.]" "/" python_destination_dir ${python_package})
      remake_project_get(PYTHON_MODULE_DESTINATION)
      remake_file(python_dist_dir ${REMAKE_PYTHON_DIST_DIR} TOPLEVEL)
      remake_file_glob(python_sources FILES ${python_globs})
      foreach(python_src ${python_sources})
        get_filename_component(python_src_name ${python_src} NAME)
        remake_list_push(python_files
          ${python_dist_dir}/${python_destination_dir}/${python_src_name})
      endforeach(python_src)
      remake_list_string(python_files python_compiled_files
        REGEX REPLACE "[.]py$" ".pyc")

      remake_component_install(
        FILES ${python_files} ${python_compiled_files}
        DESTINATION ${PYTHON_MODULE_DESTINATION}/${python_destination_dir}
        COMPONENT ${python_component})
    else(EXISTS ${python_package_dir})
      message(FATAL_ERROR "Python package ${python_package} not defined")
    endif(EXISTS ${python_package_dir})
  endif(python_build)
endmacro(remake_python_modules)

### \brief Distribute a list of Python extension modules.
#   This macro assigns a list of Python extension modules to a package which
#   has already been defined through a call to remake_python_package(). The
#   attempt to pass an undefined package will result in a fatal error.
#   \optional[value] PACKAGE:package The name of the defined Python package
#     to which the modules will be assigned, defaults to the package name
#     conversion of ${REMAKE_COMPONENT}.
#   \optional[option] ROOT If provided, this option tells the macro to assign
#     the modules to Python's root package. If a package name is specified in
#     addition, it will be ignored.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_install() for
#     installing the module files, defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_PYTHON_COMPONENT_SUFFIX}.
#     See ReMakeComponent for details.
#   \required[list] glob A list of glob expressions that is resolved in
#     order to find the extension module sources.
macro(remake_python_extensions)
  remake_arguments(PREFIX python_ VAR PACKAGE OPTION ROOT VAR COMPONENT
    ARGN globs ${ARGN})

  remake_component_name(python_default_component ${REMAKE_COMPONENT}
    ${REMAKE_PYTHON_COMPONENT_SUFFIX})
  remake_set(python_component SELF DEFAULT ${python_default_component})
  remake_component(${python_component})
  remake_component_build(${python_component} python_build)

  if(python_build)
    if(python_root)
      remake_set(python_package)
    else(python_root)
      remake_python_package_name(python_default_package ${python_component})
      remake_set(python_package SELF DEFAULT ${python_default_package})
    endif(python_root)

    remake_file(python_package_dir
      ${REMAKE_PYTHON_PACKAGE_DIR}/${python_package} TOPLEVEL)
    if(EXISTS ${python_package_dir})
      remake_file_copy(${python_package_dir} ${python_globs})

#       string(REGEX REPLACE "[.]" "/" python_destination_dir ${python_name})
#       remake_project_get(PYTHON_MODULE_DESTINATION)
#       remake_file(python_dist_dir ${REMAKE_PYTHON_DIST_DIR} TOPLEVEL)
#       remake_file_glob(python_sources FILES ${python_globs})
#       foreach(python_src ${python_sources})
#         get_filename_component(python_src_name ${python_src} NAME)
#         remake_list_push(python_files
#           ${python_dist_dir}/${python_destination_dir}/${python_src_name})
#       endforeach(python_src)
#       remake_list_string(python_files python_compiled_files
#         REGEX REPLACE "[.]py$" ".pyc")
# 
#       remake_component_install(
#         FILES ${python_files} ${python_compiled_files}
#         DESTINATION ${PYTHON_MODULE_DESTINATION}/${python_destination_dir}
#         COMPONENT ${python_component})
    else(EXISTS ${python_package_dir})
      message(FATAL_ERROR "Python package ${python_name} not defined")
    endif(EXISTS ${python_package_dir})
  endif(python_build)
endmacro(remake_python_extensions)

macro(remake_python_swig)
# check for swig
  remake_python_extensions(${ARGN} *.i)
endmacro(remake_python_swig)

remake_file_rmdir(${REMAKE_PYTHON_DIR})
remake_file(REMAKE_PYTHON_SETUP_FILE ${REMAKE_PYTHON_DIR}/setup.py)
