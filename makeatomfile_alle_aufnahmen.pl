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
use Encode qw(decode encode);

use POSIX 'strftime';

my $domain = "debianvm.vp9jo7nkxeiahn6f.myfritz.net";
my $dir1 = "/mnt/qnap_vdr/";
my $dir2 = "/video0/";
my $title = "Alle Aufnahmen";
my $description = "Liste der letzten 99 Aufnahmen des VDRs";
my $items = 99;
my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;
my $outfile = "/tmp/aufnahmen.xml";

# create the ATOM file
my $feed = XML::Atom::SimpleFeed->new(
  title   => $title,
  id      => "$domain 123456",
  link    => "http://$domain/",
  link    => { rel => 'self', href => 'http://pi.vp9jo7nkxeiahn6f.myfritz.net/easyvdr/aufnahmen.xml', },
  updated => $now,
  author  => 'Cord Horeis',
);


# scan the given (web) directory for info files and
# obtain the modification time of each found.
my %file2time;

print STDOUT "Searching in $dir1\n";
find sub {

  -f or return;
  /\.ts$/ or return;

  $file2time{$File::Find::name} = (stat)[9];

}, $dir1;

print STDOUT "Finished searching...\n";

# sort the filenames on modification time, descending.
my @filenames = sort {

  $file2time{$b} <=> $file2time{$a}

} keys %file2time;

print STDOUT "Finished sorting...\n";

# keep the $items most recent ones
@filenames = splice @filenames, 0, $items;
foreach (@filenames) {
	my $filename = $_;
#	my $titel;
#	my $kurztext;
#	my $beschreibung;
#	open(DATA, "$filename") || die("Can't open $filename:!\n");
#	while ( my $line =  <DATA> ) {
#		chomp($line);
#		$line =~ m/^T (.+)$/;
#		if( defined $1) {
#			$titel = $1;
#		}
#		
#		$line =~ /^S (.+)$/;
#		if( defined $1) {
#			$kurztext = $1;
#		}
#		
#		$line =~ /^D (.+)$/;
#		if( defined $1) {
#			$beschreibung = $1;
#		}
#	}
	$feed->add_entry(
    title => $filename,
    id    => $filename,
    content  => $filename,
    updated  => format_date_time( $file2time{$filename} ),
    category => 'Video',
  );
#  close DATA;
}

print STDOUT "Finished cutting...\n";

open(my $fh, ">", "$outfile") || die("Can't open $outfile:!\n");
$feed->print($fh);
close $fh;

print STDOUT "Finished writing...\n";

#system('/usr/bin/sudo -H -u easyvdr /usr/bin/scp /tmp/aufnahmen.xml pi@pi:/var/www/html/easyvdr/aufnahmen.xml');
system('/usr/bin/scp /tmp/aufnahmen.xml admin@qnap:/share/appdata/nginx-local/html/');

print STDOUT "Finished scp...\n";

# formats date and time for use in the RSS feed
sub format_date_time
{
  my ($time) = @_;

  my @time = gmtime $time;

  my $filetime = strftime '%Y-%m-%dT%H:%M:%SZ', @time;

  return $filetime;
}

