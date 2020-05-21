#! /usr/bin/perl

die "enriched_motifs.out\tClusterID\n" unless $#ARGV == 1;
my($input, $cluster) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

#cluster_4	5.5559989513226
#cluster_72	4.32332390874593
#cluster_50	3.81042792824585
#cluster_6	2.82492005933381
#cluster_77	2.76601000184211
#cluster_47	2.66335155853908
#cluster_38	2.62207676944108
#cluster_7	2.60813548878301

$line = "";
$SUCCESS = 0;
while($line = <IN>) {
	chomp($line);
	@array = split(/\t/, $line);
	if($cluster eq $array[0]) {
		print "Enrichment Score:\t$array[1]\n";
		close IN;
		exit;
	}
}
close IN;
print "Enrichment Score:\tNo Match\n";
