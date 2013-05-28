############################################################################
#    Copyright (C) 2010-2011 by Ethan Rublee                               #
#    Copyright (C) 2011-2013 by Andrey Kamaev                              #
#    Copyright (C) 2013 by Ralf Kaestner                                   #
#    ralf.kaestner@gmail.com                                               #
#                                                                          #
#    All rights reserved.                                                  #
#                                                                          #
#    Redistribution and use in source and binary forms, with or without    #
#    modification, are permitted provided that the following conditions    #
#    are met:                                                              #
#                                                                          #
#    1. Redistributions of source code must retain the above copyright     #
#       notice, this list of conditions and the following disclaimer.      #
#                                                                          #
#    2. Redistributions in binary form must reproduce the above copyright  #
#       notice, this list of conditions and the following disclaimer in    #
#       the documentation and/or other materials provided with the         #
#       distribution.                                                      #
#                                                                          #
#    3. The name of the copyright holders may be used to endorse or        #
#       promote products derived from this software without specific       #
#       prior written permission.                                          #
#                                                                          #
#    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS   #
#    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT     #
#    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     #
#    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE        #
#    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,  #
#    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,  #
#    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;      #
#    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER      #
#    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT    #
#    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN     #
#    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       #
#    POSSIBILITY OF SUCH DAMAGE.                                           #
############################################################################

### \brief ReMake Android toolchain file
#   The ReMake Android toolchain file configures the cross-build environment
#   for Google Android. It requires the Android Native Development Kit (NDK)
#   to be installed on the build system. To cross-compile Qt applications,
#   the Necessitas Qt Source Development Kit should be available in addition.
#
#   \usage cmake -DCMAKE_TOOLCHAIN_FILE=ReMakeAndroid <CMAKE_SOURCE_DIR>
#
#   ${ANDROID} and ${BUILD_ANDROID} will be set to true, you may test any of
#   these variables to make necessary Android-specific configuration changes.
#
#   Also ${ARMEABI} or ${ARMEABI_V7A} or ${X86} or ${MIPS} will be set true,
#   mutually exclusive. The ${NEON} option will be set true if VFP is set to
#   NEON.
#
#   The ${LIBRARY_OUTPUT_PATH_ROOT} should be set in cache to determine where
#   Android libraries will be installed. The default is ${CMAKE_SOURCE_DIR},
#   and the built Android libraries will always appear under
#   ${LIBRARY_OUTPUT_PATH_ROOT}/libs/${ANDROID_NDK_ABI_NAME} (depending on
#   the target ABI). This is convenient for Android packaging.
#
#   The ReMake Android toolchain file is derived from the Android toolchain
#   file contributed by the OpenCV project (Ethan Rublee and Andrey Kamaev).
#
#   \variable ANDROID_NDK The path to the NDK root. Can be set as environment
#     variable or at first CMake run.
#   \variable ANDROID_STANDALONE_TOOLCHAIN The path to the standalone
#     toolchain. This option is not used if full NDK is found and ignored
#     if ANDROID_NDK is set. Can be set as environment variable or at first
#     CMake run.
#   \variable ANDROID_ABI Specifies the target Application Binary Interface
#     (ABI). This option nearly matches to the APP_ABI variable used by
#     ndk-build tool from Android NDK. Possible targets are:
#     * "armeabi" Matches to the NDK ABI with the same name. See the Android
#       NDK documentation for details.
#     * "armeabi-v7a" Matches to the NDK ABI with the same name. See the
#       Android NDK documentation for details.
#     * "armeabi-v7a with NEON" Same as armeabi-v7a, but sets NEON as
#       floating-point unit.
#     * "armeabi-v7a with VFPV3" Same as armeabi-v7a, but sets VFPV3 as
#       floating-point unit (has 32 registers instead of 16).
#     * "armeabi-v6 with VFP" Tuned for ARMv6 processors having VFP.
#     * "x86" Matches to the NDK ABI with the same name. See the Android
#       NDK documentation for details.
#     * "mips" Matches to the NDK ABI with the same name (not tested on real
#       devices by the authos of this toolchain). See the Android NDK
#       documentation for details.
#   \variable ANDROID_NATIVE_API_LEVEL The level of Android API to compile
#     for. This option is read-only when the standalone toolchain is used.
#   \variable ANDROID_TOOLCHAIN_NAME The name of compiler toolchain to be
#     used. The list of possible values depends on the NDK version. For NDK
#     r8c, the possible values are:
#     * arm-linux-androideabi-4.4.3
#     * arm-linux-androideabi-4.6
#     * arm-linux-androideabi-clang3.1
#     * mipsel-linux-android-4.4.3
#     * mipsel-linux-android-4.6
#     * mipsel-linux-android-clang3.1
#     * x86-4.4.3
#     * x86-4.6
#     * x86-clang3.1
#   \variable ANDROID_FORCE_ARM_BUILD Set to ON to generate 32-bit ARM
#     instructions instead of Thumb. Is not available for "x86" (inapplicable)
#     and "armeabi-v6 with VFP" (is forced to be ON) ABIs.
#   \variable ANDROID_NO_UNDEFINED Set to ON to show all undefined symbols as
#     linker errors even if they are not used.
#   \variable ANDROID_SO_UNDEFINED Set to ON to allow undefined symbols in
#     shared libraries. Automatically turned for NDK r5x and r6x due to GLESv2
#     problems.
#   \variable LIBRARY_OUTPUT_PATH_ROOT The path to output binary files. See
#     additional details below.
#   \variable ANDROID_SET_OBSOLETE_VARIABLES If set, then toolchain defines some
#     obsolete variables which were used by previous versions of this file for
#     backward compatibility.
#   \variable ANDROID_STL Specifies the runtime to use. Possible values are:
#     * none Do not configure the runtime.
#     * system Use the default minimal system C++ runtime library. Implies
#       -fno-rtti -fno-exceptions. Is not available for standalone toolchain.
#     * system_re Use the default minimal system C++ runtime library. Implies
#       -frtti -fexceptions. Is not available for standalone toolchain.
#     * gabi++_static Use the GAbi++ runtime as a static library. Implies -frtti
#       -fno-exceptions. Available for NDK r7 and newer. Is not available for
#       standalone toolchain.
#     * gabi++_shared Use the GAbi++ runtime as a shared library. Implies -frtti
#       -fno-exceptions. Available for NDK r7 and newer. Is not available for
#       standalone toolchain.
#     * stlport_static Use the STLport runtime as a static library. Implies
#       -fno-rtti -fno-exceptions for NDK before r7. Implies -frtti
#       -fno-exceptions for NDK r7 and newer. Is not available for standalone
#       toolchain.
#     * stlport_shared Use the STLport runtime as a shared library. Implies
#       -fno-rtti -fno-exceptions for NDK before r7. Implies -frtti
#       -fno-exceptions for NDK r7 and newer. Is not available for standalone
#       toolchain.
#     * gnustl_static Use the GNU STL as a static library. Implies -frtti
#       -fexceptions.
#     * gnustl_shared Use the GNU STL as a shared library. Implies -frtti
#       -fno-exceptions. Available for NDK r7b and newer. Silently degrades
#       to gnustl_static if not available.
#   \variable ANDROID_STL_FORCE_FEATURES Turn on rtti and exceptions support
#     based on chosen runtime. If disabled, then the user is responsible for
#     settings these options.
#   \variable NECESSITAS The path to the Necessitas NDK root. Can be set as
#     environment variable or at first CMake run.

cmake_minimum_required(VERSION 2.6.3)

if(DEFINED CMAKE_CROSSCOMPILING)
  # Subsequent toolchain loading is not really needed
  return()
endif()

if(CMAKE_TOOLCHAIN_FILE)
  # Touch toolchain variable only to suppress "unused variable" warning
endif()

get_property(_CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)
if(_CMAKE_IN_TRY_COMPILE)
 include("${CMAKE_CURRENT_SOURCE_DIR}/../android.toolchain.config.cmake"
    OPTIONAL)
endif()

# This one is important
set(CMAKE_SYSTEM_NAME Linux)
# This one not so much
set(CMAKE_SYSTEM_VERSION 1)

# Rpath makes low sence for Android
set(CMAKE_SKIP_RPATH TRUE CACHE BOOL
  "If set, runtime paths are not added when using shared libraries.")

set(ANDROID_SUPPORTED_NDK_VERSIONS ${ANDROID_EXTRA_NDK_VERSIONS}
  -r8e -r8d -r8c -r8b -r8 -r7c -r7b -r7 -r6b -r6 -r5c -r5b -r5 "")
if(NOT DEFINED ANDROID_NDK_SEARCH_PATHS)
  if(CMAKE_HOST_WIN32)
    file(TO_CMAKE_PATH "$ENV{PROGRAMFILES}" ANDROID_NDK_SEARCH_PATHS)
    set(ANDROID_NDK_SEARCH_PATHS "${ANDROID_NDK_SEARCH_PATHS}/android-ndk"
      "$ENV{SystemDrive}/NVPACK/android-ndk")
  else()
    file(TO_CMAKE_PATH "$ENV{HOME}" ANDROID_NDK_SEARCH_PATHS)
    set(ANDROID_NDK_SEARCH_PATHS /opt/android-ndk
      "${ANDROID_NDK_SEARCH_PATHS}/NVPACK/android-ndk")
  endif()
endif()
  if(NOT DEFINED ANDROID_STANDALONE_TOOLCHAIN_SEARCH_PATH)
  set(ANDROID_STANDALONE_TOOLCHAIN_SEARCH_PATH /opt/android-toolchain)
endif()

set(ANDROID_SUPPORTED_ABIS_arm "armeabi-v7a" "armeabi" "armeabi-v7a with NEON"
  "armeabi-v7a with VFPV3" "armeabi-v6 with VFP")
set(ANDROID_SUPPORTED_ABIS_x86 "x86")
set(ANDROID_SUPPORTED_ABIS_mipsel "mips")

set(ANDROID_DEFAULT_NDK_API_LEVEL 8)
set(ANDROID_DEFAULT_NDK_API_LEVEL_x86 9)
set(ANDROID_DEFAULT_NDK_API_LEVEL_mips 9)

macro(remake_android_filter_list listvar regex)
  if(${listvar})
    foreach(__val ${${listvar}})
    if(__val MATCHES "${regex}")
      list(REMOVE_ITEM ${listvar} "${__val}")
    endif()
    endforeach()
  endif()
endmacro()

macro(remake_android_var var_name)
  set(__test_path 0)
  foreach(__var ${ARGN})
    if(__var STREQUAL "PATH")
    set(__test_path 1)
    break()
    endif()
  endforeach()
  if(__test_path AND NOT EXISTS "${${var_name}}")
    unset(${var_name} CACHE)
  endif()
  if("${${var_name}}" STREQUAL "")
    set(__values 0)
    foreach(__var ${ARGN})
    if(__var STREQUAL "VALUES")
      set(__values 1)
    elseif(NOT __var STREQUAL "PATH")
      set(__obsolete 0)
      if(__var MATCHES "^OBSOLETE_.*$")
      string(REPLACE "OBSOLETE_" "" __var "${__var}")
      set(__obsolete 1)
      endif()
      if(__var MATCHES "^ENV_.*$")
      string(REPLACE "ENV_" "" __var "${__var}")
      set(__value "$ENV{${__var}}")
      elseif(DEFINED ${__var})
      set(__value "${${__var}}")
      else()
      if(__values)
        set(__value "${__var}")
      else()
        set(__value "")
      endif()
      endif()
      if(NOT "${__value}" STREQUAL "")
      if(__test_path)
        if(EXISTS "${__value}")
        file(TO_CMAKE_PATH "${__value}" ${var_name})
        if(__obsolete AND NOT _CMAKE_IN_TRY_COMPILE)
          message(WARNING "Using value of obsolete variable ${__var} as initial value for ${var_name}. Please note, that ${__var} can be completely removed in future versions of the toolchain.")
        endif()
        break()
        endif()
      else()
        set(${var_name} "${__value}")
        if(__obsolete AND NOT _CMAKE_IN_TRY_COMPILE)
          message(WARNING "Using value of obsolete variable ${__var} as initial value for ${var_name}. Please note, that ${__var} can be completely removed in future versions of the toolchain.")
        endif()
        break()
      endif()
      endif()
    endif()
    endforeach()
    unset(__value)
    unset(__values)
    unset(__obsolete)
  elseif(__test_path)
    file(TO_CMAKE_PATH "${${var_name}}" ${var_name})
  endif()
  unset(__test_path)
endmacro()

macro(remake_android_detect_api _var _path)
  SET(__ndkApiLevelRegex "^[\t ]*#define[\t ]+__ANDROID_API__[\t ]+([0-9]+)[\t ]*$")
  FILE(STRINGS ${_path} __apiFileContent REGEX "${__ndkApiLevelRegex}")
  if(NOT __apiFileContent)
    message(SEND_ERROR "Could not get Android native API level. Probably you have specified invalid level value, or your copy of NDK/toolchain is broken.")
  endif()
  string(REGEX REPLACE "${__ndkApiLevelRegex}" "\\1" ${_var} "${__apiFileContent}")
  unset(__apiFileContent)
  unset(__ndkApiLevelRegex)
  endmacro()

  macro(remake_android_detect_machine _var _root)
  if(EXISTS "${_root}")
    file(GLOB __gccExePath RELATIVE "${_root}/bin/" "${_root}/bin/*-gcc${TOOL_OS_SUFFIX}")
    remake_android_filter_list(__gccExePath "^[.].*")
    list(LENGTH __gccExePath __gccExePathsCount)
    if(NOT __gccExePathsCount EQUAL 1  AND NOT _CMAKE_IN_TRY_COMPILE)
    message(WARNING "Could not determine machine name for compiler from ${_root}")
    set(${_var} "")
    else()
    get_filename_component(__gccExeName "${__gccExePath}" NAME_WE)
    string(REPLACE "-gcc" "" ${_var} "${__gccExeName}")
    endif()
    unset(__gccExePath)
    unset(__gccExePathsCount)
    unset(__gccExeName)
  else()
    set(${_var} "")
  endif()
endmacro()

# Fight against cygwin
set(ANDROID_FORBID_SYGWIN TRUE CACHE BOOL
  "Prevent cmake from working under cygwin and using cygwin tools")
mark_as_advanced(ANDROID_FORBID_SYGWIN)
if(ANDROID_FORBID_SYGWIN)
 if(CYGWIN)
  message(FATAL_ERROR
    "Android NDK and android-cmake toolchain are not welcome Cygwin.")
 endif()

 if(CMAKE_HOST_WIN32)
    # Remove cygwin from PATH
    set(__new_path "$ENV{PATH}")
    remake_android_filter_list(__new_path "cygwin")
    set(ENV{PATH} "${__new_path}")
    unset(__new_path)
  endif()
endif()

# Detect current host platform
if(NOT DEFINED ANDROID_NDK_HOST_X64 AND CMAKE_HOST_SYSTEM_PROCESSOR
    MATCHES "amd64|x86_64|AMD64")
  set(ANDROID_NDK_HOST_X64 1 CACHE BOOL "Try to use 64-bit compiler toolchain")
  mark_as_advanced(ANDROID_NDK_HOST_X64)
endif()

set(TOOL_OS_SUFFIX "")
if(CMAKE_HOST_APPLE)
  set(ANDROID_NDK_HOST_SYSTEM_NAME "darwin-x86_64")
  set(ANDROID_NDK_HOST_SYSTEM_NAME2 "darwin-x86")
elseif(CMAKE_HOST_WIN32)
  set(ANDROID_NDK_HOST_SYSTEM_NAME "windows-x86_64")
  set(ANDROID_NDK_HOST_SYSTEM_NAME2 "windows")
  set(TOOL_OS_SUFFIX ".exe")
elseif(CMAKE_HOST_UNIX)
  set(ANDROID_NDK_HOST_SYSTEM_NAME "linux-x86_64")
  set(ANDROID_NDK_HOST_SYSTEM_NAME2 "linux-x86")
else()
  message(FATAL_ERROR
    "Cross-compilation on your platform is not supported by this toolchain")
endif()

if(NOT ANDROID_NDK_HOST_X64)
  set(ANDROID_NDK_HOST_SYSTEM_NAME ${ANDROID_NDK_HOST_SYSTEM_NAME2})
endif()

# See if we have path to Android NDK
remake_android_var(ANDROID_NDK PATH ENV_ANDROID_NDK)
if(NOT ANDROID_NDK)
  # See if we have path to Android standalone toolchain
  remake_android_var(ANDROID_STANDALONE_TOOLCHAIN PATH
    ENV_ANDROID_STANDALONE_TOOLCHAIN OBSOLETE_ANDROID_NDK_TOOLCHAIN_ROOT
    OBSOLETE_ENV_ANDROID_NDK_TOOLCHAIN_ROOT)

  if(NOT ANDROID_STANDALONE_TOOLCHAIN)
    # Try to find Android NDK in one of the the default locations
    set(__ndkSearchPaths)
    foreach(__ndkSearchPath ${ANDROID_NDK_SEARCH_PATHS})
    foreach(suffix ${ANDROID_SUPPORTED_NDK_VERSIONS})
      list(APPEND __ndkSearchPaths "${__ndkSearchPath}${suffix}")
    endforeach()
    endforeach()
    remake_android_var(ANDROID_NDK PATH VALUES ${__ndkSearchPaths})
    unset(__ndkSearchPaths)

    if(ANDROID_NDK)
      message(STATUS "Using default path for Android NDK: ${ANDROID_NDK}")
      message(STATUS "  If you prefer to use a different location,")
      message(STATUS "  please define a cmake or environment variable: ANDROID_NDK")
    else()
    # Try to find Android standalone toolchain in one of the the default locations
    remake_android_var(ANDROID_STANDALONE_TOOLCHAIN PATH
      ANDROID_STANDALONE_TOOLCHAIN_SEARCH_PATH)

    if(ANDROID_STANDALONE_TOOLCHAIN)
      message(STATUS
        "Using default path for standalone toolchain ${ANDROID_STANDALONE_TOOLCHAIN}")
      message(STATUS "  If you prefer to use a different location,"
      message(STATUS "  please define the variable: ANDROID_STANDALONE_TOOLCHAIN")
    endif(ANDROID_STANDALONE_TOOLCHAIN)
    endif(ANDROID_NDK)
  endif(NOT ANDROID_STANDALONE_TOOLCHAIN)
endif(NOT ANDROID_NDK)

# Remember found paths
if(ANDROID_NDK)
  get_filename_component(ANDROID_NDK "${ANDROID_NDK}" ABSOLUTE)
  # Try to detect change
  if(CMAKE_AR)
    string(LENGTH "${ANDROID_NDK}" __length)
    string(SUBSTRING "${CMAKE_AR}" 0 ${__length} __androidNdkPreviousPath)
    if(NOT __androidNdkPreviousPath STREQUAL ANDROID_NDK)
    message(FATAL_ERROR
      "It is not possible to change the NKD path on subsequent CMake run.")
    endif()
    unset(__androidNdkPreviousPath)
    unset(__length)
  endif()
  set(ANDROID_NDK "${ANDROID_NDK}" CACHE INTERNAL "Path of the Android NDK" FORCE)
  set(BUILD_WITH_ANDROID_NDK True)
  file(STRINGS "${ANDROID_NDK}/RELEASE.TXT" ANDROID_NDK_RELEASE_FULL LIMIT_COUNT 1 REGEX r[0-9]+[a-z]?)
  string(REGEX MATCH r[0-9]+[a-z]? ANDROID_NDK_RELEASE "${ANDROID_NDK_RELEASE_FULL}")
  elseif(ANDROID_STANDALONE_TOOLCHAIN)
  get_filename_component(ANDROID_STANDALONE_TOOLCHAIN "${ANDROID_STANDALONE_TOOLCHAIN}" ABSOLUTE)
  # Try to detect change
  if(CMAKE_AR)
    string(LENGTH "${ANDROID_STANDALONE_TOOLCHAIN}" __length)
    string(SUBSTRING "${CMAKE_AR}" 0 ${__length} __androidStandaloneToolchainPreviousPath)
    if(NOT __androidStandaloneToolchainPreviousPath STREQUAL ANDROID_STANDALONE_TOOLCHAIN)
    message(FATAL_ERROR
      "It is not possible to change the Android standalone toolchain path on subsequent CMake run.")
    endif()
    unset(__androidStandaloneToolchainPreviousPath)
    unset(__length)
  endif()
  set(ANDROID_STANDALONE_TOOLCHAIN "${ANDROID_STANDALONE_TOOLCHAIN}" CACHE
    INTERNAL "Path of the Android standalone toolchain" FORCE)
  set(BUILD_WITH_STANDALONE_TOOLCHAIN True)
else()
  list(GET ANDROID_NDK_SEARCH_PATHS 0 ANDROID_NDK_SEARCH_PATH)
  message(FATAL_ERROR
      "Could not find neither Android NDK nor Android standalone toolchain.
      You should either set an environment variable:
        export ANDROID_NDK=~/my-android-ndk
      or
        export ANDROID_STANDALONE_TOOLCHAIN=~/my-android-toolchain
      or put the toolchain or NDK in the default path:
        sudo ln -s ~/my-android-ndk ${ANDROID_NDK_SEARCH_PATH}
        sudo ln -s ~/my-android-toolchain ${ANDROID_STANDALONE_TOOLCHAIN_SEARCH_PATH}")
endif()

# Get all the details about standalone toolchain
if(BUILD_WITH_STANDALONE_TOOLCHAIN)
  remake_android_detect_api(ANDROID_SUPPORTED_NATIVE_API_LEVELS
    "${ANDROID_STANDALONE_TOOLCHAIN}/sysroot/usr/include/android/api-level.h")
  set(ANDROID_STANDALONE_TOOLCHAIN_API_LEVEL ${ANDROID_SUPPORTED_NATIVE_API_LEVELS})
  set(__availableToolchains "standalone")
  remake_android_detect_machine(__availableToolchainMachines
    "${ANDROID_STANDALONE_TOOLCHAIN}")
  if(NOT __availableToolchainMachines)
    message(FATAL_ERROR
      "Could not determine machine name of your toolchain. Probably your Android standalone toolchain is broken.")
  endif()
  if(__availableToolchainMachines MATCHES i686)
    set(__availableToolchainArchs "x86")
  elseif(__availableToolchainMachines MATCHES arm)
    set(__availableToolchainArchs "arm")
  elseif(__availableToolchainMachines MATCHES mipsel)
    set(__availableToolchainArchs "mipsel")
  endif()
  execute_process(COMMAND "${ANDROID_STANDALONE_TOOLCHAIN}/bin/${__availableToolchainMachines}-gcc${TOOL_OS_SUFFIX}"
    -dumpversion
    OUTPUT_VARIABLE __availableToolchainCompilerVersions OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REGEX MATCH "[0-9]+[.][0-9]+([.][0-9]+)?" __availableToolchainCompilerVersions
    "${__availableToolchainCompilerVersions}")
  if(EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/bin/clang${TOOL_OS_SUFFIX}")
    list(APPEND __availableToolchains "standalone-clang")
    list(APPEND __availableToolchainMachines ${__availableToolchainMachines})
    list(APPEND __availableToolchainArchs ${__availableToolchainArchs})
    list(APPEND __availableToolchainCompilerVersions ${__availableToolchainCompilerVersions})
  endif()
endif()

macro(remake_android_ndk_glob __availableToolchainsVar __availableToolchainsLst __host_system_name)
  foreach(__toolchain ${${__availableToolchainsLst}})
    if("${__toolchain}" MATCHES "-clang3[.][0-9]$" AND NOT EXISTS
      "${ANDROID_NDK}/toolchains/${__toolchain}/prebuilt/")
      string(REGEX REPLACE "-clang3[.][0-9]$" "-4.6" __gcc_toolchain "${__toolchain}")
    else()
      set(__gcc_toolchain "${__toolchain}")
    endif()
    remake_android_detect_machine(__machine
      "${ANDROID_NDK}/toolchains/${__gcc_toolchain}/prebuilt/${__host_system_name}")
    if(__machine)
      string(REGEX MATCH "[0-9]+[.][0-9]+([.][0-9]+)?$" __version "${__gcc_toolchain}")
      string(REGEX MATCH "^[^-]+" __arch "${__gcc_toolchain}")
      list(APPEND __availableToolchainMachines "${__machine}")
      list(APPEND __availableToolchainArchs "${__arch}")
      list(APPEND __availableToolchainCompilerVersions "${__version}")
      list(APPEND ${__availableToolchainsVar} "${__toolchain}")
    endif()
    unset(__gcc_toolchain)
  endforeach()
endmacro()

# Get all the details about NDK
if(BUILD_WITH_ANDROID_NDK)
  file(GLOB ANDROID_SUPPORTED_NATIVE_API_LEVELS RELATIVE
    "${ANDROID_NDK}/platforms" "${ANDROID_NDK}/platforms/android-*")
  string(REPLACE "android-" "" ANDROID_SUPPORTED_NATIVE_API_LEVELS
    "${ANDROID_SUPPORTED_NATIVE_API_LEVELS}")
  set(__availableToolchains "")
  set(__availableToolchainMachines "")
  set(__availableToolchainArchs "")
  set(__availableToolchainCompilerVersions "")
  if(ANDROID_TOOLCHAIN_NAME AND EXISTS
    "${ANDROID_NDK}/toolchains/${ANDROID_TOOLCHAIN_NAME}/")
    # Do not go through all toolchains if we know the name
    set(__availableToolchainsLst "${ANDROID_TOOLCHAIN_NAME}")
    remake_android_ndk_glob(__availableToolchains __availableToolchainsLst
      ${ANDROID_NDK_HOST_SYSTEM_NAME})
    if(NOT __availableToolchains AND NOT ANDROID_NDK_HOST_SYSTEM_NAME
      STREQUAL ANDROID_NDK_HOST_SYSTEM_NAME2)
      remake_android_ndk_glob(__availableToolchains __availableToolchainsLst
        ${ANDROID_NDK_HOST_SYSTEM_NAME2})
      if(__availableToolchains)
        set(ANDROID_NDK_HOST_SYSTEM_NAME ${ANDROID_NDK_HOST_SYSTEM_NAME2})
      endif()
    endif()
  endif()
  if(NOT __availableToolchains)
    file(GLOB __availableToolchainsLst RELATIVE
      "${ANDROID_NDK}/toolchains" "${ANDROID_NDK}/toolchains/*")
    if(__availableToolchains)
    list(SORT __availableToolchainsLst) # We need clang to go after gcc
    endif()
    remake_android_filter_list(__availableToolchainsLst "^[.]")
    remake_android_filter_list(__availableToolchainsLst "llvm")
    remake_android_ndk_glob(__availableToolchains __availableToolchainsLst ${ANDROID_NDK_HOST_SYSTEM_NAME})
    if(NOT __availableToolchains AND NOT ANDROID_NDK_HOST_SYSTEM_NAME STREQUAL ANDROID_NDK_HOST_SYSTEM_NAME2)
    remake_android_ndk_glob(__availableToolchains __availableToolchainsLst ${ANDROID_NDK_HOST_SYSTEM_NAME2})
    if(__availableToolchains)
      set(ANDROID_NDK_HOST_SYSTEM_NAME ${ANDROID_NDK_HOST_SYSTEM_NAME2})
    endif()
    endif()
  endif()
  if(NOT __availableToolchains)
    message(FATAL_ERROR "Could not find any working toolchain in the NDK. Probably your Android NDK is broken.")
  endif()
endif()

# Build list of available ABIs
set(ANDROID_SUPPORTED_ABIS "")
set(__uniqToolchainArchNames ${__availableToolchainArchs})
list(REMOVE_DUPLICATES __uniqToolchainArchNames)
list(SORT __uniqToolchainArchNames)
foreach(__arch ${__uniqToolchainArchNames})
  list(APPEND ANDROID_SUPPORTED_ABIS ${ANDROID_SUPPORTED_ABIS_${__arch}})
endforeach()
unset(__uniqToolchainArchNames)
if(NOT ANDROID_SUPPORTED_ABIS)
  message(FATAL_ERROR "No one of known Android ABIs is supported by this cmake toolchain.")
endif()

# Choose target ABI
remake_android_var(ANDROID_ABI OBSOLETE_ARM_TARGET OBSOLETE_ARM_TARGETS VALUES ${ANDROID_SUPPORTED_ABIS})
# Verify that target ABI is supported
list(FIND ANDROID_SUPPORTED_ABIS "${ANDROID_ABI}" __androidAbiIdx)
if(__androidAbiIdx EQUAL -1)
  string(REPLACE ";" "\", \"", PRINTABLE_ANDROID_SUPPORTED_ABIS  "${ANDROID_SUPPORTED_ABIS}")
  message(FATAL_ERROR "Specified ANDROID_ABI = \"${ANDROID_ABI}\" is not supported by this cmake toolchain or your NDK/toolchain.
    Supported values are: \"${PRINTABLE_ANDROID_SUPPORTED_ABIS}\"
    ")
  endif()
unset(__androidAbiIdx)

# Set target ABI options
if(ANDROID_ABI STREQUAL "x86")
  set(X86 true)
  set(ANDROID_NDK_ABI_NAME "x86")
  set(ANDROID_ARCH_NAME "x86")
  set(ANDROID_ARCH_FULLNAME "x86")
  set(ANDROID_LLVM_TRIPLE "i686-none-linux-android")
  set(CMAKE_SYSTEM_PROCESSOR "i686")
elseif(ANDROID_ABI STREQUAL "mips")
  set(MIPS true)
  set(ANDROID_NDK_ABI_NAME "mips")
  set(ANDROID_ARCH_NAME "mips")
  set(ANDROID_ARCH_FULLNAME "mipsel")
  set(ANDROID_LLVM_TRIPLE "mipsel-none-linux-android")
  set(CMAKE_SYSTEM_PROCESSOR "mips")
elseif(ANDROID_ABI STREQUAL "armeabi")
  set(ARMEABI true)
  set(ANDROID_NDK_ABI_NAME "armeabi")
  set(ANDROID_ARCH_NAME "arm")
  set(ANDROID_ARCH_FULLNAME "arm")
  set(ANDROID_LLVM_TRIPLE "armv5te-none-linux-androideabi")
  set(CMAKE_SYSTEM_PROCESSOR "armv5te")
elseif(ANDROID_ABI STREQUAL "armeabi-v6 with VFP")
  set(ARMEABI_V6 true)
  set(ANDROID_NDK_ABI_NAME "armeabi")
  set(ANDROID_ARCH_NAME "arm")
  set(ANDROID_ARCH_FULLNAME "arm")
  set(ANDROID_LLVM_TRIPLE "armv5te-none-linux-androideabi")
  set(CMAKE_SYSTEM_PROCESSOR "armv6")
  # Need always fallback to older platform
  set(ARMEABI true)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
  set(ARMEABI_V7A true)
  set(ANDROID_NDK_ABI_NAME "armeabi-v7a")
  set(ANDROID_ARCH_NAME "arm")
  set(ANDROID_ARCH_FULLNAME "arm")
  set(ANDROID_LLVM_TRIPLE "armv7-none-linux-androideabi")
  set(CMAKE_SYSTEM_PROCESSOR "armv7-a")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a with VFPV3")
  set(ARMEABI_V7A true)
  set(ANDROID_NDK_ABI_NAME "armeabi-v7a")
  set(ANDROID_ARCH_NAME "arm")
  set(ANDROID_ARCH_FULLNAME "arm")
  set(ANDROID_LLVM_TRIPLE "armv7-none-linux-androideabi")
  set(CMAKE_SYSTEM_PROCESSOR "armv7-a")
  set(VFPV3 true)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a with NEON")
  set(ARMEABI_V7A true)
  set(ANDROID_NDK_ABI_NAME "armeabi-v7a")
  set(ANDROID_ARCH_NAME "arm")
  set(ANDROID_ARCH_FULLNAME "arm")
  set(ANDROID_LLVM_TRIPLE "armv7-none-linux-androideabi")
  set(CMAKE_SYSTEM_PROCESSOR "armv7-a")
  set(VFPV3 true)
  set(NEON true)
else()
  message(SEND_ERROR "Unknown ANDROID_ABI=\"${ANDROID_ABI}\" is specified.")
endif()

if(CMAKE_BINARY_DIR AND EXISTS "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeSystem.cmake")
  # Really dirty hack
  # It is not possible to change CMAKE_SYSTEM_PROCESSOR after the first run...
  file(APPEND "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeSystem.cmake" "SET(CMAKE_SYSTEM_PROCESSOR \"${CMAKE_SYSTEM_PROCESSOR}\")\n")
endif()

if(ANDROID_ARCH_NAME STREQUAL "arm" AND NOT ARMEABI_V6)
  remake_android_var(ANDROID_FORCE_ARM_BUILD OBSOLETE_FORCE_ARM VALUES OFF)
  set(ANDROID_FORCE_ARM_BUILD ${ANDROID_FORCE_ARM_BUILD} CACHE BOOL "Use 32-bit ARM instructions instead of Thumb-1" FORCE)
  mark_as_advanced(ANDROID_FORCE_ARM_BUILD)
else()
  unset(ANDROID_FORCE_ARM_BUILD CACHE)
endif()

# Choose toolchain
if(ANDROID_TOOLCHAIN_NAME)
  list(FIND __availableToolchains "${ANDROID_TOOLCHAIN_NAME}" __toolchainIdx)
  if(__toolchainIdx EQUAL -1)
    list(SORT __availableToolchains)
    string(REPLACE ";" "\n  * " toolchains_list "${__availableToolchains}")
    set(toolchains_list "  * ${toolchains_list}")
    message(FATAL_ERROR "Specified toolchain \"${ANDROID_TOOLCHAIN_NAME}\" is missing in your NDK or broken. Please verify that your NDK is working or select another compiler toolchain.
      To configure the toolchain set CMake variable ANDROID_TOOLCHAIN_NAME to one of the following values:\n${toolchains_list}\n")
  endif()
  list(GET __availableToolchainArchs ${__toolchainIdx} __toolchainArch)
  if(NOT __toolchainArch STREQUAL ANDROID_ARCH_FULLNAME)
    message(SEND_ERROR "Selected toolchain \"${ANDROID_TOOLCHAIN_NAME}\" is not able to compile binaries for the \"${ANDROID_ARCH_NAME}\" platform.")
  endif()
  else()
  set(__toolchainIdx -1)
  set(__applicableToolchains "")
  set(__toolchainMaxVersion "0.0.0")
  list(LENGTH __availableToolchains __availableToolchainsCount)
  math(EXPR __availableToolchainsCount "${__availableToolchainsCount}-1")
  foreach(__idx RANGE ${__availableToolchainsCount})
    list(GET __availableToolchainArchs ${__idx} __toolchainArch)
    if(__toolchainArch STREQUAL ANDROID_ARCH_FULLNAME)
    list(GET __availableToolchainCompilerVersions ${__idx} __toolchainVersion)
    if(__toolchainVersion VERSION_GREATER __toolchainMaxVersion)
      set(__toolchainMaxVersion "${__toolchainVersion}")
      set(__toolchainIdx ${__idx})
    endif()
    endif()
  endforeach()
  unset(__availableToolchainsCount)
  unset(__toolchainMaxVersion)
  unset(__toolchainVersion)
endif()
unset(__toolchainArch)
if(__toolchainIdx EQUAL -1)
  message(FATAL_ERROR "No one of available compiler toolchains is able to compile for ${ANDROID_ARCH_NAME} platform.")
endif()
list(GET __availableToolchains ${__toolchainIdx} ANDROID_TOOLCHAIN_NAME)
list(GET __availableToolchainMachines ${__toolchainIdx} ANDROID_TOOLCHAIN_MACHINE_NAME)
list(GET __availableToolchainCompilerVersions ${__toolchainIdx} ANDROID_COMPILER_VERSION)

unset(__toolchainIdx)
unset(__availableToolchains)
unset(__availableToolchainMachines)
unset(__availableToolchainArchs)
unset(__availableToolchainCompilerVersions)

# Choose native API level
remake_android_var(ANDROID_NATIVE_API_LEVEL ENV_ANDROID_NATIVE_API_LEVEL ANDROID_API_LEVEL ENV_ANDROID_API_LEVEL ANDROID_STANDALONE_TOOLCHAIN_API_LEVEL ANDROID_DEFAULT_NDK_API_LEVEL_${ANDROID_ARCH_NAME} ANDROID_DEFAULT_NDK_API_LEVEL)
string(REGEX MATCH "[0-9]+" ANDROID_NATIVE_API_LEVEL "${ANDROID_NATIVE_API_LEVEL}")
# Adjust API level
set(__real_api_level ${ANDROID_DEFAULT_NDK_API_LEVEL_${ANDROID_ARCH_NAME}})
foreach(__level ${ANDROID_SUPPORTED_NATIVE_API_LEVELS})
  if(NOT __level GREATER ANDROID_NATIVE_API_LEVEL AND NOT __level LESS __real_api_level)
    set(__real_api_level ${__level})
  endif()
endforeach()
if(__real_api_level AND NOT ANDROID_NATIVE_API_LEVEL EQUAL __real_api_level)
  message(STATUS "Adjusting Android API level 'android-${ANDROID_NATIVE_API_LEVEL}' to 'android-${__real_api_level}'")
  set(ANDROID_NATIVE_API_LEVEL ${__real_api_level})
endif()
unset(__real_api_level)
# Validate
list(FIND ANDROID_SUPPORTED_NATIVE_API_LEVELS "${ANDROID_NATIVE_API_LEVEL}" __levelIdx)
if(__levelIdx EQUAL -1)
  message(SEND_ERROR "Specified Android native API level 'android-${ANDROID_NATIVE_API_LEVEL}' is not supported by your NDK/toolchain.")
else()
  if(BUILD_WITH_ANDROID_NDK)
    remake_android_detect_api(__realApiLevel "${ANDROID_NDK}/platforms/android-${ANDROID_NATIVE_API_LEVEL}/arch-${ANDROID_ARCH_NAME}/usr/include/android/api-level.h")
    if(NOT __realApiLevel EQUAL ANDROID_NATIVE_API_LEVEL)
    message(SEND_ERROR "Specified Android API level (${ANDROID_NATIVE_API_LEVEL}) does not match to the level found (${__realApiLevel}). Probably your copy of NDK is broken.")
    endif()
    unset(__realApiLevel)
  endif()
  set(ANDROID_NATIVE_API_LEVEL "${ANDROID_NATIVE_API_LEVEL}" CACHE STRING "Android API level for native code" FORCE)
  if(CMAKE_VERSION VERSION_GREATER "2.8")
    list(SORT ANDROID_SUPPORTED_NATIVE_API_LEVELS)
    set_property(CACHE ANDROID_NATIVE_API_LEVEL PROPERTY STRINGS ${ANDROID_SUPPORTED_NATIVE_API_LEVELS})
  endif()
endif()
unset(__levelIdx)

# Remember target ABI
set(ANDROID_ABI "${ANDROID_ABI}" CACHE STRING "The target ABI for Android. If arm, then armeabi-v7a is recommended for hardware floating point." FORCE)
if(CMAKE_VERSION VERSION_GREATER "2.8")
 list(SORT ANDROID_SUPPORTED_ABIS_${ANDROID_ARCH_FULLNAME})
 set_property(CACHE ANDROID_ABI PROPERTY STRINGS ${ANDROID_SUPPORTED_ABIS_${ANDROID_ARCH_FULLNAME}})
endif()

# Runtime choice (STL, rtti, exceptions)
if(NOT ANDROID_STL)
  # Honor legacy ANDROID_USE_STLPORT
  if(DEFINED ANDROID_USE_STLPORT)
    if(ANDROID_USE_STLPORT)
    set(ANDROID_STL stlport_static)
    endif()
    message(WARNING "You are using an obsolete variable ANDROID_USE_STLPORT to select the STL variant. Use -DANDROID_STL=stlport_static instead.")
  endif()
  if(NOT ANDROID_STL)
    set(ANDROID_STL gnustl_static)
  endif()
endif()
set(ANDROID_STL "${ANDROID_STL}" CACHE STRING "C++ runtime")
set(ANDROID_STL_FORCE_FEATURES ON CACHE BOOL "automatically configure rtti and exceptions support based on C++ runtime")
mark_as_advanced(ANDROID_STL ANDROID_STL_FORCE_FEATURES)

if(BUILD_WITH_ANDROID_NDK)
 if(NOT "${ANDROID_STL}" MATCHES "^(none|system|system_re|gabi\\+\\+_static|gabi\\+\\+_shared|stlport_static|stlport_shared|gnustl_static|gnustl_shared)$")
    message(FATAL_ERROR "ANDROID_STL is set to invalid value \"${ANDROID_STL}\".
  The possible values are:
    none           -> Do not configure the runtime.
    system         -> Use the default minimal system C++ runtime library.
    system_re      -> Same as system but with rtti and exceptions.
    gabi++_static  -> Use the GAbi++ runtime as a static library.
    gabi++_shared  -> Use the GAbi++ runtime as a shared library.
    stlport_static -> Use the STLport runtime as a static library.
    stlport_shared -> Use the STLport runtime as a shared library.
    gnustl_static  -> (default) Use the GNU STL as a static library.
    gnustl_shared  -> Use the GNU STL as a shared library.
  ")
  endif()
elseif(BUILD_WITH_STANDALONE_TOOLCHAIN)
  if(NOT "${ANDROID_STL}" MATCHES "^(none|gnustl_static|gnustl_shared)$")
    message(FATAL_ERROR "ANDROID_STL is set to invalid value \"${ANDROID_STL}\".
  The possible values are:
    none           -> Do not configure the runtime.
    gnustl_static  -> (default) Use the GNU STL as a static library.
    gnustl_shared  -> Use the GNU STL as a shared library.
  ")
  endif()
endif()

unset(ANDROID_RTTI)
unset(ANDROID_EXCEPTIONS)
unset(ANDROID_STL_INCLUDE_DIRS)
unset(__libstl)
unset(__libsupcxx)

if(NOT _CMAKE_IN_TRY_COMPILE AND ANDROID_NDK_RELEASE STREQUAL "r7b" AND ARMEABI_V7A AND NOT VFPV3 AND ANDROID_STL MATCHES "gnustl")
  message(WARNING  "The GNU STL armeabi-v7a binaries from NDK r7b can crash non-NEON devices. The files provided with NDK r7b were not configured properly, resulting in crashes on Tegra2-based devices and others when trying to use certain floating-point functions (e.g., cosf, sinf, expf).
  You are strongly recommended to switch to another NDK release.")
endif()

if(NOT _CMAKE_IN_TRY_COMPILE AND X86 AND ANDROID_STL MATCHES "gnustl" AND ANDROID_NDK_RELEASE STREQUAL "r6")
  message(WARNING  "The x86 system header file from NDK r6 has incorrect definition for ptrdiff_t. You are recommended to upgrade to a newer NDK release or manually patch the header:
See https://android.googlesource.com/platform/development.git f907f4f9d4e56ccc8093df6fee54454b8bcab6c2
  diff --git a/ndk/platforms/android-9/arch-x86/include/machine/_types.h b/ndk/platforms/android-9/arch-x86/include/machine/_types.h
  index 5e28c64..65892a1 100644
  --- a/ndk/platforms/android-9/arch-x86/include/machine/_types.h
  +++ b/ndk/platforms/android-9/arch-x86/include/machine/_types.h
  @@ -51,7 +51,11 @@ typedef long int       ssize_t;
   #endif
   #ifndef _PTRDIFF_T
   #define _PTRDIFF_T
  -typedef long           ptrdiff_t;
  +#  ifdef __ANDROID__
  +     typedef int            ptrdiff_t;
  +#  else
  +     typedef long           ptrdiff_t;
  +#  endif
   #endif
")
endif()

# Setup paths and STL for standalone toolchain
if(BUILD_WITH_STANDALONE_TOOLCHAIN)
  set(ANDROID_TOOLCHAIN_ROOT "${ANDROID_STANDALONE_TOOLCHAIN}")
  set(ANDROID_CLANG_TOOLCHAIN_ROOT "${ANDROID_STANDALONE_TOOLCHAIN}")
  set(ANDROID_SYSROOT "${ANDROID_STANDALONE_TOOLCHAIN}/sysroot")

  if(NOT ANDROID_STL STREQUAL "none")
    set(ANDROID_STL_INCLUDE_DIRS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/include/c++/${ANDROID_COMPILER_VERSION}")
    if(ARMEABI_V7A AND EXISTS "${ANDROID_STL_INCLUDE_DIRS}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/${CMAKE_SYSTEM_PROCESSOR}/bits")
    list(APPEND ANDROID_STL_INCLUDE_DIRS "${ANDROID_STL_INCLUDE_DIRS}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/${CMAKE_SYSTEM_PROCESSOR}")
    elseif(ARMEABI AND NOT ANDROID_FORCE_ARM_BUILD AND EXISTS "${ANDROID_STL_INCLUDE_DIRS}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/thumb/bits")
    list(APPEND ANDROID_STL_INCLUDE_DIRS "${ANDROID_STL_INCLUDE_DIRS}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/thumb")
    else()
    list(APPEND ANDROID_STL_INCLUDE_DIRS "${ANDROID_STL_INCLUDE_DIRS}/${ANDROID_TOOLCHAIN_MACHINE_NAME}")
    endif()
    # always search static GNU STL to get the location of libsupc++.a
    if(ARMEABI_V7A AND NOT ANDROID_FORCE_ARM_BUILD AND EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/thumb/libstdc++.a")
    set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/thumb")
    elseif(ARMEABI_V7A AND EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/libstdc++.a")
    set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}")
    elseif(ARMEABI AND NOT ANDROID_FORCE_ARM_BUILD AND EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/thumb/libstdc++.a")
    set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/thumb")
    elseif(EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/libstdc++.a")
    set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib")
    endif()
    if(__libstl)
    set(__libsupcxx "${__libstl}/libsupc++.a")
    set(__libstl    "${__libstl}/libstdc++.a")
    endif()
    if(NOT EXISTS "${__libsupcxx}")
    message(FATAL_ERROR "The required libstdsupc++.a is missing in your standalone toolchain.
  Usually it happens because of bug in make-standalone-toolchain.sh script from NDK r7, r7b and r7c.
  You need to either upgrade to newer NDK or manually copy
      $ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/libs/${ANDROID_NDK_ABI_NAME}/libsupc++.a
  to
      ${__libsupcxx}
    ")
    endif()
    if(ANDROID_STL STREQUAL "gnustl_shared")
    if(ARMEABI_V7A AND EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/libgnustl_shared.so")
      set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/libgnustl_shared.so")
    elseif(ARMEABI AND NOT ANDROID_FORCE_ARM_BUILD AND EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/thumb/libgnustl_shared.so")
      set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/thumb/libgnustl_shared.so")
    elseif(EXISTS "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/libgnustl_shared.so")
      set(__libstl "${ANDROID_STANDALONE_TOOLCHAIN}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/libgnustl_shared.so")
    endif()
    endif()
  endif()
endif()

# Clang
if("${ANDROID_TOOLCHAIN_NAME}" STREQUAL "standalone-clang")
  set(ANDROID_COMPILER_IS_CLANG 1)
  execute_process(COMMAND "${ANDROID_CLANG_TOOLCHAIN_ROOT}/bin/clang${TOOL_OS_SUFFIX}" --version OUTPUT_VARIABLE ANDROID_CLANG_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REGEX MATCH "[0-9]+[.][0-9]+" ANDROID_CLANG_VERSION "${ANDROID_CLANG_VERSION}")
elseif("${ANDROID_TOOLCHAIN_NAME}" MATCHES "-clang3[.][0-9]?$")
  string(REGEX MATCH "3[.][0-9]$" ANDROID_CLANG_VERSION "${ANDROID_TOOLCHAIN_NAME}")
  string(REGEX REPLACE "-clang${ANDROID_CLANG_VERSION}$" "-4.6" ANDROID_GCC_TOOLCHAIN_NAME "${ANDROID_TOOLCHAIN_NAME}")
  if(NOT EXISTS "${ANDROID_NDK}/toolchains/llvm-${ANDROID_CLANG_VERSION}/prebuilt/${ANDROID_NDK_HOST_SYSTEM_NAME}/bin/clang${TOOL_OS_SUFFIX}")
    message(FATAL_ERROR "Could not find the Clang compiler driver")
  endif()
  set(ANDROID_COMPILER_IS_CLANG 1)
  set(ANDROID_CLANG_TOOLCHAIN_ROOT "${ANDROID_NDK}/toolchains/llvm-${ANDROID_CLANG_VERSION}/prebuilt/${ANDROID_NDK_HOST_SYSTEM_NAME}")
else()
  set(ANDROID_GCC_TOOLCHAIN_NAME "${ANDROID_TOOLCHAIN_NAME}")
  unset(ANDROID_COMPILER_IS_CLANG CACHE)
endif()

string(REPLACE "." "" _clang_name "clang${ANDROID_CLANG_VERSION}")
if(NOT EXISTS "${ANDROID_CLANG_TOOLCHAIN_ROOT}/bin/${_clang_name}${TOOL_OS_SUFFIX}")
  set(_clang_name "clang")
endif()

# Setup paths and STL for NDK
if(BUILD_WITH_ANDROID_NDK)
  set(ANDROID_TOOLCHAIN_ROOT "${ANDROID_NDK}/toolchains/${ANDROID_GCC_TOOLCHAIN_NAME}/prebuilt/${ANDROID_NDK_HOST_SYSTEM_NAME}")
  set(ANDROID_SYSROOT "${ANDROID_NDK}/platforms/android-${ANDROID_NATIVE_API_LEVEL}/arch-${ANDROID_ARCH_NAME}")

  if(ANDROID_STL STREQUAL "none")
    # do nothing
  elseif(ANDROID_STL STREQUAL "system")
    set(ANDROID_RTTI             OFF)
    set(ANDROID_EXCEPTIONS       OFF)
    set(ANDROID_STL_INCLUDE_DIRS "${ANDROID_NDK}/sources/cxx-stl/system/include")
  elseif(ANDROID_STL STREQUAL "system_re")
    set(ANDROID_RTTI             ON)
    set(ANDROID_EXCEPTIONS       ON)
    set(ANDROID_STL_INCLUDE_DIRS "${ANDROID_NDK}/sources/cxx-stl/system/include")
  elseif(ANDROID_STL MATCHES "gabi")
    if(ANDROID_NDK_RELEASE STRLESS "r7")
    message(FATAL_ERROR "gabi++ is not awailable in your NDK. You have to upgrade to NDK r7 or newer to use gabi++.")
    endif()
    set(ANDROID_RTTI             ON)
    set(ANDROID_EXCEPTIONS       OFF)
    set(ANDROID_STL_INCLUDE_DIRS "${ANDROID_NDK}/sources/cxx-stl/gabi++/include")
    set(__libstl                 "${ANDROID_NDK}/sources/cxx-stl/gabi++/libs/${ANDROID_NDK_ABI_NAME}/libgabi++_static.a")
  elseif(ANDROID_STL MATCHES "stlport")
    if(NOT ANDROID_NDK_RELEASE STRLESS "r8d")
    set(ANDROID_EXCEPTIONS       ON)
    else()
    set(ANDROID_EXCEPTIONS       OFF)
    endif()
    if(ANDROID_NDK_RELEASE STRLESS "r7")
    set(ANDROID_RTTI            OFF)
    else()
    set(ANDROID_RTTI            ON)
    endif()
    set(ANDROID_STL_INCLUDE_DIRS "${ANDROID_NDK}/sources/cxx-stl/stlport/stlport")
    set(__libstl                 "${ANDROID_NDK}/sources/cxx-stl/stlport/libs/${ANDROID_NDK_ABI_NAME}/libstlport_static.a")
  elseif(ANDROID_STL MATCHES "gnustl")
    set(ANDROID_EXCEPTIONS       ON)
    set(ANDROID_RTTI             ON)
    if(EXISTS "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_COMPILER_VERSION}")
    if(ARMEABI_V7A AND ANDROID_COMPILER_VERSION VERSION_EQUAL "4.7" AND ANDROID_NDK_RELEASE STREQUAL "r8d")
      # gnustl binary for 4.7 compiler is buggy :(
      # TODO: look for right fix
      set(__libstl                "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/4.6")
    else()
      set(__libstl                "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_COMPILER_VERSION}")
    endif()
    else()
    set(__libstl                "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++")
    endif()
    set(ANDROID_STL_INCLUDE_DIRS "${__libstl}/include" "${__libstl}/libs/${ANDROID_NDK_ABI_NAME}/include")
    if(EXISTS "${__libstl}/libs/${ANDROID_NDK_ABI_NAME}/libgnustl_static.a")
    set(__libstl                "${__libstl}/libs/${ANDROID_NDK_ABI_NAME}/libgnustl_static.a")
    else()
    set(__libstl                "${__libstl}/libs/${ANDROID_NDK_ABI_NAME}/libstdc++.a")
    endif()
  else()
    message(FATAL_ERROR "Unknown runtime: ${ANDROID_STL}")
  endif()
  # find libsupc++.a - rtti & exceptions
  if(ANDROID_STL STREQUAL "system_re" OR ANDROID_STL MATCHES "gnustl")
    if(ANDROID_NDK_RELEASE STRGREATER "r8") # r8b
    set(__libsupcxx "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_COMPILER_VERSION}/libs/${ANDROID_NDK_ABI_NAME}/libsupc++.a")
    elseif(NOT ANDROID_NDK_RELEASE STRLESS "r7" AND ANDROID_NDK_RELEASE STRLESS "r8b")
    set(__libsupcxx "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/libs/${ANDROID_NDK_ABI_NAME}/libsupc++.a")
    else(ANDROID_NDK_RELEASE STRLESS "r7")
    if(ARMEABI_V7A)
      if(ANDROID_FORCE_ARM_BUILD)
      set(__libsupcxx "${ANDROID_TOOLCHAIN_ROOT}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/libsupc++.a")
      else()
      set(__libsupcxx "${ANDROID_TOOLCHAIN_ROOT}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/${CMAKE_SYSTEM_PROCESSOR}/thumb/libsupc++.a")
      endif()
    elseif(ARMEABI AND NOT ANDROID_FORCE_ARM_BUILD)
      set(__libsupcxx "${ANDROID_TOOLCHAIN_ROOT}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/thumb/libsupc++.a")
    else()
      set(__libsupcxx "${ANDROID_TOOLCHAIN_ROOT}/${ANDROID_TOOLCHAIN_MACHINE_NAME}/lib/libsupc++.a")
    endif()
    endif()
    if(NOT EXISTS "${__libsupcxx}")
    message(ERROR "Could not find libsupc++.a for a chosen platform. Either your NDK is not supported or is broken.")
    endif()
  endif()
endif()

# Setup paths for Necessitas
remake_android_var(NECESSITAS PATH ENV_NECESSITAS)
set(NECESSITAS "${NECESSITAS}" CACHE INTERNAL "Path of Necessitas" FORCE)
if(NECESSITAS)
  get_filename_component(NECESSITAS "${NECESSITAS}" ABSOLUTE)
  set(BUILD_WITH_NECESSITAS True)
endif(NECESSITAS)

remake_android_var(NECESSITAS_QT_VERSION ENV_NECESSITAS_QT_VERSION)
if(BUILD_WITH_NECESSITAS)
  file(GLOB NECESSITAS_SUPPORTED_QT_VERSIONS RELATIVE "${NECESSITAS}/Android/Qt" "${NECESSITAS}/Android/Qt/*")
  if(NOT NECESSITAS_QT_VERSION)
    list(GET NECESSITAS_SUPPORTED_QT_VERSIONS 0 NECESSITAS_QT_VERSION)
  endif()
  set(NECESSITAS_QT_VERSION "${NECESSITAS_QT_VERSION}" CACHE STRING "Necessitas Qt version" FORCE)
  set(NECESSITAS_TOOLCHAIN_ROOT "${NECESSITAS}/Android/Qt/${NECESSITAS_QT_VERSION}/${ANDROID_NDK_ABI_NAME}")
  set(NECESSITAS_SYSROOT "${NECESSITAS_TOOLCHAIN_ROOT}")
  set(NECESSITAS_INCLUDE_DIRS "${ANDROID_TOOLCHAIN_ROOT}/include")
  set(NECESSITAS_LINK_DIRS "${ANDROID_TOOLCHAIN_ROOT}/lib")
endif(BUILD_WITH_NECESSITAS)

# Case of shared STL linkage
if(ANDROID_STL MATCHES "shared" AND DEFINED __libstl)
 string(REPLACE "_static.a" "_shared.so" __libstl "${__libstl}")
 if(NOT _CMAKE_IN_TRY_COMPILE AND __libstl MATCHES "[.]so$")
  get_filename_component(__libstlname "${__libstl}" NAME)
  execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${__libstl}" "${LIBRARY_OUTPUT_PATH}/${__libstlname}" RESULT_VARIABLE __fileCopyProcess)
  if(NOT __fileCopyProcess EQUAL 0 OR NOT EXISTS "${LIBRARY_OUTPUT_PATH}/${__libstlname}")
   message(SEND_ERROR "Failed copying of ${__libstl} to the ${LIBRARY_OUTPUT_PATH}/${__libstlname}")
  endif()
  unset(__fileCopyProcess)
  unset(__libstlname)
 endif()
endif()

# Ccache support
remake_android_var(_ndk_ccache NDK_CCACHE ENV_NDK_CCACHE)
if(_ndk_ccache)
  if(DEFINED NDK_CCACHE AND NOT EXISTS NDK_CCACHE)
    unset(NDK_CCACHE CACHE)
  endif()
  find_program(NDK_CCACHE "${_ndk_ccache}" DOC "The path to ccache binary")
  else()
  unset(NDK_CCACHE CACHE)
  endif()
unset(_ndk_ccache)

# Setup the cross-compiler
if(NOT CMAKE_C_COMPILER)
  if(NDK_CCACHE)
    set(CMAKE_C_COMPILER   "${NDK_CCACHE}" CACHE PATH "ccache as C compiler")
    set(CMAKE_CXX_COMPILER "${NDK_CCACHE}" CACHE PATH "ccache as C++ compiler")
    if(ANDROID_COMPILER_IS_CLANG)
    set(CMAKE_C_COMPILER_ARG1   "${ANDROID_CLANG_TOOLCHAIN_ROOT}/bin/${_clang_name}${TOOL_OS_SUFFIX}"   CACHE PATH "C compiler")
    set(CMAKE_CXX_COMPILER_ARG1 "${ANDROID_CLANG_TOOLCHAIN_ROOT}/bin/${_clang_name}++${TOOL_OS_SUFFIX}" CACHE PATH "C++ compiler")
    else()
    set(CMAKE_C_COMPILER_ARG1   "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-gcc${TOOL_OS_SUFFIX}" CACHE PATH "C compiler")
    set(CMAKE_CXX_COMPILER_ARG1 "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-g++${TOOL_OS_SUFFIX}" CACHE PATH "C++ compiler")
    endif()
  else()
    if(ANDROID_COMPILER_IS_CLANG)
    set(CMAKE_C_COMPILER   "${ANDROID_CLANG_TOOLCHAIN_ROOT}/bin/${_clang_name}${TOOL_OS_SUFFIX}"   CACHE PATH "C compiler")
    set(CMAKE_CXX_COMPILER "${ANDROID_CLANG_TOOLCHAIN_ROOT}/bin/${_clang_name}++${TOOL_OS_SUFFIX}" CACHE PATH "C++ compiler")
    else()
    set(CMAKE_C_COMPILER   "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-gcc${TOOL_OS_SUFFIX}"    CACHE PATH "C compiler")
    set(CMAKE_CXX_COMPILER "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-g++${TOOL_OS_SUFFIX}"    CACHE PATH "C++ compiler")
    endif()
  endif()
  set(CMAKE_ASM_COMPILER "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-gcc${TOOL_OS_SUFFIX}"     CACHE PATH "assembler")
  set(CMAKE_STRIP        "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-strip${TOOL_OS_SUFFIX}"   CACHE PATH "strip")
  set(CMAKE_AR           "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-ar${TOOL_OS_SUFFIX}"      CACHE PATH "archive")
  set(CMAKE_LINKER       "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-ld${TOOL_OS_SUFFIX}"      CACHE PATH "linker")
  set(CMAKE_NM           "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-nm${TOOL_OS_SUFFIX}"      CACHE PATH "nm")
  set(CMAKE_OBJCOPY      "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-objcopy${TOOL_OS_SUFFIX}" CACHE PATH "objcopy")
  set(CMAKE_OBJDUMP      "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-objdump${TOOL_OS_SUFFIX}" CACHE PATH "objdump")
  set(CMAKE_RANLIB       "${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-ranlib${TOOL_OS_SUFFIX}"  CACHE PATH "ranlib")
endif()

set(_CMAKE_TOOLCHAIN_PREFIX "${ANDROID_TOOLCHAIN_MACHINE_NAME}-")
if(CMAKE_VERSION VERSION_LESS 2.8.5)
  set(CMAKE_ASM_COMPILER_ARG1 "-c")
endif()
if(APPLE)
  find_program(CMAKE_INSTALL_NAME_TOOL NAMES install_name_tool)
  if(NOT CMAKE_INSTALL_NAME_TOOL)
    message(FATAL_ERROR "Could not find install_name_tool, please check your installation.")
  endif()
  mark_as_advanced(CMAKE_INSTALL_NAME_TOOL)
endif()

# Force set compilers because standard identification works badly for us
include(CMakeForceCompiler)
CMAKE_FORCE_C_COMPILER("${CMAKE_C_COMPILER}" GNU)
if(ANDROID_COMPILER_IS_CLANG)
  set(CMAKE_C_COMPILER_ID Clang)
endif()
set(CMAKE_C_PLATFORM_ID Linux)
set(CMAKE_C_SIZEOF_DATA_PTR 4)
set(CMAKE_C_HAS_ISYSROOT 1)
set(CMAKE_C_COMPILER_ABI ELF)
CMAKE_FORCE_CXX_COMPILER("${CMAKE_CXX_COMPILER}" GNU)
if(ANDROID_COMPILER_IS_CLANG)
  set(CMAKE_CXX_COMPILER_ID Clang)
endif()
set(CMAKE_CXX_PLATFORM_ID Linux)
set(CMAKE_CXX_SIZEOF_DATA_PTR 4)
set(CMAKE_CXX_HAS_ISYSROOT 1)
set(CMAKE_CXX_COMPILER_ABI ELF)
set(CMAKE_CXX_SOURCE_FILE_EXTENSIONS cc cp cxx cpp CPP c++ C)
# Force ASM compiler (required for CMake < 2.8.5)
set(CMAKE_ASM_COMPILER_ID_RUN TRUE)
set(CMAKE_ASM_COMPILER_ID GNU)
set(CMAKE_ASM_COMPILER_WORKS TRUE)
set(CMAKE_ASM_COMPILER_FORCED TRUE)
set(CMAKE_COMPILER_IS_GNUASM 1)
set(CMAKE_ASM_SOURCE_FILE_EXTENSIONS s S asm)

# Flags and definitions
remove_definitions(-DANDROID)
add_definitions(-DANDROID)

if(ANDROID_SYSROOT MATCHES "[ ;\"]")
  set(ANDROID_CXX_FLAGS "--sysroot=\"${ANDROID_SYSROOT}\"")
  if(NOT _CMAKE_IN_TRY_COMPILE)
    # Quotes will break try_compile and compiler identification
    message(WARNING "Your Android system root has non-alphanumeric symbols. It can break compiler features detection and the whole build.")
  endif()
else()
  set(ANDROID_CXX_FLAGS "--sysroot=${ANDROID_SYSROOT}")
endif()

# NDK flags
if(ARMEABI OR ARMEABI_V7A)
  set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -fpic -funwind-tables")
  if(NOT ANDROID_FORCE_ARM_BUILD AND NOT ARMEABI_V6)
    set(ANDROID_CXX_FLAGS_RELEASE "-mthumb -fomit-frame-pointer -fno-strict-aliasing")
    set(ANDROID_CXX_FLAGS_DEBUG   "-marm -fno-omit-frame-pointer -fno-strict-aliasing")
    if(NOT ANDROID_COMPILER_IS_CLANG)
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -finline-limit=64")
    endif()
  else()
    # Always compile ARMEABI_V6 in arm mode; otherwise there is no difference from ARMEABI
    set(ANDROID_CXX_FLAGS_RELEASE "-marm -fomit-frame-pointer -fstrict-aliasing")
    set(ANDROID_CXX_FLAGS_DEBUG   "-marm -fno-omit-frame-pointer -fno-strict-aliasing")
    if(NOT ANDROID_COMPILER_IS_CLANG)
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -funswitch-loops -finline-limit=300")
    endif()
  endif()
elseif(X86)
  set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -funwind-tables")
  if(NOT ANDROID_COMPILER_IS_CLANG)
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -funswitch-loops -finline-limit=300")
  else()
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -fPIC")
  endif()
  set(ANDROID_CXX_FLAGS_RELEASE "-fomit-frame-pointer -fstrict-aliasing")
  set(ANDROID_CXX_FLAGS_DEBUG   "-fno-omit-frame-pointer -fno-strict-aliasing")
elseif(MIPS)
  set(ANDROID_CXX_FLAGS         "${ANDROID_CXX_FLAGS} -fpic -fno-strict-aliasing -finline-functions -ffunction-sections -funwind-tables -fmessage-length=0")
  set(ANDROID_CXX_FLAGS_RELEASE "-fomit-frame-pointer")
  set(ANDROID_CXX_FLAGS_DEBUG   "-fno-omit-frame-pointer")
  if(NOT ANDROID_COMPILER_IS_CLANG)
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -fno-inline-functions-called-once -fgcse-after-reload -frerun-cse-after-loop -frename-registers")
    set(ANDROID_CXX_FLAGS_RELEASE "${ANDROID_CXX_FLAGS_RELEASE} -funswitch-loops -finline-limit=300")
  endif()
elseif()
  set(ANDROID_CXX_FLAGS_RELEASE "")
  set(ANDROID_CXX_FLAGS_DEBUG   "")
endif()

set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -fsigned-char") # Good/necessary when porting desktop libraries

if(NOT X86 AND NOT ANDROID_COMPILER_IS_CLANG)
  set(ANDROID_CXX_FLAGS "-Wno-psabi ${ANDROID_CXX_FLAGS}")
endif()

if(NOT ANDROID_COMPILER_VERSION VERSION_LESS "4.6")
  set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -no-canonical-prefixes") # See https://android-review.googlesource.com/#/c/47564/
endif()

# ABI-specific flags
if(ARMEABI_V7A)
  set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -march=armv7-a -mfloat-abi=softfp")
  if(NEON)
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -mfpu=neon")
  elseif(VFPV3)
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -mfpu=vfpv3")
  else()
    set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -mfpu=vfpv3-d16")
  endif()
elseif(ARMEABI_V6)
  set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -march=armv6 -mfloat-abi=softfp -mfpu=vfp") # vfp == vfpv2
elseif(ARMEABI)
  set(ANDROID_CXX_FLAGS "${ANDROID_CXX_FLAGS} -march=armv5te -mtune=xscale -msoft-float")
endif()

# STL
if(EXISTS "${__libstl}" OR EXISTS "${__libsupcxx}")
  if(ANDROID_STL MATCHES "gnustl")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_C_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_CXX_CREATE_SHARED_MODULE  "<CMAKE_C_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_CXX_LINK_EXECUTABLE       "<CMAKE_C_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
  else()
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_CXX_CREATE_SHARED_MODULE  "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_CXX_LINK_EXECUTABLE       "<CMAKE_CXX_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
  endif()
  if (X86 AND ANDROID_STL MATCHES "gnustl" AND ANDROID_NDK_RELEASE STREQUAL "r6")
    # workaround "undefined reference to `__dso_handle'" problem
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} \"${ANDROID_SYSROOT}/usr/lib/crtbegin_so.o\"")
    set(CMAKE_CXX_CREATE_SHARED_MODULE  "${CMAKE_CXX_CREATE_SHARED_MODULE} \"${ANDROID_SYSROOT}/usr/lib/crtbegin_so.o\"")
  endif()
  if(EXISTS "${__libstl}")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} \"${__libstl}\"")
    set(CMAKE_CXX_CREATE_SHARED_MODULE  "${CMAKE_CXX_CREATE_SHARED_MODULE} \"${__libstl}\"")
    set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} \"${__libstl}\"")
  endif()
  if(EXISTS "${__libsupcxx}")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} \"${__libsupcxx}\"")
    set(CMAKE_CXX_CREATE_SHARED_MODULE  "${CMAKE_CXX_CREATE_SHARED_MODULE} \"${__libsupcxx}\"")
    set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} \"${__libsupcxx}\"")
    # C objects:
    set(CMAKE_C_CREATE_SHARED_LIBRARY "<CMAKE_C_COMPILER> <CMAKE_SHARED_LIBRARY_C_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_C_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_C_CREATE_SHARED_MODULE  "<CMAKE_C_COMPILER> <CMAKE_SHARED_LIBRARY_C_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_C_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_C_LINK_EXECUTABLE       "<CMAKE_C_COMPILER> <FLAGS> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
    set(CMAKE_C_CREATE_SHARED_LIBRARY "${CMAKE_C_CREATE_SHARED_LIBRARY} \"${__libsupcxx}\"")
    set(CMAKE_C_CREATE_SHARED_MODULE  "${CMAKE_C_CREATE_SHARED_MODULE} \"${__libsupcxx}\"")
    set(CMAKE_C_LINK_EXECUTABLE       "${CMAKE_C_LINK_EXECUTABLE} \"${__libsupcxx}\"")
  endif()
  if(ANDROID_STL MATCHES "gnustl")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} -lm")
    set(CMAKE_CXX_CREATE_SHARED_MODULE  "${CMAKE_CXX_CREATE_SHARED_MODULE} -lm")
    set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} -lm")
  endif()
endif()

# Variables controlling optional build flags
if (ANDROID_NDK_RELEASE STRLESS "r7")
  # libGLESv2.so in NDK's prior to r7 refers to missing external symbols.
  # So this flag option is required for all projects using OpenGL from native.
  remake_android_var(ANDROID_SO_UNDEFINED                      VALUES ON)
else()
  remake_android_var(ANDROID_SO_UNDEFINED                      VALUES OFF)
endif()
remake_android_var(ANDROID_NO_UNDEFINED OBSOLETE_NO_UNDEFINED VALUES ON)
remake_android_var(ANDROID_FUNCTION_LEVEL_LINKING             VALUES ON)
remake_android_var(ANDROID_GOLD_LINKER                        VALUES ON)
remake_android_var(ANDROID_NOEXECSTACK                        VALUES ON)
remake_android_var(ANDROID_RELRO                              VALUES ON)

set(ANDROID_NO_UNDEFINED           ${ANDROID_NO_UNDEFINED}           CACHE BOOL "Show all undefined symbols as linker errors")
set(ANDROID_SO_UNDEFINED           ${ANDROID_SO_UNDEFINED}           CACHE BOOL "Allows or disallows undefined symbols in shared libraries")
set(ANDROID_FUNCTION_LEVEL_LINKING ${ANDROID_FUNCTION_LEVEL_LINKING} CACHE BOOL "Allows or disallows undefined symbols in shared libraries")
set(ANDROID_GOLD_LINKER            ${ANDROID_GOLD_LINKER}            CACHE BOOL "Enables gold linker (only avaialble for NDK r8b for ARM and x86 architectures on linux-86 and darwin-x86 hosts)")
set(ANDROID_NOEXECSTACK            ${ANDROID_NOEXECSTACK}            CACHE BOOL "Allows or disallows undefined symbols in shared libraries")
set(ANDROID_RELRO                  ${ANDROID_RELRO}                  CACHE BOOL "Enables RELRO - a memory corruption mitigation technique")
mark_as_advanced(ANDROID_NO_UNDEFINED ANDROID_SO_UNDEFINED ANDROID_FUNCTION_LEVEL_LINKING ANDROID_GOLD_LINKER ANDROID_NOEXECSTACK ANDROID_RELRO)

# Linker flags
set(ANDROID_LINKER_FLAGS "")

if(ARMEABI_V7A)
  # This is *required* to use the following linker flags that routes around
  # a CPU bug in some Cortex-A8 implementations:
  set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,--fix-cortex-a8")
endif()

if(ANDROID_NO_UNDEFINED)
  set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,--no-undefined")
endif()

if(ANDROID_SO_UNDEFINED)
  set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,-allow-shlib-undefined")
endif()

if(ANDROID_FUNCTION_LEVEL_LINKING)
  set(ANDROID_CXX_FLAGS    "${ANDROID_CXX_FLAGS} -fdata-sections -ffunction-sections")
  set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,--gc-sections")
endif()

if(ANDROID_COMPILER_VERSION VERSION_EQUAL "4.6")
  if(ANDROID_GOLD_LINKER AND (CMAKE_HOST_UNIX OR ANDROID_NDK_RELEASE STRGREATER "r8b") AND (ARMEABI OR ARMEABI_V7A OR X86))
    set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -fuse-ld=gold")
  elseif(ANDROID_NDK_RELEASE STRGREATER "r8b")
    set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -fuse-ld=bfd")
  elseif(ANDROID_NDK_RELEASE STREQUAL "r8b" AND ARMEABI AND NOT _CMAKE_IN_TRY_COMPILE)
    message(WARNING "The default bfd linker from arm GCC 4.6 toolchain can fail with 'unresolvable R_ARM_THM_CALL relocation' error message. See https://code.google.com/p/android/issues/detail?id=35342
    On Linux and OS X host platform you can workaround this problem using gold linker (default).
    Rerun cmake with -DANDROID_GOLD_LINKER=ON option in case of problems.
  ")
  endif()
endif() # Version 4.6

if(ANDROID_NOEXECSTACK)
  if(ANDROID_COMPILER_IS_CLANG)
    set(ANDROID_CXX_FLAGS    "${ANDROID_CXX_FLAGS} -Xclang -mnoexecstack")
  else()
    set(ANDROID_CXX_FLAGS    "${ANDROID_CXX_FLAGS} -Wa,--noexecstack")
  endif()
  set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,-z,noexecstack")
endif()

if(ANDROID_RELRO)
  set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,-z,relro -Wl,-z,now")
endif()

if(ANDROID_COMPILER_IS_CLANG)
  set(ANDROID_CXX_FLAGS "-Qunused-arguments ${ANDROID_CXX_FLAGS}")
  if(ARMEABI_V7A AND NOT ANDROID_FORCE_ARM_BUILD)
    set(ANDROID_CXX_FLAGS_RELEASE "-target thumbv7-none-linux-androideabi ${ANDROID_CXX_FLAGS_RELEASE}")
    set(ANDROID_CXX_FLAGS_DEBUG   "-target ${ANDROID_LLVM_TRIPLE} ${ANDROID_CXX_FLAGS_DEBUG}")
  else()
    set(ANDROID_CXX_FLAGS "-target ${ANDROID_LLVM_TRIPLE} ${ANDROID_CXX_FLAGS}")
  endif()
  if(BUILD_WITH_ANDROID_NDK)
    set(ANDROID_CXX_FLAGS "-gcc-toolchain ${ANDROID_TOOLCHAIN_ROOT} ${ANDROID_CXX_FLAGS}")
  endif()
endif()

# Cache flags
set(CMAKE_CXX_FLAGS           ""                        CACHE STRING "c++ flags")
set(CMAKE_C_FLAGS             ""                        CACHE STRING "c flags")
set(CMAKE_CXX_FLAGS_RELEASE   "-O3 -DNDEBUG"            CACHE STRING "c++ Release flags")
set(CMAKE_C_FLAGS_RELEASE     "-O3 -DNDEBUG"            CACHE STRING "c Release flags")
set(CMAKE_CXX_FLAGS_DEBUG     "-O0 -g -DDEBUG -D_DEBUG" CACHE STRING "c++ Debug flags")
set(CMAKE_C_FLAGS_DEBUG       "-O0 -g -DDEBUG -D_DEBUG" CACHE STRING "c Debug flags")
set(CMAKE_SHARED_LINKER_FLAGS ""                        CACHE STRING "shared linker flags")
set(CMAKE_MODULE_LINKER_FLAGS ""                        CACHE STRING "module linker flags")
set(CMAKE_EXE_LINKER_FLAGS    "-Wl,-z,nocopyreloc"      CACHE STRING "executable linker flags")

# Put flags to cache (for debug purpose only)
set(ANDROID_CXX_FLAGS         "${ANDROID_CXX_FLAGS}"         CACHE INTERNAL "Android specific c/c++ flags")
set(ANDROID_CXX_FLAGS_RELEASE "${ANDROID_CXX_FLAGS_RELEASE}" CACHE INTERNAL "Android specific c/c++ Release flags")
set(ANDROID_CXX_FLAGS_DEBUG   "${ANDROID_CXX_FLAGS_DEBUG}"   CACHE INTERNAL "Android specific c/c++ Debug flags")
set(ANDROID_LINKER_FLAGS      "${ANDROID_LINKER_FLAGS}"      CACHE INTERNAL "Android specific c/c++ linker flags")

# Finish flags
set(CMAKE_CXX_FLAGS           "${ANDROID_CXX_FLAGS} ${CMAKE_CXX_FLAGS}")
set(CMAKE_C_FLAGS             "${ANDROID_CXX_FLAGS} ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE   "${ANDROID_CXX_FLAGS_RELEASE} ${CMAKE_CXX_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_RELEASE     "${ANDROID_CXX_FLAGS_RELEASE} ${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_DEBUG     "${ANDROID_CXX_FLAGS_DEBUG} ${CMAKE_CXX_FLAGS_DEBUG}")
set(CMAKE_C_FLAGS_DEBUG       "${ANDROID_CXX_FLAGS_DEBUG} ${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_SHARED_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS}")
set(CMAKE_MODULE_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} ${CMAKE_MODULE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS    "${ANDROID_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}")

if(MIPS AND BUILD_WITH_ANDROID_NDK AND ANDROID_NDK_RELEASE STREQUAL "r8")
  set(CMAKE_SHARED_LINKER_FLAGS "-Wl,-T,${ANDROID_NDK}/toolchains/${ANDROID_GCC_TOOLCHAIN_NAME}/mipself.xsc ${CMAKE_SHARED_LINKER_FLAGS}")
  set(CMAKE_MODULE_LINKER_FLAGS "-Wl,-T,${ANDROID_NDK}/toolchains/${ANDROID_GCC_TOOLCHAIN_NAME}/mipself.xsc ${CMAKE_MODULE_LINKER_FLAGS}")
  set(CMAKE_EXE_LINKER_FLAGS    "-Wl,-T,${ANDROID_NDK}/toolchains/${ANDROID_GCC_TOOLCHAIN_NAME}/mipself.x ${CMAKE_EXE_LINKER_FLAGS}")
endif()

# Configure rtti
if(DEFINED ANDROID_RTTI AND ANDROID_STL_FORCE_FEATURES)
  if(ANDROID_RTTI)
    set(CMAKE_CXX_FLAGS "-frtti ${CMAKE_CXX_FLAGS}")
  else()
    set(CMAKE_CXX_FLAGS "-fno-rtti ${CMAKE_CXX_FLAGS}")
  endif()
endif()

# Configure exceptios
if(DEFINED ANDROID_EXCEPTIONS AND ANDROID_STL_FORCE_FEATURES)
  if(ANDROID_EXCEPTIONS)
    set(CMAKE_CXX_FLAGS "-fexceptions ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "-fexceptions ${CMAKE_C_FLAGS}")
  else()
    set(CMAKE_CXX_FLAGS "-fno-exceptions ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "-fno-exceptions ${CMAKE_C_FLAGS}")
  endif()
endif()

# Global includes and link directories
include_directories(SYSTEM "${ANDROID_SYSROOT}/usr/include" ${ANDROID_STL_INCLUDE_DIRS} ${NECESSITAS_INCLUDE_DIRS})
link_directories("${CMAKE_INSTALL_PREFIX}/libs/${ANDROID_NDK_ABI_NAME}" ${NECESSITAS_LINK_DIRS})

# setup output directories
set(LIBRARY_OUTPUT_PATH_ROOT ${CMAKE_SOURCE_DIR} CACHE PATH "root for library output, set this to change where android libs are installed to")
set(CMAKE_INSTALL_PREFIX "${ANDROID_TOOLCHAIN_ROOT}/user" CACHE STRING "path for installing")

if(NOT _CMAKE_IN_TRY_COMPILE)
  if(EXISTS "${CMAKE_SOURCE_DIR}/jni/CMakeLists.txt")
    set(EXECUTABLE_OUTPUT_PATH "${LIBRARY_OUTPUT_PATH_ROOT}/bin/${ANDROID_NDK_ABI_NAME}" CACHE PATH "Output directory for applications")
  else()
    set(EXECUTABLE_OUTPUT_PATH "${LIBRARY_OUTPUT_PATH_ROOT}/bin" CACHE PATH "Output directory for applications")
  endif()
  set(LIBRARY_OUTPUT_PATH "${LIBRARY_OUTPUT_PATH_ROOT}/libs/${ANDROID_NDK_ABI_NAME}" CACHE PATH "path for android libs")
endif()

# Set these global flags for cmake client scripts to change behavior
set(ANDROID True)
set(BUILD_ANDROID True)

# Where is the target environment
set(CMAKE_FIND_ROOT_PATH "${ANDROID_TOOLCHAIN_ROOT}/bin" "${ANDROID_TOOLCHAIN_ROOT}/${ANDROID_TOOLCHAIN_MACHINE_NAME}" "${ANDROID_SYSROOT}" "${CMAKE_INSTALL_PREFIX}" "${CMAKE_INSTALL_PREFIX}/share" "${NECESSITAS_TOOLCHAIN_ROOT}")
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH}" "${LIBRARY_OUTPUT_PATH}")

# Only search for libraries and includes in the ndk toolchain
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Find packages installed on the host OS.
macro(remake_android_find_package)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
  if(CMAKE_HOST_WIN32)
    SET(WIN32 1)
    SET(UNIX)
  elseif(CMAKE_HOST_APPLE)
    SET(APPLE 1)
    SET(UNIX)
  endif()
  find_package(${ARGN})
  SET(WIN32)
  SET(APPLE)
  SET(UNIX 1)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endmacro()

# Find programs installed on the host OS.
macro(remake_android_find_program)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
  if(CMAKE_HOST_WIN32)
    SET(WIN32 1)
    SET(UNIX)
  elseif(CMAKE_HOST_APPLE)
    SET(APPLE 1)
    SET(UNIX)
  endif()
  find_program(${ARGN})
  SET(WIN32)
  SET(APPLE)
  SET(UNIX 1)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endmacro()

macro(remake_android_get_abi TOOLCHAIN_FLAG VAR)
  if("${TOOLCHAIN_FLAG}" STREQUAL "ARMEABI")
    set(${VAR} "armeabi")
  elseif("${TOOLCHAIN_FLAG}" STREQUAL "ARMEABI_V7A")
    set(${VAR} "armeabi-v7a")
  elseif("${TOOLCHAIN_FLAG}" STREQUAL "X86")
    set(${VAR} "x86")
  elseif("${TOOLCHAIN_FLAG}" STREQUAL "MIPS")
    set(${VAR} "mips")
  else()
    set(${VAR} "unknown")
  endif()
endmacro()

# Export toolchain settings for the try_compile() command
if(NOT PROJECT_NAME STREQUAL "CMAKE_TRY_COMPILE")
  set(__toolchain_config "")
  foreach(__var NDK_CCACHE  LIBRARY_OUTPUT_PATH_ROOT  ANDROID_FORBID_SYGWIN  ANDROID_SET_OBSOLETE_VARIABLES
                  ANDROID_NDK_HOST_X64
                  ANDROID_NDK
                  ANDROID_STANDALONE_TOOLCHAIN
                  ANDROID_TOOLCHAIN_NAME
                  ANDROID_ABI
                  ANDROID_NATIVE_API_LEVEL
                  ANDROID_STL
                  ANDROID_STL_FORCE_FEATURES
                  ANDROID_FORCE_ARM_BUILD
                  ANDROID_NO_UNDEFINED
                  ANDROID_SO_UNDEFINED
                  ANDROID_FUNCTION_LEVEL_LINKING
                  ANDROID_GOLD_LINKER
                  ANDROID_NOEXECSTACK
                  ANDROID_RELRO
                )
    if(DEFINED ${__var})
    if("${__var}" MATCHES " ")
      set(__toolchain_config "${__toolchain_config}set(${__var} \"${${__var}}\" CACHE INTERNAL \"\")\n")
    else()
      set(__toolchain_config "${__toolchain_config}set(${__var} ${${__var}} CACHE INTERNAL \"\")\n")
    endif()
    endif()
  endforeach()
  file(WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/android.toolchain.config.cmake" "${__toolchain_config}")
  unset(__toolchain_config)
endif()

# Set some obsolete variables for backward compatibility
set(ANDROID_SET_OBSOLETE_VARIABLES ON CACHE BOOL "Define obsolete Andrid-specific cmake variables")
mark_as_advanced(ANDROID_SET_OBSOLETE_VARIABLES)
if(ANDROID_SET_OBSOLETE_VARIABLES)
  set(ANDROID_API_LEVEL ${ANDROID_NATIVE_API_LEVEL})
  set(ARM_TARGET "${ANDROID_ABI}")
  set(ARMEABI_NDK_NAME "${ANDROID_NDK_ABI_NAME}")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  file(COPY ${ANDROID_NDK}/prebuilt/android-${ANDROID_ARCH_NAME}/gdbserver/gdbserver DESTINATION ${LIBRARY_OUTPUT_PATH})
  file(COPY ${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_MACHINE_NAME}-gdb${TOOL_OS_SUFFIX} DESTINATION ${LIBRARY_OUTPUT_PATH_ROOT}/debug)
  file(RENAME ${LIBRARY_OUTPUT_PATH_ROOT}/debug/${ANDROID_TOOLCHAIN_MACHINE_NAME}-gdb${TOOL_OS_SUFFIX} ${LIBRARY_OUTPUT_PATH_ROOT}/debug/gdbclient)
endif(CMAKE_BUILD_TYPE STREQUAL "Debug")
