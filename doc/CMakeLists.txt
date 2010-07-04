remake_find_package(Perl QUIET)
remake_find_executable(groff)
remake_find_file(IO/Compress/Gzip.pm PACKAGE zlib-perl PATHS /usr/share/perl5)

if(PERL_FOUND AND GROFF_FOUND AND ZLIB_PERL_FOUND)
  remake_file_configure(cdoc.conf.remake OUTPUT cdoc_config)
  remake_add_documentation(CUSTOM CDoc
    ${PERL_EXECUTABLE} cdoc.pl -q -c ${cdoc_config} -t %TYPE% -o %OUTPUT%
      %INPUT%
    INPUT ${REMAKE_PROJECT_SOURCE_DIR}/ReMake*.cmake
    TYPES man ascii utf8 html ps)
endif(PERL_FOUND AND GROFF_FOUND AND ZLIB_PERL_FOUND)
