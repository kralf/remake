remake_find_package(Perl QUIET)
if(PERL_FOUND)
  remake_file_configure(cman.*)
  remake_add_documentation(GROFF remake.* COMPONENT doc 
    PREPROCESS ${PERL_EXECUTABLE} cman.pl)
endif(PERL_FOUND)
