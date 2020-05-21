#! /usr/bin/perl

die "BED_File\tWindow_Size(bp)\tOutput_BED\n" unless $#ARGV == 2;
my($input, $SIZE, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";
open(OUT, ">$output") or die "Can't open $output for writing!\n";

#chr17	878	880	cw_distance=330	2.0	.
#chr17	1320	1322	cw_distance=353	2.0	.
#chr17	4844	4846	cw_distance=260	3.0	.
#chr17	8621	8623	cw_distance=279	2.0	.

$line = "";
while($line = <IN>) {
	chomp($line);
	next if($line =~ "track" || $line =~ "#");
	@array = split(/\t/, $line);
	if($array[1] >= 0) {
		$CENTER = int(($array[1] + $array[2]) / 2);
		if(($array[2] - $array[1]) % 2 != 0 && $array[5] eq "+") {
			$CENTER++;
		}
		$START = $CENTER - int($SIZE / 2);
		$STOP = $CENTER + int($SIZE / 2);
		print OUT "$array[0]\t$START\t$STOP";
		for($x = 3; $x <= $#array; $x++) {
			print OUT "\t$array[$x]";
		}
		print OUT "\n";
	} else {
		print "Invalid Coordinate in File!!!\n",$line,"\n";
	}
}
close IN;
close OUT;
