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

### \brief ReMake branch macros
#   Branching is a central concept in ReMake. A branch is defined along
#   with a list of dependencies that is automatically resolved by ReMake.
#
#   Branching typically provides a maintenance solution to projects which
#   have grown complex. Defining stable, unstable, and development branches
#   of the source tree allows for selective builds with well-defined
#   interdependencies.
#
#   Note that dependent branches are generally required to be defined from
#   the same source tree directory, i.e. the same CMakeLists.txt file.

remake_set(REMAKE_BRANCH_TARGET_SUFFIX branch)

### \brief Define a ReMake branch.
#   This macro adds a ReMake branch along with a list of dependencies for
#   this branch. A branch is identified by its unique branch name. All source
#   files belonging to one and the same branch are required to reside under
#   the branch root directory. This root directory is automatically added
#   for CMake processing. The macro furthermore defines a build target named
#   ${BRANCH_NAME}_branch and a build option WITH_${BRANCH_NAME}_BRANCH for
#   the newly created branch.
#   \required[value] name The unique name the branch is identified by.
#   \optional[list] dep The list of branches the new branch depends on.
#   \optional[value] ROOT:dirname The branch root directory, defaults to the
#     filename conversion of the branch name.
#   \optional[option] OPTIONAL If this argument is present, the build option
#     of the created branch defaults to OFF.
macro(remake_branch branch_name)
  remake_arguments(PREFIX branch_ VAR ROOT OPTION OPTIONAL ARGN dependencies
    ${ARGN})
  remake_set(REMAKE_BRANCH_NAME ${branch_name})
  remake_file_name(REMAKE_BRANCH_FILENAME ${REMAKE_BRANCH_NAME})
  remake_set(REMAKE_BRANCH_ROOT ${branch_root}
    DEFAULT ${REMAKE_BRANCH_FILENAME})
  get_filename_component(REMAKE_BRANCH_ROOT ${REMAKE_BRANCH_ROOT} ABSOLUTE)
  remake_set(REMAKE_BRANCH_SUFFIX -${REMAKE_BRANCH_FILENAME})
  remake_set(REMAKE_BRANCH_DEPENDS ${branch_dependencies})

  remake_var_name(REMAKE_BRANCH_OPTION WITH ${REMAKE_BRANCH_NAME} BRANCH)
  if(branch_optional)
    remake_set(REMAKE_BRANCH_BUILD OFF)
  else(branch_optional)
    remake_set(REMAKE_BRANCH_BUILD ON)
  endif(branch_optional)

  remake_branch_set(BUILD ${REMAKE_BRANCH_BUILD} CACHE BOOL
    "Build ${REMAKE_BRANCH_NAME} branch.")
  remake_branch_get(BUILD OUTPUT REMAKE_BRANCH_BUILD)
  remake_branch_set(ROOT ${REMAKE_BRANCH_ROOT})
  remake_branch_set(SUFFIX ${REMAKE_BRANCH_SUFFIX})
  remake_branch_set(DEPENDS ${REMAKE_BRANCH_DEPENDS})

  if(REMAKE_BRANCH_BUILD)
    foreach(branch_dep ${REMAKE_BRANCH_DEPENDS})
      remake_branch_get(BUILD FROM ${branch_dep} OUTPUT branch_dep_build)
      if(NOT branch_dep_build)
        message(STATUS "Branch: ${REMAKE_BRANCH_NAME} depends on "
          "${branch_dep}, which is not going to be compiled!")
        remake_set(REMAKE_BRANCH_BUILD OFF)
        break()
      endif(NOT branch_dep_build)
    endforeach(branch_dep ${REMAKE_BRANCH_DEPENDS})
  endif(REMAKE_BRANCH_BUILD)

  if(REMAKE_BRANCH_BUILD)
    if(REMAKE_BRANCH_DEPENDS)
      string(REPLACE ";" ", " branch_depends "${REMAKE_BRANCH_DEPENDS}")
      message(STATUS "Branch: ${REMAKE_BRANCH_NAME}, depending on "
        "${branch_depends}")
    else(REMAKE_BRANCH_DEPENDS)
      message(STATUS "Branch: ${REMAKE_BRANCH_NAME}")
    endif(REMAKE_BRANCH_DEPENDS)

    remake_target_name(REMAKE_BRANCH_TARGET ${REMAKE_BRANCH_NAME}
      ${REMAKE_BRANCH_TARGET_SUFFIX})
    remake_target(${REMAKE_BRANCH_TARGET} ALL)
    remake_add_directories(${REMAKE_BRANCH_ROOT})
  endif(REMAKE_BRANCH_BUILD)
endmacro(remake_branch)

### \brief Define the value of a ReMake branch variable.
#   This macro defines a variable matching the ReMake naming conventions.
#   The variable name is automatically prefixed with an upper-case
#   conversion of the branch name. Thus, variables may appear in the cache
#   as ${BRANCH_NAME}_${VAR_NAME}. Additional arguments are passed on to
#   CMake's set() macro.
#   \required[value] variable The name of the branch variable to be defined.
#   \optional[list] arg The arguments to be passed on to CMake's set() macro.
macro(remake_branch_set branch_var)
  remake_var_name(branch_global_var ${REMAKE_BRANCH_NAME} BRANCH ${branch_var})
  remake_project_set(${branch_global_var} ${ARGN})
endmacro(remake_branch_set)

### \brief Retrieve the value of a ReMake branch variable.
#   This macro retrieves a variable matching the ReMake naming conventions.
#   Specifically, variables named ${BRANCH_NAME}_${VAR_NAME} can be found
#   by passing ${VAR_NAME} to this macro. By default, the macro defines
#   an output variable named ${VAR_NAME} which will be assigned the value of
#   the queried branch variable.
#   \required[value] variable The name of the branch variable to be retrieved.
#   \optional[value] FROM:branch The optional name of the branch to retrieve
#     the variable from, defaults to the name of the current branch.
#   \optional[value] OUTPUT:variable The optional name of an output variable
#     that will be assigned the value of the queried branch variable.
macro(remake_branch_get branch_var)
  remake_arguments(PREFIX branch_ VAR FROM VAR OUTPUT ${ARGN})
  remake_set(branch_from SELF DEFAULT ${REMAKE_BRANCH_NAME})

  remake_var_name(branch_global_var ${branch_from} BRANCH ${branch_var})
  if(branch_output)
    remake_project_get(${branch_global_var} OUTPUT ${branch_output})
  else(branch_output)
    remake_project_get(${branch_global_var} OUTPUT ${branch_var})
  endif(branch_output)
endmacro(remake_branch_get)

### \brief Add branch dependency for a library or executable target.
#   This macro adds a dependency for a library or executable target to
#   the ReMake branch build target. Therefor, the macro calls CMake's
#   add_dependencies().
#   \required[list] target The list of library or executable targets
#     for which a dependency is added to the ReMake branch build target.
macro(remake_branch_add_targets)
  remake_arguments(PREFIX branch_ ARGN targets ${ARGN})
  if(REMAKE_BRANCH_TARGET)
    foreach(branch_target ${branch_targets})
      add_dependencies(${REMAKE_BRANCH_TARGET}
        ${branch_target}${REMAKE_BRANCH_SUFFIX})
    endforeach(branch_target)
  endif(REMAKE_BRANCH_TARGET)
endmacro(remake_branch_add_targets)

### \brief Resolve link dependencies for a ReMake branch target.
#   This macro resolves the link dependencies for a ReMake branch target.
#   For a given target, it retrieves a list of libraries contained in all
#   branches for which dependencies have been defined.
#   \required[value] variable The name of a variable to be assigned the
#     result list of link libraries.
#   \optional[value] TARGET:target The optional name of the branch library
#     target for which the link dependencies are to be resolved. Passing a
#     target's name causes the macro to take care of equally-named targets
#     in branches with dependencies. In fact, a library target may thus
#     reside in several branches under the same name.
#   \required[list] lib The list of libraries to be linked into the target.
#     If a library name corresponds to a library target defined in any of
#     the branches, it is substituted for a list of branch libraries.
#     Otherwise, the library is assumed to be external and its name copied
#     to the result list.
macro(remake_branch_link branch_var)
  remake_arguments(PREFIX branch_ VAR TARGET ARGN libs ${ARGN})
  remake_branch_get(DEPENDS OUTPUT branch_depends)

  if(branch_target)
    remake_list_push(branch_libs ${branch_target})
    remake_set(branch_target_full ${branch_target}${REMAKE_BRANCH_SUFFIX})
  endif(branch_target)

  remake_set(${branch_var})
  foreach(branch_lib ${branch_libs})
    if(${branch_lib} STREQUAL "${branch_target}")
      remake_set(branch_external FALSE)
    else(${branch_lib} STREQUAL "${branch_target}")
      remake_set(branch_external TRUE)
    endif(${branch_lib} STREQUAL "${branch_target}")

    foreach(branch_dep ${REMAKE_BRANCH_NAME} ${branch_depends})
      remake_branch_get(SUFFIX FROM ${branch_dep} OUTPUT branch_dep_suffix)
      remake_set(branch_lib_full ${branch_lib}${branch_dep_suffix})

      if(TARGET ${branch_lib_full})
        remake_set(branch_external FALSE)
        if(NOT ${branch_lib_full} STREQUAL "${branch_target_full}")
          remake_list_push(${branch_var} ${branch_lib_full})
        endif(NOT ${branch_lib_full} STREQUAL "${branch_target_full}")
      endif(TARGET ${branch_lib_full})
    endforeach(branch_dep)
    if(branch_external)
      remake_list_push(${branch_var} ${branch_lib})
    endif(branch_external)
  endforeach(branch_lib)
endmacro(remake_branch_link)

### \brief Resolve include dependencies for a ReMake branch.
#   This macro resolves the include dependencies for a ReMake branch. It
#   retrieves a list of absolute-path directories contained in all branches
#   for which dependencies have been defined.
#   \required[value] variable The name of a variable to be assigned the
#     result list of include directories.
#   \optional[list] glob An optional list of glob expressions that are
#     resolved in order to find the directories to be added to the compiler's
#     include path. If a directory is located within any of the branches, it
#     is substituted for a list of branch directories. Otherwise, the directory
#     is assumed to be external and its name copied to the result list.
#   \optional[value] FROM:branch The optional branch name to include the
#     directories from. This argument is used for recursively resolving
#     include dependencies between branches and should not be passed directly
#     from a CMakeLists.txt file.
macro(remake_branch_include branch_var)
  remake_arguments(PREFIX branch_ ARGN globs VAR FROM ${ARGN})
  remake_set(branch_from SELF DEFAULT ${REMAKE_BRANCH_NAME})
  remake_branch_get(DEPENDS FROM ${branch_from} OUTPUT branch_depends)

  remake_set(${branch_var})
  foreach(branch_glob ${branch_globs})
    get_filename_component(branch_glob ${branch_glob} ABSOLUTE)
    file(RELATIVE_PATH branch_relative_glob ${REMAKE_BRANCH_ROOT}
      ${branch_glob})
    if(NOT branch_relative_glob MATCHES ^\\.\\.)
      remake_branch_get(ROOT FROM ${branch_from} OUTPUT branch_from_root)
      remake_file_glob(branch_dirs DIRECTORIES
        ${branch_from_root}/${branch_relative_glob})
      remake_list_push(${branch_var} ${branch_dirs})
    else(NOT branch_relative_glob MATCHES ^\\.\\.)
      remake_file_glob(branch_dirs DIRECTORIES ${branch_glob})
      remake_list_push(${branch_var} ${branch_dirs})
    endif(NOT branch_relative_glob MATCHES ^\\.\\.)
  endforeach(branch_glob)

  foreach(branch_dep ${branch_depends})
    remake_var_name(branch_dep_var ${branch_dep} branch_dep_dirs)
    remake_branch_include(${branch_dep_var} ${branch_globs}
      FROM ${branch_dep})
    remake_var_name(branch_dep_var ${branch_dep} branch_dep_dirs)
    remake_list_push(${branch_var} ${${branch_dep_var}})
  endforeach(branch_dep)
endmacro(remake_branch_include)
