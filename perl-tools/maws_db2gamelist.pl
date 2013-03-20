#!/usr/bin/perl 

# ------------------------------------------------------------------ #
# includes

use maws;

# ------------------------------------------------------------------ #
# initialise
my $MAWS = new maws;

# ------------------------------------------------------------------ #
# globals

# ------------------------------------------------------------------ #
# main

my $dbh = $MAWS->get_dbh();

# get version
my $sth_version = $dbh->prepare( "SELECT lookup_version_id, lookup_version_value FROM maws_lookup_version ORDER BY lookup_version_id DESC" ); 
$sth_version->execute();
my $version_row_ref = $sth_version->fetchrow_hashref();
my %version_row = %$version_row_ref;

# top of file
print &show_header( $version_row{'lookup_version_value'}, '' );

# list bios 
my $sth_bios = $dbh->prepare( "SELECT * FROM maws_resources WHERE resource_type = 'resource'" ); 
$sth_bios->execute();
my $bios_row_ref = $sth_bios->fetchrow_hashref();
my $bios_list = '';
while ( $bios_row_ref ) {
  my %bios_row = %$bios_row_ref;
  $bios_list .= ", '".$bios_row{'resource_name'}."'";
  $bios_row_ref = $sth_bios->fetchrow_hashref();
}
$sth_bios->finish();

# list games
my $sth_games = $dbh->prepare( "SELECT * FROM maws_resources WHERE resource_type = 'game' AND resource_romof IN ( '' ".$bios_list." ) ORDER BY resource_description" ); 
$sth_games->execute();
my $games_row_ref = $sth_games->fetchrow_hashref();
while ( $games_row_ref ) {
  my %games_row = %$games_row_ref;
  print "| ".&pad_spaces($games_row{ 'resource_description' }, 32)." |".&get_driver_status($games_row{ 'emulation_status' },$games_row{ 'resource_name' })."|".&get_driver_color($games_row{ 'driver_color' })."|".&get_driver_sound($games_row{ 'driver_sound' },$games_row{ 'sound_samples' })."|".&get_driver_flipping($games_row{ '' })."| ".&pad_spaces($games_row{ 'resource_name' }, 8)." |\n";
  $games_row_ref = $sth_games->fetchrow_hashref();
}
$sth_games->finish();

# sound_samples blob,

# file footer
print &show_footer();

exit;

sub get_emulation_status {
  my ( $emulation_status, $resource_name, @p ) = @_;
  if ( ($emulation_status eq 'good') || ($emulation_status eq 'imperfect') ) {
    return '  Yes  ';
  } else {
    # check for working clones
    my $clo_games = $dbh->prepare( "SELECT * FROM maws_resources WHERE resource_type = 'game' AND (emulation_status = 'good' OR emulation_status = 'imperfect') AND resource_romof = '".$resource_name."'ORDER BY resource_description" ); 
    $clo_games->execute();
    if ( $clo_games->fetchrow_hashref() ) {
      return ' No(1) ';
    } else {
      return '   No  ';
    }
  }
}

sub get_driver_status {
  my ( $driver_status, $resource_name, @p ) = @_;
  if ( $driver_status ne 'preliminary' ) {
    return '  Yes  ';
  } else {
    # check for working clones
    my $clo_games = $dbh->prepare( "SELECT * FROM maws_resources WHERE resource_type = 'game' AND driver_status = 'good' AND resource_romof = '".$resource_name."'ORDER BY resource_description" ); 
    $clo_games->execute();
    if ( $clo_games->fetchrow_hashref() ) {
      return ' No(1) ';
    } else {
      return '   No  ';
    }
  }
}

sub get_driver_color {
  my ( $driver_color, @p ) = @_;
  if ( $driver_color eq 'good' ) {
    return '  Yes  ';
  } elsif ( $driver_color eq 'imperfect' ) {
    return ' Close ';
  } else {
    return '   No  ';
  }
}

sub get_driver_sound {
  my ( $driver_sound, $sound_samples, @p ) = @_;
  if ( $driver_sound eq 'good' ) {
    if ( length($sound_samples) > 5 ) {
      return ' Yes(2)';
    } else {
      return '  Yes  ';
    }
  } elsif ( $driver_sound eq 'imperfect' ) {
    if ( length($sound_samples) > 5 ) {
      return 'Part(2)';
    } else {
      return 'Partial';
    }
  } else {
    return '   No  ';
  }
}

sub get_driver_flipping {
  my ( $driver_flipping, @p ) = @_;
  return &pad_spaces('  ---  ', 7);
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
  my ( $mame_version, $mame_date, @p ) = @_;
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


__END__
