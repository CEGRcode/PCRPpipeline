#! /usr/bin/perl

die "FLAGSTAT_Output_File\tOutput_Reads\n" unless $#ARGV == 1;
my($input, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";
open(OUT, ">$output") or die "Can't open $output for writing!\n";

# 3515572 + 0 in total (QC-passed reads + QC-failed reads)
# 0 + 0 secondary
# 0 + 0 supplementary
# 0 + 0 duplicates
# 3515572 + 0 mapped (100.00% : N/A)
# 3515572 + 0 paired in sequencing
# 1800248 + 0 read1
# 1715324 + 0 read2
# 3421752 + 0 properly paired (97.33% : N/A)
# 3428016 + 0 with itself and mate mapped
# 87556 + 0 singletons (2.49% : N/A)
# 5446 + 0 with mate mapped to a different chr
# 3443 + 0 with mate mapped to a different chr (mapQ>=5)

$line = "";
while($line = <IN>) {
	chomp($line);
	@array = split(/\s+/, $line);
	
	if($array[3] eq "read1") {
		print OUT $array[0],"\n";
	}
}
close IN;
close OUT;
