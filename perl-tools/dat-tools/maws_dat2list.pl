#!/usr/bin/perl 

# maws_dat2list.pl
#  - convert listinfo DAT to various other legacy files that MAME used to generate. Developed for Trigg when support was dropped in MAME for various files that his program needed.
# ------------------------------------------------------------------ #
# includes

use strict;

# ------------------------------------------------------------------ #
# initialise
my $mame_version = "99u7";
my $main_path = "d:\\emu\\maws\\";
my $mamedat_path = $main_path."dat\\mame\\mame".$mame_version.".dat";

my $out_path = $main_path."dat\\catgen\\".$mame_version."\\";
my $full_path = $out_path."full.list";
my $games_path = $out_path."games.list";
my $details_path = $out_path."details.list";
my $list_path = $out_path."list.list";


# ------------------------------------------------------------------ #
# globals
my @dat_content;
my %game_data;
my %chip_data;
my $line_num = 0;

my $game_cpus;
my $game_sounds;
my $cpu_pos = 0;
my $sound_pos = 0;
my $cpu_max = 8;
my $sound_max = 32;
my $num_games = 0;

# ------------------------------------------------------------------ #
# main

if ( (-e $mamedat_path) && (-r $mamedat_path) ) {

  if ( open(FULLDATA,">$full_path")
       && open(GAMESDATA,">$games_path")
       && open(DETAILSDATA,">$details_path")
       && open(LISTDATA,">$list_path")
     ) {
     
    print FULLDATA "Name:     Description:\n";

    print DETAILSDATA " romname driver     cpu 1    cpu 2    cpu 3    cpu 4    cpu 5    cpu 6    cpu 7    cpu 8    sound 1     sound 2     sound 3     sound 4     sound 5     sound 6     sound 7     sound 8     sound 9     sound 10     sound 11     sound 12     sound 13     sound 14     sound 15     sound 16     sound 17     sound 18     sound 19     sound 20     sound 21     sound 22     sound 23     sound 24     sound 25     sound 26     sound 27     sound 28     sound 29     sound 30     sound 31     sound 32     name\n";
    print DETAILSDATA "-------- ---------- -------- -------- -------- -------- -------- -------- -------- -------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- --------------------------\n";

    print LISTDATA "\nMAME currently supports the following games:\n\n";

    ## Process MAME dat for main tables
    # open mame dat file
    if ( open(MAMEDATA,"<$mamedat_path" ) ) {
      @dat_content = <MAMEDATA>;
      close(MAMEDATA);
    }

    # read each line and parse
    foreach my $curr_line (@dat_content) {
      # check for just whitespace
      if ( $curr_line =~ m/^\s+$/i ) {
        # print "White space only: ".$line_num."\n";

      # otherwise check for end of record - write current data - clear structures
      } elsif ($curr_line =~ m/^\s*\)\s*$/i ) {
        # escape for SQL
        my $fixed_game = &escape_hash_for_sql( \%game_data );
        %game_data = %$fixed_game;
        
        # pad CPUs
        while ( $cpu_pos < $cpu_max ) {
          $game_cpus .= &pad_spaces( "", 8 )." ";
          $cpu_pos++;
        }
        # pad sound
        while ( $sound_pos < $sound_max ) {
          $game_sounds .= &pad_spaces( "Dummy", 11 )." ";
          $sound_pos++;
        }
        
        # print to each file
        if ( $game_data{ "file-type" } eq "game" ) {
          $num_games++;
          print FULLDATA &pad_spaces($game_data{ "name" },9).' "'.$game_data{ "description" }.'"'."\n";
          print GAMESDATA &pad_spaces($game_data{ "year" },4)." ".&pad_spaces($game_data{ "manufacturer" },36)." ".$game_data{ "description" }."\n";
          print DETAILSDATA &pad_spaces($game_data{ "name" },8)." ".&pad_spaces($game_data{ "sourcefile" },10)." ".$game_cpus.$game_sounds.$game_data{ "description" }."\n";
          print LISTDATA &pad_spaces($game_data{ "name" },8);
          if ( !($num_games % 8) ) { 
            print LISTDATA "\n";
          } else {
            print LISTDATA "  ";
          }
        }

        %game_data = ();
        $game_cpus = "";
        $game_sounds = "";
        $cpu_pos = 0;
        $sound_pos = 0;

      # otherwise for and capture start of record - game or resource
      } elsif ($curr_line =~ m/^\s*(game|resource)\s+\(\s*$/i ) {
        # print "Type: ".$1."\n";
        $game_data{ "file-type" } = $1;

      # otherwise for and capture info in record
      } else {
        if ($curr_line =~ m/^\s*dipswitchinput\s*\(\s*(.+)?\s*\)\s*$/i ) {
          # ignore dipswitch entries

        } elsif ($curr_line =~ m/^\s*chip\s*\(\s*(.+)?\s*\)\s*$/i ) {
          # grab chip entry
          my $temp_line = $1;
          %chip_data = ();
          $temp_line =~ m/type\s+(\w+)\s*.*/i;
          $chip_data{"type"} = $1;
          $temp_line =~ m/name\s+"(.+)?"\s*.*/i;
          $chip_data{"name"} = $1;
          if ( $chip_data{"type"} eq "cpu" ) {
            $game_cpus .= &pad_spaces( $chip_data{"name"}, 8 )." ";
            $cpu_pos++;
          } elsif ( $chip_data{"type"} eq "audio" ) {
            $game_sounds .= &pad_spaces( $chip_data{"name"}, 11 )." ";
            $sound_pos++;
          } else {
            ## nothing
          }
          
        } elsif ($curr_line =~ m/^\s*name\s+(\S+)$/i ) {
          $game_data{ "name" } = $1;
        } elsif ($curr_line =~ m/^\s*year\s+(\S+)$/i ) {
          $game_data{ "year" } = $1;
        } elsif ($curr_line =~ m/^\s*description\s+\"(.+)?\"\s*$/i ) {
          $game_data{ "description" } = $1;
        } elsif ($curr_line =~ m/^\s*manufacturer\s+\"(.+)?\"\s*$/i ) {
          $game_data{ "manufacturer" } = $1;
        } elsif ($curr_line =~ m/^\s*romof\s+(\S+)$/i ) {
          $game_data{ "romof" } = $1;
        } elsif ($curr_line =~ m/^\s*cloneof\s+(\S+)$/i ) {
          $game_data{ "cloneof" } = $1;

        } elsif ($curr_line =~ m/^\s*driver\s*\(\s*(.+)?\s*\)\s*$/i ) {
          $game_data{ "driver" } = $1;
          if ( $game_data{ "driver" } =~ m/status\s+(\w+)\s*.*/i ) {
            $game_data{ "driver_status" } = $1;
          }
          if ( $game_data{ "driver" } =~ m/color\s+(\w+)\s*.*/i ) {
            $game_data{ "driver_color" } = $1;
          }
          if ( $game_data{ "driver" } =~ m/sound\s+(\w+)\s*.*/i ) {
            $game_data{ "driver_sound" } = $1;
          }
          if ( $game_data{ "driver" } =~ m/palettesize\s+(\d+)\s*.*/i ) {
            $game_data{ "driver_palettesize" } = $1;
          }

        } elsif ($curr_line =~ m/^\s*sourcefile\s+(\S+\.\S+)$/i ) {
          $game_data{ "sourcefile" } = $1;

        }
      }
      $line_num++;
    }
    print "Processed \'$mamedat_path\' : $line_num lines\n";
    @dat_content = (); # clear to return memory

    print LISTDATA "\n\nTotal ROM sets supported: ".$num_games."\n";

    close(FULLDATA);
    close(GAMESDATA);
    close(DETAILSDATA);
    close(LISTDATA);
  }  else {
    print "Can\'t open output file(s)\n";
  } 
} else {
  print "Can\'t open $mamedat_path\n";
}
exit;

sub escape_for_sql {
  my ( $in_string, @p ) = @_;
  return $in_string;
  
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
    return $in_string;
  }
}

__END__

