#!/usr/bin/perl

###############################################################################
#     sfvRenamer - Rename your files correctly with the .sfv file
#     Copyright (C) David Santiago
#  
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
##############################################################################

use warnings;
use utf8;
use strict;
use Getopt::Long;
use 5.010;
use Compress::Zlib;
use File::Basename;
use File::Copy qw/mv/;

my $SFVFile;


GetOptions("sfv=s"=>\$SFVFile) or die("Error in command line arguments");

if (!defined $SFVFile) {
    say "Please define a sfv file with the switch -sfv";
    exit 0;
}

my %SFV = ();

say "Loading SFV file";
open my $ifh, '<', $SFVFile;

while (my $line = <$ifh>){
    $line =~ s/\R//g;
    next if ($line =~/^;/);
    my @words = split(/ /, $line);
    my $hash = lc (pop @words);
    $SFV{$hash} = join(' ', @words);
    print ".";
}
close $ifh;
say "\nLoading complete!";

my %fileList = ();
say "Renaming 1st pass";
for (@ARGV) {
    my $file = $_;

    my ($fileName, $fileDirectory)=(fileparse($file));
    open my $ifh, '<', $file or die "Couldn't open file $file : $!";
    binmode $ifh;
    my $crc32 = 0;
    while (read ($ifh, my $input, 512*1024)!=0) {
        $crc32 = crc32($input,$crc32);
    }
    close $ifh;
    my $hash = sprintf("%08x",$crc32);
    if (exists $SFV{$hash}) {
        rename("$fileDirectory$fileName", "$fileDirectory".$SFV{$hash}."_rename") or die("Unable to rename $hash");
        $fileList{"$fileDirectory".$SFV{$hash}."_rename"}="$fileDirectory".$SFV{$hash};
    }  
}

say "Renaming 2nd pass";
for (keys %fileList){
    rename($_, $fileList{$_}) or die "unable to remove _rename";
}
say "Rename complete!";