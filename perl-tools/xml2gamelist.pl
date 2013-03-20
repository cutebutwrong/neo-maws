#!/usr/bin/perl

# FIXME: remaining bug allows a blank details, probably from putting clones in wrong hash

# ------------------------------------------------------------------ #
# includes

use XML::Parser;
use Data::Dumper;
use strict;

# ------------------------------------------------------------------ #
# initialise

my $parser = XML::Parser->new( Style => 'Stream', Pkg => 'MameXml' );
my $mame_xml = shift;

my %settings = (
    ## general
    # program
    "program"=>"xml2gamelist.pl", 
    # version
    "build"=>"v0.1 - 2005/12/17", 
    # max sets to load (0 is no limit)
    "max_sets"=>"0", 
  );  


# ------------------------------------------------------------------ #
# main

if ( !((-e $mame_xml) && (-r $mame_xml)) ) {
  print "=======================================================\n";
  print $settings{"program"} . " - " . $settings{"build"} . "\n";
  print "  cutebutwrong - http://www.mameworld.net/maws/\n";
  print "=======================================================\n";
  print "Read MAME -listxml file and producce gamelist.txt\n";
  print "=======================================================\n";
  print "Usage:\n";
  print "  perl " . $settings{"program"} . " \"mameinfo.xml\" > gamelist.txt\n\n";
  
  exit;
}

$parser->parsefile($mame_xml);

exit;

# ------------------------------------------------------------------ #
# packages

package MameXml;
use Data::Dumper;

my ( %games, %clones, $current_element, $current_set, $current_clone,
     $game_count, $clone_count, $bios_count, $mame_version );

## XML handlers

sub StartTag {
 my ($self, $element) = @_;
 my %attributes = %_;
 
 if ($element eq 'game') {
   if ( $attributes{"isbios"} eq "yes" ) {
     ## BIOS
     $bios_count++;
   } elsif ( $attributes{"cloneof"} ) {
     ## clone
     $current_clone = $attributes{"name"};
     $clones{$current_clone} = \%attributes;
     $clone_count++;
   } else {
     ## parent
     $current_set = $attributes{"name"};
     $games{$current_set} = \%attributes;
     $game_count++;
   }
   
 } elsif ( $element eq 'driver' ) {
   if ( $current_set ) {
     # store attributes
     $games{$current_set}{$element} = \%attributes;
   } elsif ( $current_clone ) {
     if ( !($games{$clones{$current_clone}}{"working_clone"}) 
          && ($attributes{"emulation"} ne "preliminary") ) {
       $games{$clones{$current_clone}{"cloneof"}}{"working_clone"} = $current_clone;
     }
   }

 } elsif ( $element eq 'sample' ) {
   if ( $current_set ) {
     $games{$current_set}{"samples"} = "Yes";
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
   $current_clone = undef;
 }
}

sub StartDocument {
 my ($self) = @_;
 
 $game_count = 0;
}

sub EndDocument {
 my ($self) = @_;
 print &show_header($mame_version);
 my %gamelist = {};

 foreach my $set_name (keys %games ) {
   if ( (length($set_name) <= 8) && (length($set_name) > 0) ) {
     my $sort_description = $games{$set_name}{"description"};
     $sort_description =~ tr/[A-Z]/[a-z]/;
     $sort_description =~ s/\s+/ /;
     if ( length( $sort_description ) > 1 ) {
       $gamelist{$sort_description} = $set_name;
     }
   } else {
     #### print "ERROR: set name ".$set_name." too long\n";
   }
 }

 foreach my $set_description (sort keys %gamelist ) {
   my $parent_name = $gamelist{$set_description};
   print "| ".&pad_spaces($games{$parent_name}{"description"}, 32)." | ";
   if ( $games{$parent_name}{"driver"}{"emulation"} ne "preliminary" ) {
     print " Yes "
   } elsif ( $games{$parent_name}{"working_clone"} ) {
     print "No(1)"
   } else {
     print "  No ";
   }
   print " | ";
   if ( $games{$parent_name}{"driver"}{"color"} eq 'good' ) {
     print " Yes  ";
   } elsif ( $games{$parent_name}{"driver"}{"color"} eq 'imperfect' ) {
     print "Close ";
   } else {
     print "  No  ";
   }
   if ( $games{$parent_name}{"driver"}{"sound"} eq "good" ) {
     if ( $games{$parent_name}{"samples"} ) {
       print "| Yes(2)|";
     } else {
       print "|  Yes  |";
     }
   } elsif ( $games{$parent_name}{"driver"}{"sound"} eq "imperfect" ) {
     if ( $games{$parent_name}{"samples"} ) {
       print "|Part(2)|";
     } else {
       print "|Partial|";
     }
   } else {
     print "|   No  |";
   }
   if ( $games{$parent_name}{"driver"}{"cocktail"} eq "preliminary" ) {
     print "   No ";
   } else {
     print "  Yes ";
   }

   print " | ".&pad_spaces($parent_name, 8)." |\n";
 }
 
 print &show_footer();
 
 print "\n".$game_count." parent, ".$clone_count." clone, and ".$bios_count." BIOS sets processed\n";
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

sub show_header {
  my ( $mame_version, @p ) = @_;
  my $outstring =<<"END_INLINE";
This is the complete list of games supported by MAME $mame_version

This list is designed to copy the format of the old gamelist.txt but variations
may occur. Specifically, the screen flipping column is not yet supported.
Explanatory text has been copied from the original file generated by MAME.

This list is generated automatically and is not 100% accurate. MAWS extracts
information from -listxml and errors may be introduced during this process.

An up-to-date version can be found online at: 
http://www.mameworld.net/maws/gamelist.txt

Here are the meanings of the columns:

Working
=======
  NO: Emulation is still in progress; the game does not work correctly. This
  means anything from major problems to a black screen.

Correct Colors
==============
    YES: Colors should be identical to the original.
  CLOSE: Colors are nearly correct.
     NO: Colors are completely wrong. 
  
  Note: In some cases, the color PROMs for some games are not yet available.
  This causes a NO GOOD DUMP KNOWN message on startup (and, of course, the game
  has wrong colors). The game will still say YES in this column, however,
  because the code to handle the color PROMs has been added to the driver. When
  the PROMs are available, the colors will be correct.

Sound
=====
  PARTIAL: Sound support is incomplete or not entirely accurate. 

  Note: Some original games contain analog sound circuitry, which is difficult
  to emulate. Therefore, these emulated sounds may be significantly different.

Screen Flip
===========
  Many games were offered in cocktail-table models, allowing two players to sit
  across from each other; the game's image flips 180 degrees for each player's
  turn. Some games also have a "Flip Screen" DIP switch setting to turn the
  picture (particularly useful with vertical games).
  In many cases, this feature has not yet been emulated.

Internal Name
=============
  This is the unique name that must be used when running the game from a
  command line.

  Note: Each game's ROM set must be placed in the ROM path, either in a .zip
  file or in a subdirectory with the game's Internal Name. The former is
  suggested, because the files will be identified by their CRC instead of
  requiring specific names.

+----------------------------------+-------+-------+-------+-------+----------+
|                                  |       |Correct|       |Screen | Internal |
| Game Name                        |Working|Colors | Sound | Flip  |   Name   |
+----------------------------------+-------+-------+-------+-------+----------+
END_INLINE
  return $outstring;
}

sub show_footer {
  my $outstring =<<"END_INLINE";
+----------------------------------+-------+-------+-------+-------+----------+

(1) There are variants of the game (usually bootlegs) that work correctly
(2) Needs samples provided separately

END_INLINE
  return $outstring;
}


1;


__END__

