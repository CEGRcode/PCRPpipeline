#! /usr/bin/perl

die "ClusterID_File\tClusterID\tOutput_Motifs\n" unless $#ARGV == 2;
my($input, $cluster, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";
open(OUT, ">$output") or die "Can't open $output for writing!\n";

#cluster_1	DUXA,DUX4,PROP1,Phox2b,PHOX2A,Arid3a,HOXA5,Crx,RHOXF1,OTX1,Pitx1,OTX2,PITX3,GSC,GSC2,Nkx2-5,NKX2-3,NKX2-8,ISL2,NKX3-2,Nkx3-1,HMBOX1,Arid3b,Lhx3,Dux,BARHL2,Barhl1,POU6F2,VENTX,Nobox,LBX1,PDX1,NKX6-1,NKX6-2,BARX1,BSX,EN1,LHX9,ISX,Shox2,SHOX,RAX2,Prrx2,PRRX1,UNCX,Dlx2,DLX6,Dlx3,Dlx4,MSX2,MSX1,Msx3,PAX4,Lhx8,LMX1B,LMX1A,Lhx4,VAX1,VAX2,VSX1,VSX2,mix-a,POU6F1,LHX6,LHX2,NOTO,MNX1,Dlx1,EN2,ALX3,MIXL1,GBX1,GBX2,RAX,HESX1,ESX1,LBX2,MEOX1,MEOX2,GSX1,GSX2,HOXA2,HOXB2,HOXB3,EVX1,EVX2,EMX1,EMX2
#cluster_2	RXRA::VDR,NR1H4,NR1A4::RXRA,NR4A2::RXRA,RARA,Rarb,Nr2f6_var.2_,Rarg,Tcf7,TCF7L1,TCF7L2,LEF1,Hnf4a,PPARA::RXRA,NR1H2::RXRA,HNF4G,Nr2f6,RXRB,Rxra,RXRG,NR2C2,Pparg::Rxra,VDR,Nr5a2,RORA_var.2_,RORC,RORA,RORB,Nr2e1,NR2F1,NR4A2,Esrra,Esrrg,NR4A1,ESRRB,NR2F2
#cluster_3	FOSL1::JUNB,FOSL1::JUN,FOS::JUND,FOSL2::JUN,FOS::JUNB,JDP2,NFE2,FOSL1,FOS,JUND,FOSL2,JUNB,JUN::JUNB,FOSL1::JUND,FOS::JUN,FOSL2::JUND,FOSB::JUNB,FOSL2::JUNB,BATF::JUN,JUN_var.2_,MAFK,MAFF,MAFG,Nfe2l2,Bach1::Mafk,MAF::NFE2,BACH2
#cluster_4	XBP1,CREB3,CREB3L1,Hes2,USF2,MITF,Arnt,Ahr::Arnt,Creb3l2,ARNT::HIF1A,Id2,Mlxip,TFE3,Arntl,USF1,BHLHE40,BHLHE41,TFEB,TFEC,MLXIPL,MLX,SREBF2_var.2_,Srebf1_var.2_,HEY2,HEY1,CLOCK,Npas2,MAX,MNT,Tcfl5,Hes1,MAX::MYC,MXI1,MYC,MYCN,HIF1A,HES5,HES7
#cluster_5	Gmeb1,GMEB2,CEBPA,CEBPG,CEBPD,CEBPB,CEBPE,NFIL3,HLF,DBP,TEF,PROX1,ATF4,Atf3,Atf1,Crem,JUN,JUND_var.2_,FOS::JUN_var.2_,FOSL2::JUND_var.2_,ATF7,BATF3,FOSL1::JUND_var.2_,JUNB_var.2_,FOSL1::JUN_var.2_,FOSB::JUNB_var.2_,FOSB::JUN,FOSL2::JUN_var.2_,CREB1,JUN::JUNB_var.2_,FOSL2::JUNB_var.2_,JDP2_var.2_,Creb5
#cluster_6	TFAP2A,TFAP2B_var.2_,TFAP2C_var.2_,TFAP2B_var.3_,TFAP2C_var.3_,TFAP2A_var.3_,TFAP2A_var.2_,TFAP2C,TFAP2B
#cluster_7	HINFP,SPIC,SPI1,ZBTB7A,Gabpa,ETV2,ELK4,ETV6,ETV5,FEV,ETV1,ETV4,FLI1,ERG,ETS1,ELK1,ELK3,ERF,ETV3,SPDEF,ELF5,ELF3,EHF,ELF1,ELF4
#cluster_8	HLTF,Bhlha15,BHLHE23,Twist2,Neurog1,OLIG1,BHLHE22,OLIG2,OLIG3,NEUROD2,Atoh1,NEUROG2,ZBTB18,TWIST1,NEUROD1,TAL1::TCF3
#cluster_9	PKNOX1,PKNOX2,TGIF1,TGIF2,MYB,SNAI2,ZEB1,FIGLA,ID4,TCF3,TCF4,TFAP4,MSC,MYF6,Myog,Tcf12,NHLH1,Ascl2,Tcf21,Myod1,ASCL1
#cluster_10	ONECUT3,ONECUT1,ONECUT2,PAX7,PAX3,CUX1,CUX2

$line = "";
$SUCCESS = 0;
while($line = <IN>) {
	chomp($line);
	@array = split(/\t/, $line);
	if($cluster eq $array[0]) {
		@MOTIF = split(/\,/, $array[1]);
		for($x = 0; $x <= $#MOTIF; $x++) {
			print OUT $MOTIF[$x],"\n";
		}
		$SUCCESS = 1;
	}
}
close IN;
if($SUCCESS == 0) { print OUT "No Match\n"; }
close OUT;