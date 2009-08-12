cmake_minimum_required(VERSION 2.6)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/src)
include(ReMake)

remake_project(
  ReMake
  0.1
  beta
  "A set of CMake macros for restructuring GNU Automake/Autoconf projects."
  "Ralf Kaestner"
  "ralf.kaestner@gmail.com"
  "http://aslforge.ethz.ch/projects/remake"
  "GNU Lesser General Public License (LGPL)"
  INSTALL /usr
)

remake_doc(
  man INSTALL share
  ps
  html
)

remake_pack_deb(ARCH all "cmake (>= 2.6)")
remake_pack_deb(ARCH all COMPONENT doc)
