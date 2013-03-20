#!/usr/bin/perl

# ------------------------------------------------------------------ #
# xml2dumpinfo.pl by cutebutwrong ( http://www.mameworld.net/maws/ )
#
# Take a MAME listxml file and create an HTML list of sets that need
# re-dumping, ordered by manufacturer.
#
# 2005/10/02 first release
# 2005/10/10 filter out MCU undumpables
#
# ------------------------------------------------------------------ #

# ------------------------------------------------------------------ #
# includes

use XML::Parser;

# ------------------------------------------------------------------ #
# initialise

my $parser = XML::Parser->new(Style => 'Stream', Pkg => 'MameXmlSimple');
my $mame_xml = shift;
my %games = ();
my %mcus = ();

# ------------------------------------------------------------------ #
# main

( (-e $mame_xml) && (-r $mame_xml) ) ||
  die("Could not find XML file. Usage: perl xml2dumpinfo.pl \"mameinfo.xml\" > output.html");

$parser->parsefile($mame_xml);

exit;

# ------------------------------------------------------------------ #
# subs

sub escape_for_sql {
 my ( $self, $in_string, @p ) = @_;
 if ( $in_string ) {
   $in_string =~ s/\'/\'\'/ig;
   return $in_string;
 } else {
   return "";
 }
}

# ------------------------------------------------------------------ #
# packages

package MameXmlSimple;
use Data::Dumper;

my (%game, $current_element, $game_count, $game_bad_count, $game_mcu_count,
    @dump_roms, @dump_disks, @dump_mcus);
$game_count = 0;

sub StartTag {
 my ($self, $element) = @_;
 my %attributes = %_;
 
 if ($element eq 'game') {
   %game = %attributes;
   @dump_roms = ();
   @dump_disks = ();
   @dump_mcus = ();
   $game_count++;

 } elsif ($element eq 'rom') {
   # get attributes
   if ( ($attributes{"name"} eq "pr1data.8k") && ($attributes{"status"} ne "good") ) {
    # skip Namco substitute ROM
    $dump_mcus[@dump_mcus] = \%attributes;
   # } elsif ( ($attributes{"name"} =~ m/.*\.mcu/ig) && ($attributes{"status"} ne "good") ) {  
   #  # skip .mcu ROMs
   #  $dump_mcus[@dump_mcus] = \%attributes;
   } elsif ( $attributes{"status"} && ($attributes{"status"} ne "good") ) {
    $dump_roms[@dump_roms] = \%attributes;
   }

 } elsif ($element eq 'disk') {
   # get attributes
   if ( $attributes{"status"} && ($attributes{"status"} ne "good") ) {
    $dump_disks[@dump_disks] = \%attributes;
   }

 }
 
 $current_element = $element;
 
 if ( $game_count > 50 ) {
  # exit;
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
   $game{$current_element} = $text if $text;
 }
}

sub EndTag {
 my ($self, $element) = @_;
 if ($element eq "game") {
  my %cgame = %game;
  if ( @dump_roms || @dump_disks ) {
   my @cdump_roms = @dump_roms;
   my @cdump_disks = @dump_disks;
   $games{ $game{"manufacturer"} }{ $game{"description"} }{ "game" } = \%cgame;
   $games{ $game{"manufacturer"} }{ $game{"description"} }{ "roms" } = \@cdump_roms;
   $games{ $game{"manufacturer"} }{ $game{"description"} }{ "disks" } = \@cdump_disks;
   $game_bad_count++;
  }
  if ( @dump_mcus ) {
   my @cdump_mcus = @dump_mcus;
   $mcus{ $game{"manufacturer"} }{ $game{"description"} }{ "game" } = \%cgame;
   $mcus{ $game{"manufacturer"} }{ $game{"description"} }{ "mcus" } = \@cdump_mcus;
   $game_mcu_count++;
  }
 }
}

sub StartDocument {
 my ($self) = @_;
 print "<html>\n<head>\n";
 print '<style type="text/css"> * { font-family: Arial, Helvetica, sans-serif; } BODY { font-size: 80%; } .manulist { margin: 0px; padding: 0px; } LI.manu { font-weight: bold; list-style-type: none; margin: 0px; padding: 0px; } LI.set { font-weight: normal; list-style-type: none; margin: 0px; padding: 0px; } LI.rom_nodump, LI.rom_baddump { list-style-type: square; } LI.disk_nodump, LI.disk_baddump { list-style-type: disc; } </style>'."\n";
 print "</head>\n<body>\n";
}

sub EndDocument {
 my ($self) = @_;
 print "<h1>ROMs that need re-dumping as of MAME&trade; version .xxx.xx</h1>\n";
 print "<p>".$game_count." total sets of which ".$game_bad_count." need re-dumping<br>\n";
 print "Games listed with &quot;baddump&quot; have known parts that are bad or suspected to be bad. <br>\n";
 print "Games listed  with &quot;nodump&quot; are known or suspected to be missing some data.</p>\n";
 print "<p>NOTE!<br>\n";
 print "Hopefully some new flags will be introduced to give more details about things such as MCUs that can not be dumped.<br>\n";
 print "So for now, ignore anything about MCU's being needed because there are many that were read and were protected. The likelyhood of all of them being protected is very high, the effort is better spent elsewhere.<br>\n";
 print "Also ignore all of the bad dumps of 'pr1data.8k' in the NAMCO section being wanted. Hopefully a new flag can be introduced there also to state that 'pr1data.8k' is simply a substitute ROM being used until the real data can be extracted (if possible).</p>\n";
 
 print "<h2>ROM Missing and Bad Dumps</h2>\n";
 print "<ul class=\"manulist\">\n";
 foreach $manufacturer (sort keys %games) {
  print "<li class=\"manu\">".&escapeHtml( $manufacturer )."\n";
  print " <ol>\n";
  my $games_ref = $games{$manufacturer};
  my %manu_games = %$games_ref;
  foreach $game_name (sort keys %manu_games ) {
    my $game_ref = ($manu_games{$game_name}{"game"}); my %mgame = %$game_ref; 
    my $roms_ref = $manu_games{$game_name}{"roms"}; my @dump_roms = @$roms_ref;
    my $disks_ref = $manu_games{$game_name}{"disks"}; my @dump_disks = @$disks_ref;
    print "  <li class=\"set\">".&escapeHtml( $mgame{"description"} )." (<a href=\"http://www.mameworld.net/maws/set/".$mgame{"name"}."\">".$mgame{"name"}."</a>)\n";
    if ( @dump_roms ) {
     print "   <ul>\n";
     for($dLoop=0;$dLoop<@dump_roms;$dLoop++) {
      print "    <li class=\"rom_".$dump_roms[$dLoop]{"status"}."\">".$dump_roms[$dLoop]{"name"}." - ".$dump_roms[$dLoop]{"status"}."</li>\n";
     }
     print "   </ul>\n";
    }
    if ( @dump_disks ) {
     print "   <ul>\n";
     for($dLoop=0;$dLoop<@dump_disks;$dLoop++) {
      print "    <li class=\"disk_".$dump_disks[$dLoop]{"status"}."\">".$dump_disks[$dLoop]{"name"}.".chd - ".$dump_disks[$dLoop]{"status"}."</li>\n";
     }
     print "   </ul>\n";
    }
    print "  </li>\n";
  }
  print " </ol>\n";
  print "</li>\n";
 }
 print "</ul>\n";

 print "<h2>Dumps Not Required (undumpable MCUs, etc?)</h2>\n";
 print "<ul class=\"manulist\">\n";
 foreach $manufacturer (sort keys %mcus) {
  print "<li class=\"manu\">".&escapeHtml( $manufacturer )."\n";
  print " <ol>\n";
  my $mcu_ref = $mcus{$manufacturer};
  my %manu_games = %$mcu_ref;
  foreach $game_name (sort keys %manu_games ) {
    my $game_ref = ($manu_games{$game_name}{"game"}); my %mgame = %$game_ref; 
    my $mcu_ref = $manu_games{$game_name}{"mcus"}; my @dump_mcus = @$mcu_ref;
    print "  <li class=\"set\">".&escapeHtml( $mgame{"description"} )." (<a href=\"http://www.mameworld.net/maws/set/".$mgame{"name"}."\">".$mgame{"name"}."</a>)\n";
    if ( @dump_mcus ) {
     print "   <ul>\n";
     for($dLoop=0;$dLoop<@dump_mcus;$dLoop++) {
      print "    <li class=\"mcu_".$dump_mcus[$dLoop]{"status"}."\">".$dump_mcus[$dLoop]{"name"}." - ".$dump_mcus[$dLoop]{"status"}."</li>\n";
     }
     print "   </ul>\n";
    }
    print "  </li>\n";
  }
  print " </ol>\n";
  print "</li>\n";
 }
 print "</ul>\n";

 print "</body></html>\n";
}

sub Text {
 my ($self, $element) = @_;
 if ( ($current_element eq 'description')
      || ($current_element eq 'year')
      || ($current_element eq 'manufacturer')) {
   my $text = $self->{Text};
   # print $current_element." ".$text."\n";
   # clear white space
   $text =~ s/^\s*//;
   $text =~ s/\s*$//;
   $game{$current_element} = $text if $text;
 }
}

sub escapeHtml {
 my ($html, @p) = @_;
 $html  =~ s/</&lt;/;
 $html  =~ s/>/&gt;/;
 $html  =~ s/"/&quot;/;
 return $html;
}

1;


__END__

