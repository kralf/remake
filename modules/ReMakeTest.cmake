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
include(ReMakeFind)
include(ReMakeTarget)

include(ReMakePrivate)

### \brief ReMake testing macros
#   The ReMake testing module provides unit testing support.

if(NOT DEFINED REMAKE_TEST_CMAKE)
  remake_set(REMAKE_TEST_CMAKE ON)

  remake_set(REMAKE_TEST_ALL_TARGET test)
  remake_set(REMAKE_TEST_TARGET_SUFFIX test)

  remake_set(REMAKE_TEST_DIR ReMakeTesting)
  remake_file_rmdir(${REMAKE_TEST_DIR} TOPLEVEL)
endif(NOT DEFINED REMAKE_TEST_CMAKE)

### \brief Generate a test based on an executable target.
#   This macro generates a unit test based on an executable target named
#   ${TARGET}. It therefore first defines the build rules for the executable
#   target by calling remake_add_executable() and then generates a
#   corresponding testing target ${TARGET}_${REMAKE_TEST_TARGET_SUFFIX}
#   through remake_test(). Upon invocation, the testing target executes
#   the produced output binary. Note that execution of the testing target
#   thus implicitly fails with a non-zero return value of the executable.
#   \required[value] target The name of an existing executable target for
#     which to generate the test.
#   \optional[list] args An optional list of arguments to be passed on to
#     remake_add_executable() for defining the executable target. See ReMake
#     for details.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_add_executable(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_COMPONENT_TESTING_SUFFIX}. See ReMake 
#     for details.
#   \optional[list] TEST_DEPENDS:depend An optional list of additional file
#     or target dependencies for the testing target.
macro(remake_test_target test_target)
  remake_arguments(PREFIX test_ VAR COMPONENT LIST TEST_DEPENDS ARGN args
    ${ARGN})
  remake_component_name(test_default_component ${REMAKE_COMPONENT}
    ${REMAKE_COMPONENT_TESTING_SUFFIX})
  remake_set(test_component SELF DEFAULT ${test_default_component})
    
  remake_add_executable(
    ${test_target}
    ${test_args}
    COMPONENT ${test_component})
    
  get_target_property(test_command ${test_target} LOCATION)
  remake_test(
    "executable target"
    ${test_target}
    ${test_command}
    DEPENDS ${test_target} ${test_test_depends})
endmacro(remake_test_target)

### \brief Generate a Google test.
#   This macro generates a C++ unit testing target for Google's testing
#   framework. It therefore defines a new executable target which is
#   built against the Google test libraries or sources found on the build
#   system and then executes the output binary upon invocation of the
#   testing target.
#   \required[value] target The name of the executable target which will
#     be built and executed by the testing target.
#   \optional[list] args An optional list of arguments to be passed on to
#     remake_add_executable() for defining the executable target. See ReMake
#     for details.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_add_executable(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_COMPONENT_TESTING_SUFFIX}. See ReMake 
#     for details.
#   \optional[option] LINK_MAIN With this option being present, the
#     executable target will be linked against or built with a main
#     function. See the Google test documentation for details.
#   \optional[list] TEST_DEPENDS:depend An optional list of additional file
#     or target dependencies for the testing target.
macro(remake_test_google test_target)
  remake_arguments(PREFIX test_ VAR COMPONENT OPTION LINK_MAIN
    LIST TEST_DEPENDS ARGN args ${ARGN})
  remake_component_name(test_default_component ${REMAKE_COMPONENT}
    ${REMAKE_COMPONENT_TESTING_SUFFIX})
  remake_set(test_component SELF DEFAULT ${test_default_component})
  
  if(NOT GTEST_FOUND)
    remake_find_package(GTest QUIET OPTIONAL)
    if(NOT GTEST_FOUND)
      if(GTEST_INCLUDE_DIR)
        remake_find_file(src/gtest.cc PACKAGE GTest PATHS /usr/src/gtest
          OPTIONAL)
      endif(GTEST_INCLUDE_DIR)
    endif(NOT GTEST_FOUND)
    
    if(NOT GTEST_FOUND)
      remake_find_result(GTest ${GTEST_FOUND} TYPE package)
    endif(NOT GTEST_FOUND)
  endif(NOT GTEST_FOUND)
    
  remake_include(${GTEST_INCLUDE_DIR})
  if(GTEST_LIBRARY)
    if(test_link_main)
      remake_add_executable(
        ${test_target}
        ${test_args}
        LINK ${GTEST_MAIN_LIBRARY}
        COMPONENT ${test_component})
    else(test_link_main)
      remake_add_executable(
        ${test_target}
        ${test_args}
        LINK ${GTEST_LIBRARY}
        COMPONENT ${test_component})
    endif(test_link_main)    
  else(GTEST_LIBRARY)
    remake_include(${GTEST_PATH})
    if(test_link_main)
      remake_add_executable(
        ${test_target} ${GTEST_PATH}/src/gtest-all.cc
          ${GTEST_PATH}/src/gtest_main.cc
        ${test_args}
        COMPONENT ${test_component})
    else(test_link_main)
      remake_add_executable(
        ${test_target} ${GTEST_PATH}/src/gtest-all.cc
        ${test_args}
        COMPONENT ${test_component})
    endif(test_link_main)
  endif(GTEST_LIBRARY)
    
  get_target_property(test_command ${test_target} LOCATION)  
  remake_test(
    "Google"
    ${test_target}
    ${test_command}
    DEPENDS ${test_target} ${test_test_depends})
endmacro(remake_test_google)

### \brief Generate a Python nose test.
#   This macro generates a Python nose unit test. It therefore defines a
#   new testing target which executes a Python nose test script by calling
#   remake_test(). In addition, an install rule is defined for the script
#   through remake_add_scripts().
#   \required[value] name The name of the Python nose test. Note that, for
#     the generated testing target to not be multiply defined, a unique name
#     must be chosen for each nose test defined by a project.
#   \required[value] filename The filename of the Python nose test script
#     to be installed via remake_add_scripts() and executed for testing.
#   \optional[list] args An optional list of arguments to be passed on to
#     remake_add_scripts() for installing the test script. See ReMake for
#     details.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_add_scripts(), defaults to
#     ${REMAKE_COMPONENT}-${REMAKE_COMPONENT_TESTING_SUFFIX}. See ReMake 
#     for details.
#   \optional[value] MODULE_PATH:dir The optional name of the directory
#     containing the required Python modules for the nose test, defaulting
#     to ${CMAKE_CURRENT_SOURCE_DIR}.
#   \optional[list] TEST_DEPENDS:depend An optional list of additional file
#     or target dependencies for the testing target.
macro(remake_test_python_nose test_name test_filename)
  remake_arguments(PREFIX test_ VAR COMPONENT VAR MODULE_PATH
    LIST TEST_DEPENDS ARGN args ${ARGN})
  remake_set(test_module_path SELF DEFAULT ${CMAKE_CURRENT_SOURCE_DIR})
  remake_component_name(test_default_component ${REMAKE_COMPONENT}
    ${REMAKE_COMPONENT_TESTING_SUFFIX})
  remake_set(test_component SELF DEFAULT ${test_default_component})
  
  remake_find_executable(nosetests)  
  if(IS_ABSOLUTE ${test_filename})
    remake_set(test_script ${test_filename})
  else(IS_ABSOLUTE ${test_filename})
    remake_set(test_script ${CMAKE_CURRENT_SOURCE_DIR}/${test_filename})
  endif(IS_ABSOLUTE ${test_filename})
  
  if(NOT IS_ABSOLUTE ${test_module_path})
    remake_set(test_module_path
      ${CMAKE_CURRENT_SOURCE_DIR}/${test_module_path})
  endif(NOT IS_ABSOLUTE ${test_module_path})
  
  remake_add_scripts(
    ${test_filename}
    ${test_args}
    COMPONENT ${test_component})
  remake_test(
    "Python nose"
    ${test_name}
    PYTHONPATH=${test_module_path} ${NOSETESTS_EXECUTABLE} -v ${test_script}
    DEPENDS ${test_filename} ${test_test_depends})
endmacro(remake_test_python_nose)

### \brief Define a testing target.
#   This macro is a helper macro to define testing targets for all requested
#   test types. It associates the testing command with a new testing target
#   ${NAME}_${REMAKE_TEST_TARGET_SUFFIX} named after the specified test. This
#   command is modified such that all output generated by the test will be
#   written into a log file. Note that a call to the testing target implicitly
#   fails with a non-zero return value of the executed testing command.
#   \required[value] type The human-readable type of test for which to
#     generate the testing target.
#   \required[value] name The name of an existing executable target for
#     which to generate the testing target.
#   \required[value] command The testing command to be executed.
#   \optional[list] args An optional list of arguments to the testing command.
#   \optional[list] DEPENDS:depend An optional list of file or target
#     dependencies for the testing target.
#   \optional[value] DESCRIPTION:string An optional descripition of the
#     testing target.
macro(remake_test test_type test_name test_command)
  remake_arguments(PREFIX test_ LIST DEPENDS ARGN args ${ARGN})
  if(NOT TARGET ${REMAKE_TEST_ALL_TARGET})
    remake_target(${REMAKE_TEST_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_TEST_ALL_TARGET})
  if(NOT EXISTS ${REMAKE_TEST_DIR})
    remake_file_mkdir(${REMAKE_TEST_DIR} TOPLEVEL)
  endif(NOT EXISTS ${REMAKE_TEST_DIR})
  
  remake_target_name(test_target ${test_name} ${REMAKE_TEST_TARGET_SUFFIX})
  remake_file(test_log ${REMAKE_TEST_DIR}/${test_name} TOPLEVEL)
  
  remake_target(
    ${test_target}
    COMMAND ${test_command} ${test_args} 1> ${test_log}
    COMMENT "Running ${test_type} test ${test_name}"
    ${DEPENDS})
  add_dependencies(${REMAKE_TEST_ALL_TARGET} ${test_target})
endmacro(remake_test)
