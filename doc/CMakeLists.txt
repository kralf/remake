remake_find_package(Perl QUIET)
remake_find_executable(groff)

if(PERL_FOUND AND GROFF_FOUND)
  remake_file_configure(cdoc.conf.remake OUTPUT cdoc_config)
  remake_add_documentation(CUSTOM CDoc
    ${PERL_EXECUTABLE} cdoc.pl -c ${cdoc_config} -t
    INPUT ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_SOURCE_DIR}
    TYPES man ascii utf8 html ps
    COMPONENT doc)
endif(PERL_FOUND AND GROFF_FOUND)
