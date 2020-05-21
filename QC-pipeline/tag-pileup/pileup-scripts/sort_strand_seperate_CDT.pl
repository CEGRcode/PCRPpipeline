#! /usr/bin/perl/

die "Sense_CDT\tAnti_CDT\tOutput_Sense_CDT\tOutput_Anti_CDT\n" unless $#ARGV == 3;
my($sense, $anti, $outsense, $outanti) = @ARGV;
open(SENSE, "<$sense") or die "Can't open $sense for reading!\n";
open(ANTI, "<$anti") or die "Can't open $anti for reading!\n";

open(SOUT, ">$outsense") or die "Can't open $outsense Sense for writing!\n";
open(AOUT, ">$outanti") or die "Can't open $outanti Anti for writing!\n";

@CDT = ();
$line1 = "";
$line2 = "";
while($line1 = <SENSE>) {
	$line2 = <ANTI>;
	chomp($line1);
	chomp($line2);
	@array1 = split(/\t/, $line1);
	@array2 = split(/\t/, $line2);

	if($#array1 != $#array2) {
		print "Unequal array lengths!!!\n$sense\n$anti\n";
		exit(1);
	}
	$SUM = 0;
	if($line1 =~ "YORF") {
		print SOUT $line1,"\n";
		print AOUT $line2,"\n";
	} else {
		for($x = 2; $x <= $#array1; $x++) {
			$SUM += ($array1[$x] + $array2[$x]);
		}
		push(@CDT, {sense => $line1, anti => $line2, sum => $SUM});
	}
}
close SENSE;
close ANTI;
@FINAL = sort { $$b{'sum'} <=> $$a{'sum'} } @CDT;

for($x = 0; $x <= $#FINAL; $x++) {
	print SOUT $FINAL[$x]{'sense'},"\n";
	print AOUT $FINAL[$x]{'anti'},"\n";
}
close SOUT;
close AOUT;
