cmake_minimum_required(VERSION 2.6)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/src)
include(ReMake)

remake_project(
  ReMake
  0.1.0
  beta
  "A set of CMake macros for restructuring GNU Automake/Autoconf projects."
  "Ralf Kaestner"
  "ralf.kaestner@gmail.com"
  "http://aslforge.ethz.ch/projects/remake"
  GPL
  INSTALL /usr
)

remake_doc(
  "man pages"
  INSTALL share
)

remake_pack_deb(
  ARCH all
  "cmake (>= 2.6)"
)
