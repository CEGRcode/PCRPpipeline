#! /usr/bin/perl

die "transfac_PWM_File\tMEME_Output_tile\n" unless $#ARGV == 1;
my($input, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";
open(OUT, ">$output") or die "Can't open $output for writing!\n";

#DE	meme2Motif6	
#0	1.000000	0.000000	0.000000	0.000000	A
#1	0.000000	0.000000	1.000000	0.000000	G
#2	0.714286	0.285714	0.000000	0.000000	A
#3	0.000000	0.000000	0.000000	1.000000	T
#4	1.000000	0.000000	0.000000	0.000000	A
#5	0.000000	1.000000	0.000000	0.000000	C
#6	1.000000	0.000000	0.000000	0.000000	A
#7	0.000000	0.000000	1.000000	0.000000	G
#8	0.000000	0.000000	0.000000	1.000000	T
#9	0.000000	0.000000	0.000000	1.000000	T
#10	0.000000	1.000000	0.000000	0.000000	C
#11	0.000000	1.000000	0.000000	0.000000	C
#12	0.000000	1.000000	0.000000	0.000000	C
#XX

print OUT "MEME version 4\n\n";
print OUT "ALPHABET= ACGT\n\n";
print OUT "strands: + -\n\n";
print OUT "Background letter frequencies\n";
print OUT "A 0.295 C 0.205 G 0.205 T 0.295\n\n";

@MATRIX = ();
$loadMATRIX = 0;
$MOTIFNUM = 0;
$line = "";
while($line = <IN>) {
	chomp($line);
	@array = split(/\t/, $line);
	if($array[0] eq "DE") {
		$loadMATRIX = 1;
		print OUT "MOTIF Subtype$MOTIFNUM\n";
		$MOTIFNUM++;
	} elsif($array[0] eq "XX") {
		$LENGTH = $#MATRIX + 1;
		print OUT "letter-probability matrix: alength= 4 w= $LENGTH\n";
		for($r = 0; $r <= $#MATRIX; $r++) {
		        print OUT $MATRIX[$r][0];
		        for($c = 1; $c < $#{$MATRIX[$r]}; $c++) {
	                	print OUT "\t",$MATRIX[$r][$c];
			}
			print OUT "\n";
	        }
        	print OUT "\n";
		@MATRIX = ();
		$loadMATRIX = 0;
	} elsif($loadMATRIX == 1) {
		@ROW = ();
		for($x = 1; $x <= $#array; $x++) {
         	       push(@ROW, $array[$x]);
	        }
        	push(@MATRIX, [@ROW]);
	}
}
close OUT;
