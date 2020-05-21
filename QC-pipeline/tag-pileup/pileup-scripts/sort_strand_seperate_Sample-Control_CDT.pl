#! /usr/bin/perl/

die "Sense-Sample\tAnti-Sample\tSense-Control\tAnti-Control\tSample_Output_Name\tControl_Output-Name\n" unless $#ARGV == 5;
my($Ssense, $Santi, $Csense, $Canti, $Sout, $Cout) = @ARGV;
open(SS, "<$Ssense") or die "Can't open $Ssense for reading!\n";
open(SA, "<$Santi") or die "Can't open $Santi for reading!\n";
open(CS, "<$Csense") or die "Can't open $Csense for reading!\n";
open(CA, "<$Canti") or die "Can't open $Canti for reading!\n";

open(SSOUT, ">$Sout\_sense.tabular") or die "Can't open $Sout\_sense.tabular for writing!\n";
open(SAOUT, ">$Sout\_anti.tabular") or die "Can't open $Sout\_anti.tabular for writing!\n";
open(CSOUT, ">$Cout\_sense.tabular") or die "Can't open $Cout\_sense.tabular for writing!\n";
open(CAOUT, ">$Cout\_anti.tabular") or die "Can't open $Cout\_anti.tabular for writing!\n";

@CDT = ();
$line1 = $line2 = $line3 = $line4 = "";
while($line1 = <SS>) {
	$line2 = <SA>;
	$line3 = <CS>;
	$line4 = <CA>;
	chomp($line1);
	chomp($line2);
	chomp($line3);
	chomp($line4);
	@array1 = split(/\t/, $line1);
	@array2 = split(/\t/, $line2);

	if($#array1 != $#array2) {
		print "Unequal array lengths!!!\n$Ssense\n$Santi\n";
		exit(1);
	}
	$SUM = 0;
	if($line1 =~ "YORF") {
		print SSOUT $line1,"\n";
		print SAOUT $line2,"\n";
		print CSOUT $line3,"\n";
                print CAOUT $line4,"\n";
	} else {
		for($x = 2; $x <= $#array1; $x++) {
			$SUM += ($array1[$x] + $array2[$x]);
		}
		push(@CDT, {Ssense => $line1, Santi => $line2, Csense => $line3, Canti => $line4, sum => $SUM});
	}
}
close SS;
close SA;
close CS;
close CA;
@FINAL = sort { $$b{'sum'} <=> $$a{'sum'} } @CDT;

for($x = 0; $x <= $#FINAL; $x++) {
	print SSOUT $FINAL[$x]{'Ssense'},"\n";
	print SAOUT $FINAL[$x]{'Santi'},"\n";
        print CSOUT $FINAL[$x]{'Csense'},"\n";
        print CAOUT $FINAL[$x]{'Canti'},"\n";
}
close SSOUT;
close SAOUT;
close CSOUT;
close CAOUT;
