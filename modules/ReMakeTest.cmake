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

### \brief ReMake testing macros
#   The ReMake testing module provides unit testing support.

remake_set(REMAKE_TEST_ALL_TARGET tests)
remake_set(REMAKE_TEST_TARGET_SUFFIX test)

remake_set(REMAKE_TEST_DIR ReMakeTesting)

### \brief Define a ReMake unit testing target.
#   This macro adds a unit test for an existing executable target named
#   ${TARGET}. It therefor defines a new testing target
#   ${TARGET}_${REMAKE_TEST_TARGET_SUFFIX} which depends on ${TARGET} and
#   executes its output binary upon invocation. Note that a call to the testing
#   target implicitly fails with a non-zero return value.
#   \required[value] target The name of an existing executable target for
#     which to add the unit test.
macro(remake_test test_exec_target)
  if(NOT TARGET ${REMAKE_TEST_ALL_TARGET})
    remake_target(${REMAKE_TEST_ALL_TARGET})
  endif(NOT TARGET ${REMAKE_TEST_ALL_TARGET})
  if(NOT EXISTS ${REMAKE_TEST_DIR})
    remake_file_mkdir(${REMAKE_TEST_DIR})
  endif(NOT EXISTS ${REMAKE_TEST_DIR})

  remake_target_name(test_target ${test_exec_target}
    ${REMAKE_TEST_TARGET_SUFFIX})
  get_target_property(test_binary ${test_exec_target} OUTPUT_NAME)
  remake_file(test_log ${REMAKE_TEST_DIR}/${test_exec_target}.log)
  remake_target(${test_target}
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/${test_binary} > ${test_log}
    COMMENT "Testing ${test_exec_target}")
  add_dependencies(${test_target} ${test_exec_target})
  add_dependencies(${REMAKE_TEST_ALL_TARGET} ${test_target})
endmacro(remake_test)
