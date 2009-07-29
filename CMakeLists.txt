cmake_minimum_required(VERSION 2.6)

include(sources/ReMake.cmake)

remake_project(
  ReMake
  0.1.0
  beta
  "A set of CMake macros for restructuring GNU Automake/Autoconf projects."
  "Ralf Kaestner"
  "ralf.kaestner@gmail.com"
  "http://aslforge.ethz.ch/projects/remake"
  GPL
)

add_subdirectory(sources)

remake_pack_deb(
  "cmake (>= 2.6)"
)
