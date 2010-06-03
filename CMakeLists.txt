cmake_minimum_required(VERSION 2.6.2)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/src)
include(ReMake)

remake_project(
  ReMake
  VERSION 0.2
  RELEASE beta
  SUMMARY "A set of CMake macros for restructuring GNU Automake/Autoconf projects."
  AUTHOR "Ralf Kaestner"
  AUTHOR "Dizan Vasquez"
  CONTACT "ralf.kaestner@gmail.com"
  HOME "http://aslforge.ethz.ch/projects/remake"
  LICENSE "GNU Lesser General Public License (LGPL)"
  INSTALL /usr
)

remake_doc(
  man INSTALL share
  ps
  html
)

remake_pack_deb(
  ARCH all
  "cmake (>= 2.6.2)"
)
remake_pack_deb(
  ARCH all
  COMPONENT doc
  DESCRIPTION "documentation"
)
