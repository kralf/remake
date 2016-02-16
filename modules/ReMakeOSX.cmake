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

### \brief ReMake OS X macros
#   The ReMake OSX  macros provide abstracted access to OS X-specific
#   build system facilities.
#
#   \variable REMAKE_OSX_FOUND Indicates if ReMake believes to run in an
#     OS X-compliant build environment.
#   \variable REMAKE_OSX_NAME The name of the build system's OS X version.
#   \variable REMAKE_OSX_CODENAME The code name of the build system's
#     OS X version.
#   \variable REMAKE_OSX_RELEASE The release number of the build system's
#     OS X version.
#   \variable REMAKE_OSX_BUILD The build number of the build system's
#     OS X version.

include(ReMakePrivate)
include(ReMakeFile)
include(ReMakeFind)

if(NOT DEFINED REMAKE_OSX_CMAKE)
  remake_set(REMAKE_OSX_CMAKE ON)
  remake_unset(REMAKE_OSX_NAME)
  remake_unset(REMAKE_OSX_CODENAME)
  remake_unset(REMAKE_OSX_RELEASE)
  remake_unset(REMAKE_OSX_BUILD)

  if(NOT DEFINED REMAKE_OSX_FOUND)
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      remake_set(REMAKE_OSX_FOUND ON)
    else(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      remake_set(REMAKE_OSX_FOUND OFF)
    endif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")

    if(REMAKE_OSX_FOUND)
      remake_find_executable(sw_vers OPTIONAL QUIET)
      if(SW_VERS_FOUND)
        execute_process(
          COMMAND ${SW_VERS_EXECUTABLE} -productName
          OUTPUT_VARIABLE REMAKE_OSX_NAME
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        execute_process(
          COMMAND ${SW_VERS_EXECUTABLE} -productVersion
          OUTPUT_VARIABLE REMAKE_OSX_VERSION
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        execute_process(
          COMMAND ${SW_VERS_EXECUTABLE} -buildVersion
          OUTPUT_VARIABLE REMAKE_OSX_BUILD
          OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
      endif(SW_VERS_FOUND)

      remake_find_file(Info.plist
        PACKAGE "Setup Assistant"
        PATHS "/System/Library/CoreServices/Setup Assistant.app/Contents")
      if(SETUP_ASSISTANT_FOUND)
        remake_set(osx_license
          "${SETUP_ASSISTANT_PATH}/Resources/en.lproj/OSXSoftwareLicense.rtf")
        if(EXISTS "${osx_license}")
          execute_process(
            COMMAND grep -oE "SOFTWARE LICENSE AGREEMENT FOR OS X.*[A-Z]"
              "${osx_license}"
            OUTPUT_VARIABLE osx_license_line
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
          if(osx_license_line)
            string(REGEX REPLACE "SOFT.*OS X " "" REMAKE_OSX_CODENAME
              "${osx_license_line}")
          endif(osx_license_line)
        endif(EXISTS "${osx_license}")
      endif(SETUP_ASSISTANT_FOUND)
    endif(REMAKE_OSX_FOUND)

    remake_set(REMAKE_OSX_FOUND ${REMAKE_OSX_FOUND}
      CACHE BOOL "Build system is an OS X version.")
    remake_set(REMAKE_OSX_NAME ${REMAKE_OSX_NAME}
      CACHE STRING "Name of the OS X version.")
    remake_set(REMAKE_OSX_CODENAME ${REMAKE_OSX_CODENAME}
      CACHE STRING "Code name of the OS X version.")
    remake_set(REMAKE_OSX_RELEASE ${REMAKE_OSX_RELEASE}
      CACHE STRING "Release number of the OS X version.")
    remake_set(REMAKE_OSX_BUILD ${REMAKE_OSX_BUILD}
    CACHE STRING "Build number of the OS X version.")

    if(REMAKE_OSX_FOUND)
      if(REMAKE_OSX_NAME)
        message(STATUS
          "The build system is ${REMAKE_OSX_NAME} (${REMAKE_OSX_VERSION})")
      else(REMAKE_OSX_NAME)
        message(STATUS "The build system is an unknown OS X version")
      endif(REMAKE_OSX_NAME)
    endif(REMAKE_OSX_FOUND)
  endif(NOT DEFINED REMAKE_OSX_FOUND)
else(NOT DEFINED REMAKE_OSX_CMAKE)
  return()
endif(NOT DEFINED REMAKE_OSX_CMAKE)

include(ReMakeComponent)
include(ReMakeDistribute)
include(ReMakePack)
