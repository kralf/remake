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
include(ReMakeFind)

### \brief ReMake ROS build macros
#   The ReMake ROS build macros provide access to the ROS build system
#   configuration without requirement for the ROS CMake API. Note that
#   all ROS environment variables should be initialized by sourcing the
#   corresponding ROS setup script prior to calling CMake.

### \brief Configure the ROS build system.
#   This macro discovers ROS, initializes ${ROS_PATH} and includes the
#   public CMake macros of ROS. Note that the macro automatically gets
#   invoked by the macros defined in this module. It needs not be called
#   directly from a CMakeLists.txt file.
macro(remake_ros)
  if(NOT ROS_FOUND)
    remake_find_file(core/rosbuild/rosbuild.cmake PACKAGE ROS
      PATHS $ENV{ROS_ROOT})
  endif(NOT ROS_FOUND)
endmacro(remake_ros)

### \brief Find a ROS package.
#   This macro discovers a ROS package in the distribution under ${ROS_PATH}
#   by calling rospack. If the ROS package was found, the variable name
#   conversion of ROS_${PACKAGE}_FOUND is set to TRUE, and ROS_${PACKAGE}_PATH,
#   ROS_${PACKAGE}_INCLUDE_DIRS, ROS_${PACKAGE}_LIBRARIES, and
#   ROS_${PACKAGE}_LIBRARY_DIRS are initialized accordingly. In addition, the
#   directories in which the linker will look for the package libraries is
#   specified by passing ROS_${PACKAGE}_LIBRARY_DIRS to CMake's
#   link_directories().
#   \required[value] package The name of the ROS package to be discovered.
#   \optional[option] OPTIONAL If provided, this option is passed on to
#     remake_find_result().
macro(remake_ros_find_package ros_package)
  remake_arguments(PREFIX ros_ OPTION OPTIONAL ${ARGN})
  remake_ros()

  if(ROS_FOUND)
    remake_find_executable(rospack PATHS $ENV{ROS_ROOT}/../../bin)

    remake_var_name(ros_path_var ROS ${ros_package} PATH)
    remake_var_name(ros_include_dirs_var ROS ${ros_package} INCLUDE_DIRS)
    remake_var_name(ros_libraries_var ROS ${ros_package} LIBRARIES)
    remake_var_name(ros_library_dirs_var ROS ${ros_package} LIBRARY_DIRS)

    execute_process(
      COMMAND ${ROSPACK_EXECUTABLE} find ${ros_package}
      RESULT_VARIABLE ros_result
      OUTPUT_VARIABLE ${ros_path_var}
      OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(ros_result)
      remake_set(${ros_path_var} ${ros_path_var}-NOTFOUND CACHE PATH
        "Path to ROS package ${ros_package}.")
    else(ros_result)
      execute_process(
        COMMAND ${ROSPACK_EXECUTABLE} cflags-only-I ${ros_package}
        OUTPUT_VARIABLE ros_include_dirs
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      execute_process(
        COMMAND ${ROSPACK_EXECUTABLE} libs-only-l ${ros_package}
        OUTPUT_VARIABLE ros_libraries
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      execute_process(
        COMMAND ${ROSPACK_EXECUTABLE} libs-only-L ${ros_package}
        OUTPUT_VARIABLE ros_library_dirs
        OUTPUT_STRIP_TRAILING_WHITESPACE)

      remake_set(${ros_path_var} ${${ros_path_var}} CACHE PATH
        "Path to ROS package ${ros_package}.")
      string(REGEX REPLACE "[ ]+" ";" ${ros_include_dirs_var}
        ${ros_include_dirs})
      string(REGEX REPLACE "[ ]+" ";" ${ros_libraries_var} ${ros_libraries})
      string(REGEX REPLACE "[ ]+" ";" ${ros_library_dirs_var}
        ${ros_library_dirs})

      link_directories(${${ros_library_dirs_var}})
    endif(ros_result)

    remake_find_result("ROS ${ros_package}" ${${ros_path_var}} ${OPTIONAL})
  endif(ROS_FOUND)
endmacro(remake_ros_find_package)
