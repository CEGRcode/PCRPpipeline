#! /usr/bin/perl

#heatmap upper threshold: 8.09819542589
#heatmap lower threshold: 0

die "*_contrast.out\n" unless $#ARGV == 0;
my($input) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

while($line = <IN>) {
	chomp($line);
	@array = split(/\t/, $line);
	if($array[0] =~ "upper threshold") {
		print $array[1],"\n";
	}
}
close IN;
