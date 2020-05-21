#! /usr/bin/perl

die "Cluster_File\n" unless $#ARGV == 0;
my($input) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

#XBP1
#CREB3
#CREB3L1
#Hes2
#USF2
#MITF
#Arnt
#Ahr::Arnt
#Creb3l2
#ARNT::HIF1A
#Id2
#Mlxip
#TFE3
#Arntl

print "JASPAR cluster components:\t";
$counter = 0;
while($line = <IN>) {
	chomp($line);
	if($counter == 0) { print $line; }
	else { print "|",$line; }
	$counter++;
}
close IN;
