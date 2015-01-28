cmake_minimum_required(VERSION 2.6.2)

set(
  CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/modules
)

include(ReMake)

remake_project(
  ReMake
  VERSION 1:0.7.1
  RELEASE beta
  SUMMARY "A set of CMake macros for restructuring GNU Automake/Autoconf projects."
  AUTHOR "Ralf Kaestner"
  AUTHOR "Dizan Vasquez"
  CONTACT "ralf.kaestner@gmail.com"
  HOME "http://github.com/kralf/remake"
  LICENSE "GNU Lesser General Public License (LGPL)"
  INSTALL /usr
  README README.md
)

remake_add_directories(
  modules
  toolchains
)
remake_doc(
  man INSTALL share
  ps
  html
)

remake_pack_deb(
  ARCH all
  DEPENDS "cmake (>= 2.6.2)" groff
  RECOMMENDS pkg-config
)
remake_pack_deb(
  ARCH all
  COMPONENT doc
  DESCRIPTION "documentation"
)

remake_distribute_deb(
  DISTRIBUTION lucid
  SECTION devel
  UPLOAD ppa:kralf/asl
  DEPENDS groff
  PASS CMAKE_BUILD_TYPE REMAKE_GIT_REVISION
)
remake_distribute_deb(
  DISTRIBUTION precise
  SECTION devel
  UPLOAD ppa:kralf/asl
  DEPENDS groff
  PASS CMAKE_BUILD_TYPE REMAKE_GIT_REVISION
)
remake_distribute_deb(
  DISTRIBUTION trusty
  SECTION devel
  UPLOAD ppa:kralf/asl
  DEPENDS groff
  PASS CMAKE_BUILD_TYPE REMAKE_GIT_REVISION
)
