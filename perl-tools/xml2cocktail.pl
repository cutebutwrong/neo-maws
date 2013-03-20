#!/usr/bin/perl

# FIXME: remaining bug allows a blank details, probably from putting clones in wrong hash

# ------------------------------------------------------------------ #
# includes

use XML::Parser;
use Data::Dumper;
use strict;

# ------------------------------------------------------------------ #
# initialise

my $parser = XML::Parser->new( Style => 'Stream', Pkg => 'MameXmlCocktail' );
my $mame_xml = shift;

my %settings = (
    ## general
    # program
    "program"=>"xml2cocktail.pl", 
    # version
    "build"=>"v0.1 - 2005/12/23", 
    # max sets to load (0 is no limit)
    "max_sets"=>"0", 
    "mame32ini"=>"0",
  );  

if ( $mame_xml eq "-mame32ini" ) {
  $settings{"mame32ini"} = "1";
  $mame_xml = shift;
}

# ------------------------------------------------------------------ #
# main

if ( !((-e $mame_xml) && (-r $mame_xml)) ) {
  print "=======================================================\n";
  print $settings{"program"} . " - " . $settings{"build"} . "\n";
  print "  cutebutwrong - http://www.mameworld.net/maws/\n";
  print "=======================================================\n";
  print "Read MAME -listxml file and produce cocktail.ini\n";
  print "=======================================================\n";
  print "Usage:\n";
  print "  perl " . $settings{"program"} . " \"mameinfo.xml\" > cocktail.ini\n";
  print "  perl " . $settings{"program"} . " -mame32ini \"mameinfo.xml\" > cocktail32.ini\n\n";
  
  exit;
}

$parser->parsefile($mame_xml);

exit;

# ------------------------------------------------------------------ #
# packages

package MameXmlCocktail;
use Data::Dumper;

my ( %games, $current_element, $current_set, $game_count, 
     $mame_version );

## XML handlers

sub StartTag {
 my ($self, $element) = @_;
 my %attributes = %_;
 
 if ($element eq 'game') {
   if ( $attributes{"runnable"} eq "no" ) {
     ## BIOS
   } else {
     ## game
     $current_set = $attributes{"name"};
     $games{$current_set} = \%attributes;
     $game_count++;
   }
   
 } elsif ( ($element eq 'driver') && $current_set ) {
   $games{$current_set}{$element} = \%attributes;

 } elsif ( ($element eq 'dipvalue') && $current_set ) {
   if ( $attributes{"name"} eq "Cocktail" ) {
     $games{$current_set}{"cocktail_dip"} = 1;
   }
   
 } elsif ( ($element eq 'mame') && $attributes{"build"} ) {
   $mame_version = $attributes{"build"};
 
 }
 
 $current_element = $element;
 
 if ( $settings{"max_sets"} && ($game_count > $settings{"max_sets"}) ) {
   exit;
 }
}

sub EndTag {
 my ($self, $element) = @_;
 if ($element eq "game") {
   $current_set = undef;
 }
}

sub StartDocument {
 my ($self) = @_;
 
 $game_count = 0;
}

sub EndDocument {
 my ($self) = @_;
 if ( $settings{"mame32ini"} ) {
   print "[FOLDER_SETTINGS]\n";
   print "RootFolderIcon = cust1.ico\n";
   print "SubFolderIcon = cust2.ico\n\n";
   print "[ROOT_FOLDER]\n\n";
   # good|imperfect|preliminary
   my ( $cocktail_good, $cocktail_imperfect, $cocktail_preliminary, $other ) = ( "", "", "", "" );
   foreach my $set_name (sort keys %games ) {
     if ( (length($set_name) <= 8) && (length($set_name) > 0) ) {
       if ( $games{$set_name}{"driver"}{"cocktail"} eq "good" ) {
         $cocktail_good .= $set_name."\n";
       } elsif ( $games{$set_name}{"driver"}{"cocktail"} eq "imperfect" ) {
         $cocktail_imperfect .= $set_name."\n";
       } elsif ( $games{$set_name}{"driver"}{"cocktail"} eq "preliminary" ) {
         $cocktail_preliminary .= $set_name."\n";
       } elsif ( $games{$set_name}{"cocktail_dip"} && ( $games{$set_name}{"driver"}{"cocktail"} ne "preliminary" ) ) {
         $cocktail_good .= $set_name."\n";
       } else {
         $other .= $set_name."\n";
       }
     } else {
       print "ERROR: set name ".$set_name." too long\n";
       exit(-1);
     }
   }
   print "[good]\n".$cocktail_good."\n";
   print "[imperfect]\n".$cocktail_imperfect."\n";
   print "[preliminary]\n".$cocktail_preliminary."\n";
   if ( $other ) {
     print "[n/a]\n".$other."\n";
   }
   
 } else {
   if ( $mame_version ) {
     print ";; Cocktail.ini / MAME ".$mame_version." / http://www.mameworld.net/maws/ ;;\n";
   } else {
     print ";; Cocktail.ini / http://www.mameworld.net/maws/ ;;\n";
   }
   print "\n[Cocktail]\n";

   foreach my $set_name (sort keys %games ) {
     if ( (length($set_name) <= 8) && (length($set_name) > 0) ) {
       if ( $games{$set_name}{"cocktail_dip"} && ( $games{$set_name}{"driver"}{"cocktail"} ne "preliminary" ) ) {
         print $set_name."=good\n";
       } elsif ( $games{$set_name}{"driver"}{"cocktail"} ) {
         print $set_name."=".$games{$set_name}{"driver"}{"cocktail"}."\n";
       } else {
         print $set_name."=n/a\n";
       }
     } else {
       print "ERROR: set name ".$set_name." too long\n";
       exit(-1);
     }
   }
 }
 print "\n";
}

sub Text {
 my ($self, $element) = @_;
 if ( ($current_element eq 'description')
      || ($current_element eq 'year')
      || ($current_element eq 'manufacturer')) {
   my $text = $self->{Text};
   # clear white space
   $text =~ s/^\s*//;
   $text =~ s/\s*$//;

   if ( $current_set ) {
     $games{$current_set}{$current_element} = $text if $text;
   }
 }
}

sub Characters {
 my ($self, $element) = @_;
 if (($current_element eq 'description')
     || ($current_element eq 'year')
     || ($current_element eq 'manufacturer')) {
   my $text = $self->{Text};
   # clear white space
   $text =~ s/^\s*//;
   $text =~ s/\s*$//;
   if ( $current_set ) {
     $games{$current_set}{$current_element} = $text if $text;
   }
 }
}

## utility functions

sub escapeHtml {
 my ($html, @p) = @_;
 $html  =~ s/</&lt;/;
 $html  =~ s/>/&gt;/;
 $html  =~ s/"/&quot;/;
 return $html;
}

sub escape_for_sql {
  my ( $in_string, @p ) = @_;
  if ( $in_string ) {
    $in_string =~ s/\'/\'\'/ig;
    return $in_string;
  } else {
    return "";
  }
}

sub escape_hash_for_sql {
  my ( $hashref, @p ) = @_;
  my %htable = %$hashref;
  foreach my $key ( keys %htable ) {
    $htable{$key} = &escape_for_sql( $htable{$key} );
  }
  return \%htable;
}

sub pad_spaces {
  my ( $in_string, $req_length, @p ) = @_;
  if ( length($in_string) < $req_length ) {
    return sprintf '%-'.$req_length.'s', $in_string;
  } else {
    return substr $in_string, 0, $req_length;
  }
}

1;


__END__

