#!/usr/bin/perl 

# ------------------------------------------------------------------ #
# includes

use XML::SAX;

# ------------------------------------------------------------------ #
# initialise

my $parser = XML::SAX::ParserFactory->parser( Handler => MameXmlSimple->new );
my $mame_xml = shift;
my %games = ();
        
my %parser_args = (Source => {SystemId => $mame_xml});
$parser->parse(%parser_args);

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
use strict;
use base qw(XML::SAX::Base);

my (%game, $current_element, $game_count);

sub new {
  my $type = shift;
  return bless {}, $type;
}
 
sub start_element {
  my ($self, $element) = @_;

  if ($element->{Name} eq 'game') {
    %game = ();
    $game_count++;
#	<game name="supnudg2" sourcefile="coinmstr.c">
#		<description>Super Nudger II (Version 5.21)</description>
#		<year>1989</year>
#		<manufacturer>Coinmaster</manufacturer>
#		<rom name="2-2.41" size="8192" crc="756dd230" sha1="6d6f440bf1f48cc33d5e46cfc645809d5f8b1f3a" region="gfx1" dispose="yes" offset="2000"/>
#		<rom name="questions.bin" size="655360" region="user1" status="nodump" offset="0"/>
#		<disk name="kinst2" merge="kinst2" sha1="ab0242233d2eaf9d907abe246a54e09a8a2561a5" md5="2563b089b316f2c8636d78af661ac656" region="disks" index="0"/>
  } elsif ($element->{Name} eq 'rom') {
    # get attributes
    $current_element = 'rom';
  } elsif ($element->{Name} eq 'disk') {
    # get attributes
    $current_element = 'disk';
  } else {
    $current_element = $element->{Name};
  }
}

sub characters {
  my ($self, $characters) = @_;
  my $text = $characters->{Data};
  # clear white space
  $text =~ s/^\s*//;
  $text =~ s/\s*$//;
  $game{$current_element} .= $text if $text;
}

sub end_element {
  my ($self, $element) = @_;
  if ($element->{Name} eq 'game')  {
    # $games{ $game{"manufacturer"} }{ $game{"description"} } = \%game; 
    print "Game ".$game_count."\n";
    print "  - ".$game{"description"}." (".$game{"year"}." ".$game{"manufacturer"}.")\n";
  }
}
     
sub start_document {
  my ($self) = @_;
  print "Starting SAX MAME XML reader\n";
}

sub end_document {  
  my ($self) = @_;
  print "SAX SAX MAME XML reader Finished\n$game_count of games processed\n";
}
        
1;


__END__
