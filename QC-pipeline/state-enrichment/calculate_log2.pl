#! /usr/bin/perl

die "SAMPLE_Freq\tCONTROL_Freq\tOutput_Log2File\n" unless $#ARGV == 2;
my($sample, $control, $log2) = @ARGV;

if($sample =~ /.gz$/) { open(SAM, "gunzip -c $sample |") || die "Can’t open pipe to $sample"; }
else { open(SAM, "<$sample") || die "Can't open $sample for reading!\n"; }
if($control =~ /.gz$/) { open(CON, "gunzip -c $control |") || die "Can’t open pipe to $control"; }
else { open(CON, "<$control") || die "Can't open $control for reading!\n"; }

open(OUT, ">$log2") or die "Can't open $log2 for writing!\n";

#	Promoter	Transcription	Enhancer	Insulator	Repressed	Heterochromatin
#chromHMM	0.128335130128875	0.22297897108593	0.376448494810037	0.0580111761292814	0.0574327848988639	0.156793442947013
#chromHMM	0.0193512886458898	0.190592257919302	0.0374488195674922	0.00422286956462047	0.043376960753577	0.705007803549119
#	Promoter	Transcription	Enhancer	Insulator	Repressed	Heterochromatin
#18327-USF1_v6_chromHMM	0.479591836734694	0.0612244897959184	0.0714285714285714	0.0306122448979592	0.122448979591837	0.23469387755102
#18327-USF1_v6_chromHMM	0.0355060943296237	0.0324021500492089	0.00227117874176698	0.000227117874176698	0.0121886592474828	0.917404799757741

$line1 = $line2 = "";
while($line1 = <SAM>) {
	$line2 = <CON>;
	chomp($line1);
	chomp($line2);
	@array1 = split(/\t/, $line1);
	@array2 = split(/\t/, $line2);
	if($array1[0] eq "") {
		print OUT $line1,"\n";
	} else {
		print OUT "Log2";
		for($x = 1; $x <= $#array1; $x++) {
			if($array1[$x] == 0 || $array2[$x] == 0) { print OUT "\tNaN"; }
			else {
				$LOG2 = log($array1[$x] / $array2[$x]) / log(2);
				print OUT "\t$LOG2";
			}
		}
		print OUT "\n";
	}
}
close SAM;
close CON;
close OUT;
