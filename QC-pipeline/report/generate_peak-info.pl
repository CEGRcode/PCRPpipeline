#! /usr/bin/perl

#peaks:       500
#sample frip:   2.84e-3
#control frip:  6.40e-4
#relative frip: 4.44

die "Binding-events\tSampleFRIP.out\tControlFRIP.out\tOutput_File\n" unless $#ARGV == 3;
my($bindingevents, $sFRIP, $cFRIP, $output) = @ARGV;
open(OUT, ">$output") or die "Can't open $output for writing!\n";

print OUT "peaks:\t$bindingevents\n";

open(SFRIP, "<$sFRIP") or die "Can't open $sFRIP for reading!\n";
$s = 0;
while(<SFRIP>) {
	chomp;
	next if(/tags/);
        @array = split(/\t/, $_);
	$s = $array[1];
	print OUT "sample frip:\t$s\n";
}
close SFRIP;

open(CFRIP, "<$cFRIP") or die "Can't open $cFRIP for reading!\n";
$c = 0;
while(<CFRIP>) {
        chomp;
        next if(/tags/);
        @array = split(/\t/, $_);
        $c = $array[1];
        print OUT "control frip:\t$c\n";
}
close CFRIP;

$r = 0;
if($c != 0) {
	$r = $s / $c;
}
print OUT "frip enrichment ratio:\t$r\n";
close OUT;
