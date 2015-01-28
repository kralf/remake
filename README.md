# ReMake

## Synopsis

A set of CMake macros for restructuring GNU Automake/Autoconf projects.

**Author(s):** Ralf Kaestner, Dizan Vasquez

**Maintainer:** Ralf Kaestner <ralf.kaestner@gmail.com>

**Licsense:** GNU Lesser General Public License (LGPL)

**Operating system(s):** Debian-based Linux

**Package PPA:** ppa:ethz-asl/build-essential

## Description

ReMake provides a set of CMake macros that have originally been written to
facilitate the restructuring of GNU Automake/Autoconf projects. In the course
of continuous development, however, ReMake grew into a vast collection of
highly useful CMake macros for a variety of different build system applications.

ReMake is structured into several modules. This is a brief overview of their
core purposes:

* **ReMake** - ReMake convenience macros

  The most widely used ReMake macros have been summarized into a reduced
  set of short-named macros for flexible and convenient use.

* **ReMakeBranch** - ReMake branch macros

  Branching is a central concept in ReMake. A branch is defined along
  with a list of dependencies that is automatically resolved by ReMake.

* **ReMakeComponent** - ReMake component macros

  The ReMake component module provides basic functionalities for managing
  component-based project structures.

* **ReMakeDebian** - ReMake Debian macros

  The ReMake Debian macros provide abstracted access to Debian-specific
  build system facilities.

* **ReMakeDistribute** - ReMake distribution macros

  The ReMake distribution macros facilitate automated distribution of
  a ReMake project.

* **ReMakeDoc** - ReMake documentation macros

  The ReMake documentation module has been designed for simple and 
  transparent intergration of project documentation tasks with CMake.

* **ReMakeFile** - ReMake file macros

  The ReMake file macros are a set of helper macros to simplify
  file operations in ReMake.

* **ReMakeFind** - ReMake package and file discovery macros

  The ReMake package and file discovery macros provide a useful abstraction
  to CMake's native find functionalities.

* **ReMakeGenerate** - ReMake code generation macros

  The ReMake code generation macros define additional targets for the
  automated generation of source code.

* **ReMakeGit** - ReMake Git macros

  The ReMake Git module provides useful tools for Git-based projects.

* **ReMakeList** - ReMake list macros

  The ReMake list macros are a set of helper macros to simplify
  operations over lists in ReMake.

* **ReMakePack** - ReMake packaging macros

  The ReMake packaging macros have been designed to provide simple and
  transparent package generation using CMake's CPack module.

* **ReMakePkgConfig** - ReMake pkg-config support

  The ReMake pkg-config macros provide support for generating pkg-config
  files from ReMake projects.

* **ReMakePrivate** - ReMake private macros

  ReMake's private module provides basic helper macros that are used
  throughout the ReMake module infrastructure. As the name suggest,
  these macros are considered to be private to ReMake.

* **RemakeProject** - ReMake project macros

   The ReMake project macros are required by most processing macros in
   ReMake. They maintain the environment necessary for initializing default
   values throughout the modules, thus introducing convenience and
   conventions into ReMake's naming schemes.

* **ReMakePython** - ReMake Python macros

  The ReMake Python macros provide convenient targets for the distribution
  of Python modules and extensions using generators such as the Simplified
  Wrapper and Interface Generator (SWIG).

* **ReMakeQt3** - ReMake Qt3 macros

  The ReMake Qt3 macros provide seamless integration of Qt3 meta-object
  processing with ReMake build targets.

* **ReMakeQt4** - ReMake Qt4 macros

  The ReMake Qt4 macros provide seamless integration of Qt4 meta-object
  and user interface file processing with ReMake build targets.

* **ReMakeRecurse** - ReMake multi-project recursion macros

  The ReMake recursion macros extend the CMake build system facilities
  into multi-project environments. Recursion support exists for selected
  build system types.

* **ReMakeROS** - ReMake ROS build macros

  The ReMake ROS build macros provide access to the ROS build system
  configuration without requirement for the ROS CMake API. Note that
  all ROS environment variables should be initialized by sourcing the
  corresponding ROS setup script prior to calling CMake.

* **ReMakeSVN** - ReMake Subversion macros

  The ReMake Subversion module provides useful tools for Subversion-based
  projects.

* **ReMakeTarget** - ReMake target macros

  The ReMake target module provides useful workarounds addressing some 
  grave CMake limitations. In CMake, top-level target definition only
  behaves correctly in the top-level source directory. The ReMake target 
  macros are specifically designed to also work in directories below the
  top-level.

* **ReMakeTest** - ReMake testing macros

  The ReMake testing module provides unit testing support.

* **ReMakeVersion** - ReMake version information

  The ReMake version module only holds the current version of ReMake.

It is important to note that, although modern CMake provides some of the ReMake
features in a very similar fashion, many of these features have already been
developed when CMake still suffered from serious limitations.

In its current version, ReMake requires CMake version 2.6.2 or higher. It
specifically targets projects which are intended to build on Debian-based
Linux platforms.

## Installation

### Installing from packages (recommended for Ubuntu LTS users)

The maintainers of this project provide binary packages for the latest Ubuntu
LTS releases and commonly used system architectures. To install these packages,
you may follow these instructions:

* Add the project PPA to your APT sources by issuing

  ```
  sudo add-apt-repository ppa:ethz-asl/build-essential
  ```

  on the command line

* To re-synchronize your package index files, run 

  ```
  sudo apt-get update
  ```

* Install all project packages and their dependencies through

  ```
  sudo apt-get install remake*
  ```

  or selected packages using your favorite package management tool

### Building from source

This project is inherently based on the CMake build system and bootstraps
itself using the ReMake macro extension.

#### Installing build dependencies

The build dependencies of this project are available from the standard
package repositories of recent Ubuntu LTS releases. To install them, simply
use the command

```
sudo apt-get install debhelper cmake groff
```

#### Building with CMake

This project can be built the traditional CMake way. Assuming that you have
cloned the project sources into `PROJECT_DIR`, a typical out-of-source build
might look like this:

* Create a build directory using 

  ```
  mkdir -p PROJECT_DIR/build
  ```

* Switch into the build directoy by 

  ```
  cd PROJECT_DIR/build
  ```

* In the build directory, run

  ```
  cmake PROJECT_DIR
  ```

  to configure the build

* Build and install the project using

  ```
  make packages_install
  ```

  (from packages on Debian-based Linux only) or

  ```
  make install
  ```

## API documentation

This project generates its API documentation from source. To access it, you
may either inspect the build directory tree after the project has been built
using `make` or install the documentation package through

```
sudo apt-get install remake-doc
```

## Feature requests and bug reports

If you would like to propose a feature for this project, please consider
contributing or send a feature request to the project authors. Bugs may be
reported through the project's issue page.

## Further reading

For additional information of the CMake build system, please refer to the
official [CMake documentation](http://www.cmake.org/documentation).
