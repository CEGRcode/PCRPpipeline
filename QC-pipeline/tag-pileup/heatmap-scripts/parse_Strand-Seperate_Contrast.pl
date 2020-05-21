#! /usr/bin/perl

#heatmap upper threshold: 8.09819542589
#heatmap lower threshold: 0

die "Sense_contrast.out\tAnti_contrast.out\n" unless $#ARGV == 1;
my($sense, $anti) = @ARGV;
open(SEN, "<$sense") or die "Can't open $sense for reading!\n";
open(ANT, "<$anti") or die "Can't open $anti for reading!\n";

while($line1 = <SEN>) {
	$line2 = <ANT>;
	chomp($line1);
	chomp($line2);
	@array1 = split(/\t/, $line1);
	@array2 = split(/\t/, $line2);
	if($array1[0] =~ "upper threshold" || $array2[0] =~ "upper threshold") {
		if($array1[1] > $array1[1]) { print $array1[1],"\n"; }
		else { print $array2[1],"\n"; }
	}
}
close IN;
