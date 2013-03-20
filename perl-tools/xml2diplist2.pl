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
my %kong_games = ();
my $output_csv = 0;

if ( $mame_xml =~ m/\-csv/i ) {
  $output_csv = 1;
  $mame_xml = shift;
}
my $dips_html = shift;

# ------------------------------------------------------------------ #
# main

( (-e $mame_xml) && (-r $mame_xml) && (-e $dips_html) && (-r $dips_html) ) ||
  die("Could not find XML file. Usage: perl xml2diplist2.pl [-csv] \"listinfo.xml\" \"crazy_kong_disp.html\" > diplist.[html|csv]");

# parse HTML
if ( open(INFILE, "< ".$dips_html) ) {
  @in_file_content = <INFILE>;
  $file_content = "@in_file_content";
  # href="/dips/10yard.txt">10 YARD FIGHT<
  while ($file_content =~ /href\=\"(\/dips\/.*?\.txt)\"\>(.*?)\</ig) {
    $kong_games{$2} = 'http://www.crazykong.com'.$1;
    # print $2 . " - " . $1 . "\n";
  }
  close(INFILE);
} else {
  die( "can't open HTML: ".$dips_html );
}

# parse XML
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
  my %cgame = %game;
  $games{ $game{"description"} }{ "game" } = \%cgame;
  if ( @unknown_dip_roms  ) {
   my @cunknown_dip_roms = @unknown_dip_roms;
   $games{ $game{"description"} }{ "dips" } = \@cunknown_dip_roms;
   $unknown_dip_count++;
  }
 }
}

sub StartDocument {
 my ($self) = @_;
 if ( $output_csv ) {
   print '"Game","Set","Driver","Manufacturer","Game Link","Driver Link","Unknown Dips","Crazy Kong Name","Crazy Kong Link"'."\n";
 } else {
   print "<html>\n<head>\n";
   print '<style type="text/css"> BODY { font-family: Arial, Helvetica, sans-serif; } UL, P { font-size: 10pt; } #manulist { margin: 0px; padding: 0px; } LI.manu { font-weight: bold; list-style-type: none; margin: 0px 0px 10px 0px; padding: 0px; } LI.set { font-weight: normal; list-style-type: none; margin: 0px; padding: 0px; } LI.rom_nodump, LI.rom_baddump { list-style-type: square; } LI.disk_nodump, LI.disk_baddump { list-style-type: disc; } </style>'."\n";
   print "</head>\n<body>\n";
   print "<h1>Games and dips</h1>\n";
   print "<ul id=\"#manulist\">\n";
 }
}

sub EndDocument {
 my ($self) = @_;
 foreach $game_name (sort keys %games ) {
   my $game_ref = ($games{$game_name}{"game"}); my %mgame = %$game_ref; 
   my $dips_ref = $games{$game_name}{"dips"}; my @dips = @$dips_ref;
   my $clean_name = &clean_name($mgame{"description"});
   if ( $output_csv ) {
     print '"'.$mgame{"description"}.'","'.$mgame{"name"}.'","'.$mgame{"sourcefile"}.'","'.$mgame{"manufacturer"}.'","http://www.mameworld.net/maws/set/'.$mgame{"name"}.'","http://www.mameworld.net/maws/mamesource/src/mame/drivers/'.$mgame{"sourcefile"}.'","';
     if ( @dips ) {
       print 'yes"';
     } else {
       print 'no"';
     }
     if ( $kong_games{ uc($clean_name) } ) {
       print ',"'.uc($mgame{"description"}).'","'.$kong_games{ uc($clean_name) }.'"';
     } else {
       print ',"",""';
     }
     print "\n";
   } else {
     print "  <li class=\"set\"><a href=\"http://www.mameworld.net/maws/set/".$mgame{"name"}."\">".&escapeHtml( $mgame{"description"} )."</a> &mdash; ".&escapeHtml( $mgame{"manufacturer"} )." [<a href=\"http://www.mameworld.net/maws/mamesource/src/mame/drivers/".$mgame{"sourcefile"}."\">".$mgame{"sourcefile"}."</a>]";
     if ( @dips ) {
       print " (has unknown dips)";
     }
     if ( $kong_games{ uc($clean_name) } ) {
       print ' &mdash; Crazy Kong <a href="'.$kong_games{ uc($clean_name) }.'">'.uc($clean_name).'</a>';
     } else {
       # print " &mdash; no Crazy Kong link";
     }
     print "</li>\n";
   }
   
   if ( $kong_games{ uc($clean_name) } ) {
     $kong_games{ uc($clean_name) } = 0; 
   }
 }
 if ( $output_csv ) {
   print "\n\n\n\n";
   print '"Unmatched Name","Unmatched URL"'."\n";
   foreach $kong_name (sort keys %kong_games ) {
     if ( $kong_games{ $kong_name } ) {
       print '"'.$kong_name.'","'.$kong_games{ $kong_name }.'"'."\n";
     }
   }
 } else {
   print "</ul>\n";
   print '<h2>Unmatched Crazy Kong Dip Entries</h2>'."\n";
   print '<ol>'."\n";
   foreach $kong_name (sort keys %kong_games ) {
     if ( $kong_games{ $kong_name } ) {
       print '  <li><a href="'.$kong_games{ $kong_name }.'">'.$kong_name.'</a></li>'."\n";
     }
   }
   print "</ol>\n";
   print "</body></html>\n";
 }
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

sub clean_name {
  my ( $game_name, @p ) = @_;
  $game_name =~ s/\&(.*?);//ig;
  $game_name =~ s/\(.*?\)//ig;
  $game_name =~ s/\[.*?\]//ig;
  $game_name =~ s/^(.*?)\s+\/\s+(.*?)$/$1/ig;
  $game_name =~ s/^\s+//ig;
  $game_name =~ s/\s+$//ig;
  return $game_name;
}


1;


__END__

