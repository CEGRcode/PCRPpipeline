#! /usr/bin/perl

#INFO	2019-10-24 10:58:14	BamIndexStats	
#
#********** NOTE: Picard's command line syntax is changing.
#**********
#********** For more information, please see:
#********** https://github.com/broadinstitute/picard/wiki/Command-Line-Syntax-Transition-For-Users-(Pre-Transition)
#**********
#********** The command line looks like this in the new syntax:
#**********
#**********    BamIndexStats -I ../../KRAB_XO/BAM/H1hESC/KAP1_H1hESC_XO.bam
#**********
#
#
#10:58:14.851 INFO  NativeLibraryLoader - Loading libgkl_compression.so from jar:file:/gpfs/group/bfp2/default/pughlab-members/wkl2-WillLai/PCRP_Project/zz_QC-pipeline_v6/external_app/picard.jar!/com/intel/gkl/native/libgkl_compression.so
#[Thu Oct 24 10:58:14 EDT 2019] BamIndexStats INPUT=../../KRAB_XO/BAM/H1hESC/KAP1_H1hESC_XO.bam    VERBOSITY=INFO QUIET=false VALIDATION_STRINGENCY=STRICT COMPRESSION_LEVEL=5 MAX_RECORDS_IN_RAM=500000 CREATE_INDEX=false CREATE_MD5_FILE=false GA4GH_CLIENT_SECRETS=client_secrets.json USE_JDK_DEFLATER=false USE_JDK_INFLATER=false
#[Thu Oct 24 10:58:14 EDT 2019] Executing as wkl2@comp-bc-0357.acib.production.int.aci.ics.psu.edu on Linux 2.6.32-754.9.1.el6.x86_64 amd64; OpenJDK 64-Bit Server VM 1.8.0_212-b04; Deflater: Intel; Inflater: Intel; Provider GCS is not available; Picard version: 2.21.1-SNAPSHOT
#chr1 length=	249250621	Aligned= 9876522	Unaligned= 0
#chr2 length=	243199373	Aligned= 9471101	Unaligned= 0
#chr3 length=	198022430	Aligned= 7089465	Unaligned= 0
#chr4 length=	191154276	Aligned= 7608405	Unaligned= 0


die "Picard_Output\n" unless $#ARGV == 0;
my($input) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

$line = "";
$READCOUNT = 0;
$GENOMESIZE = 0;

while($line = <IN>) {
	chomp($line);
	next if($line =~ "INFO");
	@array = split(/\s+/, $line);
	if($#array == 6) {
	#	print $line,"\n";
		$READCOUNT += $array[4];
		$GENOMESIZE += $array[2];
	}
}
close IN;
print $READCOUNT;
