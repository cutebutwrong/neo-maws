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
    "program"=>"xml2hilist.pl", 
    # version
    "build"=>"v0.1 - 2007/01/02", 
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
  print "Read MAME -listxml file and produce hi-score/savestate\n";
  print "=======================================================\n";
  print "Usage:\n";
  print "  perl " . $settings{"program"} . " \"mameinfo.xml\" > hilist.txt\n\n";
  
  exit;
}

# get hiscore support info
my $hiscore_ref = &parse_hiscore;
my %hiscore_support = %$hiscore_ref;

# parse XML
$parser->parsefile($mame_xml);

exit;

# ------------------------------------------------------------------ #
# subroutines

## Process hiscore dat for hiscore support lookup
sub parse_hiscore {
  my $line_num = 0;
  my $hiscore_path = 'F:\mingw\dat\mame\hiscoredat143u9.dat';
  my ( %hiscore_support, @dat_content );
  if ( open(MAMEDATA,"<$hiscore_path" ) ) {
    @dat_content = <MAMEDATA>;
    close(MAMEDATA);
  }
  # read each line and parse
  foreach my $curr_line (@dat_content) {
    # check for just whitespace
    if ( $curr_line =~ m/^\s+$/i ) {
      # print "White space only: ".$line_num."\n";

      # comment line
    } elsif ($curr_line =~ m/^\;.*$/i ) {
      # ignore comment line

    # entry line (don't need)
    } elsif ($curr_line =~ m/\d\:.*/i ) {
      # ignore code entry line

    # capture data
    } elsif ($curr_line =~ m/^(\S+)\:.*$/i ) {
      # escape for SQL
      $hiscore_support{$1} = "supported"

    }
  }
  # print "Processed \'$hiscore_path\' : ".@dat_content." lines\n";
  @dat_content = (); # clear to return memory
  return \%hiscore_support;
}

# ------------------------------------------------------------------ #
# packages

package MameXml;
use Data::Dumper;

my ( %games, %clones, $current_element, $current_set, $current_clone,
     $game_count, $clone_count, $bios_count, $mame_version,
     $savestate_count, $hiscore_count,
     $savestate_parent_count, $hiscore_parent_count );

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
     if ( $attributes{"savestate"} eq "supported" ) {
       $savestate_count++;
       $savestate_parent_count++;
     }
     $games{$current_set}{$element} = \%attributes;
   } elsif ( $current_clone ) {
     if ( $attributes{"savestate"} eq "supported" ) {
       $savestate_count++;
     }
     if ( !($games{$clones{$current_clone}}{"working_clone_ss"}) 
          && ($attributes{"savestate"} eq "supported") ) {
       $games{$clones{$current_clone}{"cloneof"}}{"working_clone_ss"} = $current_clone;
     }
   }
   # store hiscore data
   if ( $current_clone ) {
     if ( $hiscore_support{$current_clone} eq "supported" ) {
       $hiscore_count++;
       $games{$current_clone}{"hiscore_clone"} = "supported";
     }
   } else {
     if ( $hiscore_support{$current_set} eq "supported" ) {
       $hiscore_count++;
       $hiscore_parent_count++;
       $games{$current_set}{"hiscore"} = "supported";
     }
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
  if ( $set_description ) {
   my $parent_name = $gamelist{$set_description};
   print "| ".&pad_spaces($games{$parent_name}{"description"}, 32)." |";
   if ( $games{$parent_name}{"driver"}{"savestate"} eq "supported" ) {
     print "    supported "
   } elsif ( $games{$parent_name}{"working_clone_ss"} ) {
     print "unsupported(1)"
   } else {
     print "  unsupported ";
   }
   print "|";
   if ( $games{$parent_name}{"hiscore"} eq "supported" ) {
     print "    supported "
   } elsif ( $games{$parent_name}{"hiscore_clone"} ) {
     print "unsupported(1)"
   } else {
     print "  unsupported ";
   }

   print "| ".&pad_spaces($parent_name, 8)." |\n";
  }
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
This is the complete list of games with savestate support in:
  MAME $mame_version

Hiscore.dat information is for version .131 of MAME and the file


+----------------------------------+--------------+--------------+----------+
|                                  |              |              | Internal |
| Game Name                        |  savestate   | hiscore.dat  |   Name   |
+----------------------------------+--------------+--------------+----------+
END_INLINE
  return $outstring;
}

sub show_footer {
  my $outstring =<<"END_INLINE";
+----------------------------------+--------------+--------------+----------+

Totals: 
  savestate: $savestate_count
  (parents only): $savestate_parent_count
  
  hiscore: $hiscore_count
  (parents only): $hiscore_parent_count

END_INLINE
  return $outstring;

## not required
# (1) There are variants of the game (usually bootlegs) that work correctly

}


1;


__END__

