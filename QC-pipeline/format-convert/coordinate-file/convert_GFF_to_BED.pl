#! /usr/bin/perl

die "GFF_Files\tBED_File\n" unless $#ARGV == 1;
my($input, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";
open(OUT, ">$output") or die "Can't open $output for writing!\n";

##2018-02-01 18:38:44.352;localbam.bam;READ1
#chrom	index	forward	reverse	value
#chr1	10004	1	0	1
#chr1	10005	1	0	1
#chr1	10011	1	0	1
#chr1	10016	1	0	1

#chr1	genetrack	.	123950	123970	22	+	.	stddev=0.0
#chr1	genetrack	.	565745	565765	12	+	.	stddev=0.0
#chr1	genetrack	.	565793	565813	44	+	.	stddev=0.298065387468

$line = "";
while($line = <IN>) {
	chomp($line);
	$char = substr $line, 0, 1;
	next if($line =~ /index/ || $char eq "#");
	$line =~ s/\r//g;
	@array = split(/\t/, $line);
	$NAME = $array[8];
	$SCORE = $array[5];
	$DIR = $array[6];
	if($array[3] >= 1) {
		$START = $array[3] - 1;
		print OUT "$array[0]\t$START\t$array[4]\t$NAME\t$SCORE\t$DIR\n";
	} else {
		print "Invalid Coordinate in File!!!\n$line";
	}
}
close IN;
close OUT;
