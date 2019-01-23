#!/usr/bin/perl

# feed-builder.pl
#
# © Copyright, 2005 By John Bokma, http://johnbokma.com/
#
# $Id: feed-builder.pl 1091 2008-09-30 19:14:36Z john $

use strict;
use warnings;

use File::Find;
use XML::Atom::SimpleFeed;
use Getopt::Long;

use POSIX 'strftime';

my $domain;
my $dir;
my $title;
my $description;
my $items = 99;
my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;

GetOptions(

  "dir=s"    => \$dir,
  "domain=s" => \$domain,
  "title=s"  => \$title,
  "desc=s"   => \$description,
  "items=i"  => \$items,

) or show_help();

(
        defined $dir
    and defined $domain
    and defined $title
    and defined $description

) or show_help();

# scan the given (web) directory for mp3 files and
# obtain the modification time of each found.
my %file2time;

find sub {

  -f or return;
  /\.(mp3)|(flac)?$/ or return;

  $file2time{$File::Find::name} = (stat)[9];

}, $dir;

# sort the filenames on modification time, descending.
my @filenames = sort {

  $file2time{$b} <=> $file2time{$a}

} keys %file2time;

# keep the $items most recent ones
@filenames = splice @filenames, 0, $items;

# create the ATOM file
my $feed = XML::Atom::SimpleFeed->new(
  title   => $title,
  id      => $domain,
  link    => "http://$domain/",
  link    => { rel => 'self', href => 'http://example.org/atom', },
  updated => $now,
  author  => 'Cord Horeis',
);

# add an item for each filename
for my $filename (@filenames)
{

  my ( $title, $description ) = get_title_and_description($filename);

  my $link = "http://$domain" . substr $filename, length $dir;
  $link =~ s/index\.html?$//;

  my $type="MP3";

  if ($filename =~ m/.+\.flac$/) 
  {
    $type="FLAC";
  }
  else
  {
    $type="MP3";
  }

  $feed->add_entry(
    title => $title,
    id    => $link,
    link  => {
      rel   => "enclosure",
      type  => "audio/mpeg",
      title => $type,
      href  => $link
    },
    content  => $description,
    updated  => format_date_time( $file2time{$filename} ),
    category => 'Audiorecorder',
  );
}
$feed->print;

sub show_help
{

  print <<HELP;
Usage: feed-builder [options] > index.rss
Options:
    --dir       path to the document root
    --domain    domain name
    --title     title of feed
    --desc      description of feed
    --items     number of items in feed
                (default is 12)

Only --items is optional
HELP

  exit 1;
}

# formats date and time for use in the RSS feed
sub format_date_time
{

  my ($time) = @_;

  my @time = gmtime $time;

  my $filetime = strftime '%Y-%m-%dT%H:%M:%SZ', @time;

  return $filetime;
}

# extracts a title and a description from the given HTML file
sub get_title_and_description
{

  my $filename = shift;

  #Datei hat folgenden Namen: YYYY-MM-DD_Beschreibung_Sendumg.mp3
  $filename =~ m/.*(\d{4}-\d{2}-\d{2})_(.*).((mp3)|(flac))/;
  my $datum        = $1;
  my $beschreibung = $2;

  #Der Dateiname ohne Pfad
  $filename =~ m/.*\/(.+\.((mp3)|(flac)))/;
  my $filename_ohne_pfad = $1;

  $datum =
    ( defined $datum && $datum ne '' )
    ? $datum
    : 'no_date';
  $beschreibung =
    ( defined $beschreibung && $beschreibung ne '' )
    ? $beschreibung
    : $filename_ohne_pfad;

  return ( "$beschreibung", "Datum: $datum" );
}
