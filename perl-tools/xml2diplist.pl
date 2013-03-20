#!/usr/bin/perl

# Updates:
#  CBW 21/02/2007 Fixed driver source links

# ------------------------------------------------------------------ #
# includes

use XML::Parser;

# ------------------------------------------------------------------ #
# initialise

my $parser = XML::Parser->new(Style => 'Stream', Pkg => 'MameXmlSimple');
my $mame_xml = shift;
my %games = ();
my $show_dips = 1;

if ( $mame_xml =~ m/\-hidedips/i ) {
  $show_dips = 0;
  $mame_xml = shift;
}

# ------------------------------------------------------------------ #
# main

( (-e $mame_xml) && (-r $mame_xml) ) ||
  die("Could not find XML file. Usage: perl xml2diplist.pl [-hidedips] \"listinfo.xml\" > diplist.html");

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

my (%game, $current_element, $game_count, $unknown_dip_count,
    @unknown_dip_roms, $build_version);
$game_count = 0;

sub StartTag {
 my ($self, $element) = @_;
 my %attributes = %_;
 
 if ($element eq 'game') {
   %game = %attributes;
   @unknown_dip_roms = ();
   $game_count++;

 } elsif ($element eq 'dipswitch') {
   # get attributes
   if ( $attributes{"name"} =~ m/unknown/ig ) {
    $unknown_dip_roms[@unknown_dip_roms] = \%attributes;
   }

 } elsif ($element eq 'mame') {
   # get attributes
   if ( $attributes{"build"} ) {
    $build_version = $attributes{"build"};
   } else {
    $build_version = "[unknown build]";
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
  if ( @unknown_dip_roms  ) {
   my %cgame = %game;
   my @cunknown_dip_roms = @unknown_dip_roms;
   $games{ $game{"description"} }{ "game" } = \%cgame;
   $games{ $game{"description"} }{ "dips" } = \@cunknown_dip_roms;
   $unknown_dip_count++;
  }
 }
}

sub StartDocument {
 my ($self) = @_;
 print "<html>\n<head>\n";
 print '<style type="text/css"> BODY { font-family: Arial, Helvetica, sans-serif; } UL, P { font-size: 10pt; } #manulist { margin: 0px; padding: 0px; } LI.manu { font-weight: bold; list-style-type: none; margin: 0px 0px 10px 0px; padding: 0px; } LI.set { font-weight: normal; list-style-type: none; margin: 0px; padding: 0px; } LI.rom_nodump, LI.rom_baddump { list-style-type: square; } LI.disk_nodump, LI.disk_baddump { list-style-type: disc; } </style>'."\n";
 print "</head>\n<body>\n";
}

sub EndDocument {
 my ($self) = @_;
 print "<h1>ROMs that have unknown dips as of MAME version ".$build_version."</h1>\n";
 print "<p>".$game_count." total sets of which ".$unknown_dip_count." have unknown dips</p>\n";
 print "<p>NOTE!<br/>\n";  
 print "This page is auto-generated from MAME's XML output and is 100% accurate based on the version of MAME stated above.<br/>\n";
 print "If something listed here is not correct, or misleading, don't complain to me. Just fix the MAME source.</p>\n"; 
 print "<ul id=\"#manulist\">\n";
  foreach $game_name (sort keys %games ) {
    my $game_ref = ($games{$game_name}{"game"}); my %mgame = %$game_ref; 
    my $dips_ref = $games{$game_name}{"dips"}; my @dips = @$dips_ref;
    print "  <li class=\"set\">".&escapeHtml( $mgame{"description"} )." &mdash; ".&escapeHtml( $mgame{"manufacturer"} )." &lt;<a href=\"http://maws.mameworld.info/maws/set/".$mgame{"name"}."\">".$mgame{"name"}."</a>&gt; [<a href=\"http://maws.mameworld.info/maws/mamesource/src/mame/drivers/".$mgame{"sourcefile"}."\">".$mgame{"sourcefile"}."</a>]\n";
    if ( $show_dips && @dips ) {
     print "   <ul>\n";
     for($dLoop=0;$dLoop<@dips;$dLoop++) {
      print "    <li class=\"rom_".$dips[$dLoop]{"name"}."\">".$dips[$dLoop]{"name"}."</li>\n";
     }
     print "   </ul>\n";
    }
    print "  </li>\n";
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

