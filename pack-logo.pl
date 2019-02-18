#!/usr/bin/perl

# Copyright (C) 2019 Florent Revest <revestflo@gmail.com>
#               2012 Bruno Martins (bgcngm@XDA)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# You may not distribute nor sell this software or parts of it in 
# Source, Object nor in any other form without explicit permission obtained 
# from the original author. 

use v5.14;
use warnings;
use Compress::Zlib;
use Term::ANSIColor;
use File::Basename;
use Text::Wrap;

my $outfile = "logo.bin";
my ($logobin, $logo_length);
my (@raw_addr, @raw, @zlib_raw);

my $i = 0;
printf ("Repacking logo image...\n");
for my $inputfile (glob "./img[*.*") {
    my $extension = (fileparse($inputfile, qr/\.[^.]*/))[2];
    $inputfile =~ s/^.\///;
    
    if ($extension eq ".rgb565") {
        open (RGB565FILE, "$inputfile")
            or die colored ("\n" . wrap("","       ","Error: Couldn't open image file '$inputfile'!"), 'red') . "\n";
        my $input;
            while (<RGB565FILE>) {
            $input .= $_;
        }
        close (RGB565FILE);
        print "Packing '$inputfile'\n";
        $raw[$i] = $input;
    } else {
        next;
    }

    # Deflate all rgb565 images (compress zlib rfc1950)
    $zlib_raw[$i] = compress($raw[$i],Z_BEST_COMPRESSION);

    $i++;
}
die colored ("\n" . wrap("","       ","Error: Couldn't find any .rgb565 file"), 'red') . "\n"
    unless $i > 0;

my $num_blocks = $i;
print "Number of images found and packed into new logo image: $num_blocks\n";

$logo_length = (4 + 4 + $num_blocks * 4);
# Calculate the start address of each rgb565 image and the new file size
for my $i (0 .. $num_blocks - 1) {
    $raw_addr[$i] = $logo_length;
    $logo_length += length($zlib_raw[$i]);
}

$logobin = pack('L L', $num_blocks, $logo_length);

for my $i (0 .. $num_blocks - 1) {
    $logobin .= pack('L', $raw_addr[$i]);
}

for my $i (0 .. $num_blocks - 1) {
    $logobin .= $zlib_raw[$i];
}

# Generate logo header according to the logo size
my $logo_header = pack('a4 L a32 a472', "\x88\x16\x88\x58", $logo_length, "LOGO", "\xFF"x472);
$logobin = $logo_header . $logobin;

# Create the output file
open (LOGOFILE, ">$outfile")
    or die colored ("\n" . wrap("","       ","Error: Couldn't create output file '$outfile'!"), 'red') . "\n";
binmode (LOGOFILE);
print LOGOFILE $logobin or die;
close (LOGOFILE);

if (-e $outfile) {
    print colored ("\nSuccessfully repacked logo image into '$outfile'.", 'green') . "\n";
}

