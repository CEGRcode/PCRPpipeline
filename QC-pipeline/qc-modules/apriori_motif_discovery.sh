#!/bin/sh

# Required software for this module:
# python 2.7.14
# python - matplotlib
# Java 8 or later
# perl

# bedtools

usage()
{
    echo 'apriori_motif_discovery.sh -i <INPUT PATH> -s <SampleID> -c <ControlID> -a <Path to scripts> -r <Path to references>'
    exit
}

if [ "$#" -ne 10 ]
then
    usage
fi

while getopts ":i:s:c:a:r:" IN; do
    case "${IN}" in
        i)
            INPUT=${OPTARG}
            ;;
        s)
            SAMPLEID=${OPTARG}
            ;;
        c)
            CONTROLID=${OPTARG}
            ;;
        a)
            SCRIPT=${OPTARG}
            ;;
        r)
            REF=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${INPUT}" ] || [ -z "${SAMPLEID}" ] || [ -z "${CONTROLID}" ] || [ -z "${SCRIPT}" ] || [ -z "${REF}" ]; then
    usage
fi

echo "i = ${INPUT}"
echo "s = ${SAMPLEID}"
echo "c = ${CONTROLID}"
echo "a = ${SCRIPT}"
echo "r = ${REF}"

#Load modules
module load python/2.7.14-anaconda5.0.1

SPEAK=$INPUT/peak_calling/$SAMPLEID\_peak.bed
SBAM=$INPUT/$SAMPLEID\.bam
CBAM=$INPUT/$CONTROLID\.bam

# Genome FASTA file
GENOME=$REF/Genome/hg19.fa
# Motif datafiles
MOTIFDATABASE=$REF/Motif_Coord/hg19_JASPAR2020_MotifCluster.gff.gz
MOTIFCOUNT=$REF/Motif_Coord/hg19_JASPAR2020_cluster_occurrence.tab
MOTIFLOGO=$REF/Motif_Coord/JASPAR2020_weblogo
MOTIFID=$REF/Motif_Coord/JASPAR2020_cluster_ID.out

# BED/GFF manipulation
BEDEXPAND=$SCRIPT/format-convert/coordinate-file/expand_BED.pl
CONVERT=$SCRIPT/format-convert/coordinate-file/convert_GFF_to_BED.pl

# Motif enrichment scripts
ENRICH=$SCRIPT/motif-enrichment/motif-cluster/calculate_Log2_MotifEnrichment.pl
MATCHMOTIF=$SCRIPT/motif-enrichment/motif-cluster/get_Motif_from_ClusterID.pl
ENRICHMENTSCORE=$SCRIPT/motif-enrichment/motif-cluster/get_EnrichmentScore.pl
SPLITMOTIFS=$SCRIPT/format-convert/coordinate-file/split_GFF_by_motif.pl
PARSECLUSTER=$SCRIPT/motif-enrichment/motif-cluster/parse_JASPAR_Cluster_components.pl
PEAKEXPAND=100
TOPMOTIF=10
LOG2THRESH=1.5

# Pileup
TAGPILEUP=$SCRIPT/tag-pileup/pileup-scripts/TagPileup.jar
SORTCDT=$SCRIPT/tag-pileup/pileup-scripts/sort_strand_seperate_Sample-Control_CDT.pl
PARSECOMPOSITE=$SCRIPT/tag-pileup/pileup-scripts/combine_StrandSep_Sample-Control_Composite.pl
CONTRAST=$SCRIPT/tag-pileup/heatmap-scripts/calculate_Contrast_Threshold.py
PARSE=$SCRIPT/tag-pileup/heatmap-scripts/parse_Strand-Seperate_Contrast.pl
HEATMAP=$SCRIPT/tag-pileup/heatmap-scripts/jHeatmap.jar
HEATMAPMERGE=$SCRIPT/tag-pileup/heatmap-scripts/jMergeHeatmap.jar
HEATMAPLABEL=$SCRIPT/tag-pileup/heatmap-scripts/label_Heatmap.py
HEATROW=500
HEATCOL=200
# Pileup parameters
CPU=2
PEXPANSION=500
HEATXAXIS="-250,0,250"

# FourColour
FOURCOLOUR=$SCRIPT/motif-enrichment/fourcolour_plot/FourColorPlot.jar
FOURSIZE=30
FOURXAXIS="-15,0,15"
RESIZEPNG=$SCRIPT/motif-enrichment/fourcolour_plot/resize_png.py
COLORROW=500
COLORCOL=100

mkdir -p $INPUT/apriori_motif_enrichment
cd $INPUT/apriori_motif_enrichment
# Not enough peaks to determine a priori motif enrichment, ending this pipeline module
if [ 10 -gt $(wc -l < $SPEAK) ]; then
        echo "Insufficient starting peaks to test for a priori enrichment"
        exit 0
fi

sort -k1,1 -k2,2n $SPEAK > peak_sort.bed
perl $BEDEXPAND peak_sort.bed $PEAKEXPAND peak_w_border.bed
# Intersect peaks with known genomic motifs
bedtools intersect -sorted -u -a $MOTIFDATABASE -b peak_w_border.bed > overlap.gff
# Clean up intermediary file
rm -f peak_sort.bed peak_w_border.bed
# Calculate motif occurance enrichment over uniform background
perl $ENRICH overlap.gff $MOTIFCOUNT $PEAKEXPAND enriched_motifs.out
# Split overlapping motifs into seperate files
mkdir -p $INPUT/apriori_motif_enrichment/enrichedmotifs
perl $SPLITMOTIFS overlap.gff enriched_motifs.out $TOPMOTIF $LOG2THRESH $INPUT/apriori_motif_enrichment/enrichedmotifs/motif
rm overlap.gff

# If no motifs pass Enrichment threshold, then we should end this section of the pipeline
if [ 1 -gt $(ls $INPUT/apriori_motif_enrichment/enrichedmotifs/*.gff 2>/dev/null | wc -w) ]; then
	echo "No enriched overlapping motifs discovered"
        exit 0
fi

# Convert enriched motifs to BED for plot generation
cd $INPUT/apriori_motif_enrichment/enrichedmotifs
for file in *.gff
do
	var=$(echo $file | awk -F"." '{print $1}')
	set -- $var
	perl $CONVERT $file $INPUT/apriori_motif_enrichment/$SAMPLEID\_$1\.bed
done

# Make tag pileup at motif midpoints
mkdir -p $INPUT/apriori_motif_enrichment/tagpileup
cd $INPUT/apriori_motif_enrichment
for file in *.bed
do
	var=$(echo $file | awk -F"." '{print $1}')
        set -- $var
        perl $BEDEXPAND $1\.bed $PEXPANSION $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp.bed

        # Tag pileup at motif midpoints
        java -jar $TAGPILEUP -b $SBAM -i $SBAM\.bai -c $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp.bed -t $CPU -w 5 -e true -x $INPUT/apriori_motif_enrichment/tagpileup/$1\_SAMPLE-C.out -o $INPUT/apriori_motif_enrichment/tagpileup
        java -jar $TAGPILEUP -b $CBAM -i $CBAM\.bai -c $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp.bed -t $CPU -w 5 -e true -x $INPUT/apriori_motif_enrichment/tagpileup/$1\_CONTROL-C.out -o $INPUT/apriori_motif_enrichment/tagpileup
        perl $PARSECOMPOSITE $INPUT/apriori_motif_enrichment/tagpileup/$1\_SAMPLE-C.out $INPUT/apriori_motif_enrichment/tagpileup/$1\_CONTROL-C.out $INPUT/apriori_motif_enrichment/tagpileup/$1\_composite.out
        # Make pileup heatmaps
        perl $SORTCDT $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_$SAMPLEID\_read1_sense.tabular $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_$SAMPLEID\_read1_anti.tabular $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_CONTROL_read1_sense.tabular $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_CONTROL_read1_anti.tabular $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_CONTROL_SORT
        #Calculate contrast ratio based on sample
        python $CONTRAST -i $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_sense.tabular -o $INPUT/apriori_motif_enrichment/tagpileup/sense_heatmap_contrast.out -q 90 -d T -s 2 -r $HEATROW -l $HEATCOL
        python $CONTRAST -i $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_anti.tabular -o $INPUT/apriori_motif_enrichment/tagpileup/anti_heatmap_contrast.out -q 90 -d T -s 2 -r $HEATROW -l $HEATCOL
        SCALE="$(perl $PARSE $INPUT/apriori_motif_enrichment/tagpileup/sense_heatmap_contrast.out $INPUT/apriori_motif_enrichment/tagpileup/anti_heatmap_contrast.out)"
        # Generate sample heatmap
        java -jar $HEATMAP -m $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_sense.tabular -o $INPUT/apriori_motif_enrichment/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_SENSE -a $SCALE -C 0,0,255 -r 1 -c 2 -h $HEATROW -w $HEATCOL
        java -jar $HEATMAP -m $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_anti.tabular -o $INPUT/apriori_motif_enrichment/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_ANTI -a $SCALE -C 255,0,0 -r 1 -c 2 -h $HEATROW -w $HEATCOL
        java -jar $HEATMAPMERGE -s $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SORT_SENSE_treeview.png -a $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SORT_ANTI_treeview.png -o $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_MERGE.png
        read peaks filename <<< $(wc -l "$file")
        python $HEATMAPLABEL -i $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_MERGE.png -o $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SAMPLE.png -b true -v $HEATXAXIS -x "Distance from peak midpoint (bp)" -y "N=$peaks"
        # Generate control heatmap
        java -jar $HEATMAP -m $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_CONTROL_SORT_sense.tabular -o $INPUT/apriori_motif_enrichment/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_SENSE -a $SCALE -C 0,0,255 -r 1 -c 2 -h $HEATROW -w $HEATCOL
        java -jar $HEATMAP -m $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_CONTROL_SORT_anti.tabular -o $INPUT/apriori_motif_enrichment/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_ANTI -a $SCALE -C 255,0,0 -r 1 -c 2 -h $HEATROW -w $HEATCOL
        java -jar $HEATMAPMERGE -s $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SORT_SENSE_treeview.png -a $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_SORT_ANTI_treeview.png -o $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_MERGE.png
        read peaks filename <<< $(wc -l "$file")
        python $HEATMAPLABEL -i $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_MERGE.png -o $INPUT/apriori_motif_enrichment/tagpileup/$1\_$PEXPANSION\bp_CONTROL.png -b true -v $HEATXAXIS -x "Distance from peak midpoint (bp)" -y "N=$peaks"
        #Clean up temp files
        rm $INPUT/apriori_motif_enrichment/tagpileup/*.tabular $INPUT/apriori_motif_enrichment/tagpileup/*treeview.png $INPUT/apriori_motif_enrichment/tagpileup/*MERGE.png $INPUT/apriori_motif_enrichment/tagpileup/*contrast.out
done

# Make 4-color plots
echo "Generating 4colour plots"
mkdir -p $INPUT/apriori_motif_enrichment/fourcolour
cd $INPUT/apriori_motif_enrichment
for file in *.bed
do
        var=$(echo $file | awk -F"." '{print $1}')
        set -- $var
        # Make input for 4color plot FASTA
        perl $BEDEXPAND $file $FOURSIZE $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\bp.bed
        # Get FASTA sequence for 4 color plot
        bedtools getfasta -s -fi $GENOME -bed $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\bp.bed -fo $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\bp.fa
        # Make plot
        java -jar $FOURCOLOUR -f $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\bp.fa -o $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\.png -A 208,0,0 -T 0,208,0 -G 255,180,0 -C 0,0,208
        python $RESIZEPNG -i $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\.png -o $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\_resize.png -r $COLORROW -c $COLORCOL
        read bound filename <<< $(wc -l "$file")
        python $HEATMAPLABEL -i $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\_resize.png -o $INPUT/apriori_motif_enrichment/fourcolour/$1\_FourColor.png -b true -v $FOURXAXIS -x "Distance from peak midpoint (bp)" -y "N=$bound"
        rm  $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\.png $INPUT/apriori_motif_enrichment/fourcolour/$1\_$FOURSIZE\_resize.png
done
#Remove peakfiles
rm $INPUT/apriori_motif_enrichment/fourcolour/*_$FOURSIZE\bp.bed

# Get weblogos and motif IDs of enriched motifs
echo "Compiling motif information"
mkdir -p $INPUT/apriori_motif_enrichment/logo
cd $INPUT/apriori_motif_enrichment/enrichedmotifs
for file in  *.gff; do
	MOTIFNAME=$(echo $file | awk -F"." '{print $1}' | awk -F"_" '{print $NF}' )
	cp $MOTIFLOGO/JASPAR_cluster_$MOTIFNAME\.png $INPUT/apriori_motif_enrichment/logo/
	perl $MATCHMOTIF $MOTIFID cluster_$MOTIFNAME $INPUT/apriori_motif_enrichment/logo/JASPAR_cluster_$MOTIFNAME\.out
done
 
# Output Report
echo "Outputing final motif enrichment report"
MOTIF=0
cd $INPUT/apriori_motif_enrichment
for file in *.bed; do
	MOTIF="$(($MOTIF+1))"
	var=$(echo $file | awk -F"." '{print $1}')
	set -- $var
	CLUSTERID=$(echo $file | awk -F"." '{print $1}' | awk -F"_" '{print $NF}')

	ls $INPUT/apriori_motif_enrichment/logo/JASPAR_cluster_$CLUSTERID\.png > $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
        # Output 4color plot
        ls $INPUT/apriori_motif_enrichment/fourcolour/*_$CLUSTERID\_FourColor.png  >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
        # Output sample heatmap
        ls $INPUT/apriori_motif_enrichment/tagpileup/*_$CLUSTERID\_*SAMPLE.png >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
        # Output control heatmap
        ls $INPUT/apriori_motif_enrichment/tagpileup/*_$CLUSTERID\_*CONTROL.png >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
        # Output sample and control composite plot
        cat $INPUT/apriori_motif_enrichment/tagpileup/*_$CLUSTERID\_*composite.out >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt

        # Output peak statistics
	read peaks filename <<< $(wc -l "$INPUT/apriori_motif_enrichment/enrichedmotifs/motif_cluster_$CLUSTERID.gff")
	echo -e "Peaks:\t$peaks" >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
	perl $ENRICHMENTSCORE $INPUT/apriori_motif_enrichment/enriched_motifs.out cluster_$CLUSTERID >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
	perl $PARSECLUSTER $INPUT/apriori_motif_enrichment/logo/JASPAR_cluster_$CLUSTERID\.out >> $INPUT/apriori_motif_enrichment/apriori_motif$MOTIF\-info.txt
 
done
