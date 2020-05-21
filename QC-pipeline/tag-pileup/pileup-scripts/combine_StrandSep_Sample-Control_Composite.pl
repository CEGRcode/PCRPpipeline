#! /usr/bin/perl/

die "Sample_Composite\tControl_Composite\tOutput_File\n" unless $#ARGV == 2;
my($sample, $control, $output) = @ARGV;

open(OUT, ">$output") or die "Can't open $output Sense for writing!\n";
print OUT "\"Xaxis\": \"";

open(SAM, "<$sample") or die "Can't open $sample for reading!\n";
$line = <SAM>;
chomp($line);
@array = split(/\t/, $line);
for($x = 1; $x <= $#array; $x++) {
	print OUT $array[$x];
	if($x < $#array) { print OUT ","; }
}
print OUT "\"\n";
print OUT "\"sampleSenseYaxis\": \"";
$line = <SAM>;
chomp($line);
@array = split(/\t/, $line);
for($x = 1; $x <= $#array; $x++) {
        print OUT sprintf("%.2f",$array[$x]);
        if($x < $#array) { print OUT ","; }
}
print OUT "\"\n"; 
print OUT "\"sampleAntiYaxis\": \"";
$line = <SAM>;
chomp($line);
@array = split(/\t/, $line);
for($x = 1; $x <= $#array; $x++) {
        print OUT sprintf("%.2f",$array[$x]);
        if($x < $#array) { print OUT ","; }
}
print OUT "\"\n";
close SAM;

open(CON, "<$control") or die "Can't open $control for reading!\n";
$line = <CON>;
print OUT "\"controlSenseYaxis\": \"";
$line = <CON>;
chomp($line);
@array = split(/\t/, $line);
for($x = 1; $x <= $#array; $x++) {
        print OUT sprintf("%.2f",$array[$x]);
        if($x < $#array) { print OUT ","; }
}
print OUT "\"\n";
print OUT "\"controlAntiYaxis\": \"";
$line = <CON>;
chomp($line);
@array = split(/\t/, $line);
for($x = 1; $x <= $#array; $x++) {
        print OUT sprintf("%.2f",$array[$x]);
        if($x < $#array) { print OUT ","; }
}
print OUT "\"\n";
close CON;
close OUT;
