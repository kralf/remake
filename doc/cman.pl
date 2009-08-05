#! /usr/bin/perl

use File::Find;
use File::Glob;
use File::Basename;
use File::Path;

require "cman";

sub write_man {
  my $file = shift;
  my $module = shift;
  my $brief = shift;
  my $description = shift;
  my @includes = @{(shift)};
  my @macros = @{(shift)};

  my $name = lc($project_name);
  if ($module) {
    $name .= "_".lc($module);
  }
  my @time = localtime();
  my $date = sprintf("%d-%02d-%02d", $time[5]+1900, $time[4], 
    $time[3]);

  my %references;
  for my $include (@includes) {
    if ($include =~ /$name_pattern/) {
      my $reference = lc($project_name)."_".lc($1)." ($man_extension)";
      %references = (%references, $include, $reference);
    }
  }

  my $doc;

  $doc .= ".TH \"".uc($name)."\" $man_extension \"$date\" ".
    "Linux \"$project_name Module Documentation\"\n";
  $doc .= ".SH NAME\n";
  my @macro_names;
  for my $macro (@macros) {
    @macro_names = (@macro_names, $macro->{name});
  }
  $doc .= join(", ", @macro_names);
  if ($brief) {
    $doc .= " - $brief";
  }
  $doc .= "\n";

  $doc .= ".SH SYNOPSIS\n";
  $include = $file;
  $include =~ s/$source_pattern//;
  $doc .= ".BR \"include($include)\"\n";
  $doc .= ".sp\n";
  for my $macro (@macros) {
    my $macro_signature;
    my @param_signatures;

    for my $param (@{$macro->{parameters}}) {
      my $param_signature;
      if ($param->{type} =~ /$list_pattern/) {
        $param_signature = "\" $param->{name}1 \" [\" $param->{name}2 \" ...]";
      }
      elsif ($param->{type} =~ /$option_pattern/) {
        $param_signature = "$param->{name}";
      }
      else {
        $param_signature = "\" ".$param->{name}." \"";
      }

      if ($param->{key}) {
        $param_signature = "$param->{key} $param_signature";
      }
      if ($param->{tag} =~ /$optional_pattern/) {
        $param_signature = "[$param_signature]";
      }

      @param_signatures = (@param_signatures, $param_signature);
    }
    $macro_signature = join(" ", @param_signatures);
    $macro->{signature} = $macro_signature;

    $doc .= ".BR \"$macro->{name}($macro->{signature})\"\n";
    $doc .= ".br\n";
  }

  $doc .= ".SH DESCRIPTION\n";
  if ($description) {
    $description =~ s/\n\n/\n.PP\n/g;
    $doc .= "$description\n";
  }
  else {
    $doc .= "$project_summary\n";
  }

  $doc .= ".SH MACROS\n";
  for my $macro (@macros) {
    $doc .= ".TP\n";
    $doc .= ".BI \"$macro->{name}($macro->{signature})\"\n";
    $doc .= ".RS\n";

    if ($macro->{brief}) {
      $doc .= "$macro->{brief}\n";
      $doc .= ".PP\n";
    }

    my $macro_description = $macro->{description};
    $macro_description =~ s/\n\n/\n.PP\n/g;
    $doc .= "$macro_description\n";

    for my $param (@{$macro->{parameters}}) {
      $doc .= ".TP\n";
      if ($param->{type} =~ /$list_pattern/) {
        $doc .= ".IR \"$param->{name}1 $param->{name}2 \"...\n";
      }
      elsif ($param->{type} =~ /$option_pattern/) {
        $doc .= "$param->{name}\n";
      }
      else {
        $doc .= ".IR \"$param->{name}\"\n";
      }
      $doc .= "$param->{description}\n";
    }

    $doc .= ".RE\n";
  }

  $doc .= ".SH AUTHOR\n";
  $doc .= "Written by $project_author.\n";  

  $doc .= ".SH REPORTING BUGS\n";
  $doc .= "Report bugs to <$project_contact>.\n";  

  $doc .= ".SH COPYRIGHT\n";
  $doc .= "$project_name is published under the $project_license.\n";

  if (%references) {
    $doc .= ".SH SEE ALSO\n";
    for my $reference (values %references) {
      $doc .= ".BR $reference\n";
    }
  }

  $doc .= ".SH COLOPHON\n";
  $doc .= "This page is part of version $project_version, ".
    "release $project_release of the $project_name project.\n";
  $doc .= ".PP\n";
  $doc .= "A description of the project, and information about ".
    "reporting bugs, can be found at ".$project_home.".\n";  

  for my $reference_key (keys %references) {
    my $reference_value = $references{$reference_key};
    $doc =~ s/\s*$reference_key\s*/\n.BR $reference_value\n/g;
  }

  mkpath($output_directory);
  my $filename = "$name.$man_extension";
  open(file, ">$output_directory/$filename") or 
    die("Error: Failed to write $output_directory/$filename!\n");
  print file $doc;
  close(file);
}

sub process_source {
  my $source_name = $File::Find::name;

  return unless -f $source_name;
  return unless $source_name  =~ /$source_pattern/;

  my $file = basename($source_name);
  my $module = $file;
  $module =~ s/$source_pattern//;
  my $module_brief;
  my $module_description;
  my @module_includes;
  my @macros;

  my $in_block = 0;
  my @block;

  my $source = "";
  open(source_file, $source_name);
  while (<source_file>) {
    $line = $_;

    if ($line =~ /$comment_pattern/) {
      my $comment = $1;
  
      if ($comment =~ /$block_pattern/) {
        $in_block = 1;
        @block = ($1);
      }
      elsif ($in_block) {
        @block = (@block, $1);
      }
      else {
        @block = ($comment);
      }
    }
    else {
      my $module;
      my $brief;
      my @macro_params = ();
      my @non_directive = ();

      my $in_parameter = 0;

      for my $block_line (@block) {
        if ($block_line =~ /$directive_pattern/) {
          my $directive = $1;
          my $arguments = $2;

          if ($directive =~ /$module_pattern/) {
            $module = $arguments;
          }
          if ($directive =~ /$brief_pattern/) {
            $brief = $arguments;
          }
          if ($directive =~ /$param_pattern/) {
            $in_parameter = 1;

            my $param_tag = $1;
            my $param_spec = $2;

            if ($arguments =~ /$param_arguments_pattern/) {
              my $param_key;
              my $param_name = $1;
              my $param_type = $value_pattern;
              my $param_description = $2;

              if ($param_name =~ /$param_key_pattern/) {
                $param_key = $1;
                $param_name = $2;
              }

              foreach my $param_type_key (keys %param_type_patterns) {
                if ($param_spec =~ /$param_type_patterns{$param_type_key}/) {
                  $param_type = $param_type_key;
                  break;
                }
              }

              @macro_params = (@macro_params, {
                tag => $param_tag,
                key => $param_key,
                name => $param_name,
                type => $param_type,
                description => $param_description
              });
            }
          }
          else {
            $in_parameter = 0;
          }
        }
        else {
          if ($in_parameter) {
            $macro_params[$#macro_params]->{description} .= " $block_line";
          }
          else {
            @non_directive = (@non_directive, $block_line);
          }
        }
      }

      if ($line =~ /$include_pattern/) {
        my $include = $1;
        if ($include =~ /$name_pattern/) {
          @module_includes = (@module_includes, $include);
        }
      }
      elsif ($line =~ /$macro_pattern/) {
        my $name = $1;
        @macros = (@macros, {
          name => $name,
          brief => $brief,
          description => join("\n", @non_directive),
          parameters => [@macro_params]
        });
      }
      elsif (!@macros) {
        if (!$module_brief) {
          $module_brief = $brief;
        }
        if ($module_brief and !$module_description) {
          $module_description = join("\n", @non_directive);
        }
      }

      @block = ();
      $in_block = 0;
    }
  }
  close(source_file);

  if ($module =~ /$name_pattern/) {
    $module = $1;
  }
  write_man($file, $module, 
    $module_brief, $module_description, \@module_includes, \@macros);
}

find(\&process_source, $project_sources);
