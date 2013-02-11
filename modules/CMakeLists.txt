remake_file_configure(*.remake OUTPUT remake_version_module)
remake_add_files(INSTALL ${CMAKE_ROOT}/Modules *.cmake
  ${remake_version_module})
