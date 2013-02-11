remake_find_package(Perl QUIET)
remake_find_executable(groff)
remake_find_executable(gzip)

if(PERL_FOUND AND GZIP_FOUND AND GROFF_FOUND)
  remake_file_configure(docs.conf.remake OUTPUT docs_config)
  remake_add_documentation(CUSTOM remake-gendocs
    ${REMAKE_PROJECT_SOURCE_DIR}/bin/gendocs -q -c ${docs_config}
      -t %TYPE% -o %OUTPUT% %INPUT%
    INPUT ${REMAKE_PROJECT_MODULE_DIR}/ReMake*.cmake
    TYPES man ascii utf8 html ps)
endif(PERL_FOUND AND GZIP_FOUND AND GROFF_FOUND)
