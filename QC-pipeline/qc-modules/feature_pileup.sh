#!/bin/sh

# Required software for this module:
# python 2.7.14
# python - matplotlib
# Java 8 or later
# perl

# bedtools

#Ends script if any of the shell commands fail
set -e

usage()
{
    echo 'feature_pileup.sh -i <INPUT PATH> -s <SampleID> -c <ControlID> -a <Path to scripts> -r <Path to references>'
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

SBAM=$INPUT/$SAMPLEID\.bam
CBAM=$INPUT/$CONTROLID\.bam

#Pileup script
TAGPILEUP=$SCRIPT/tag-pileup/pileup-scripts/TagPileup.jar
#Pileup param
CPU=4
#Enrichment calculator
ENRICH=$SCRIPT/tag-pileup/pileup-scripts/calculate_log2_enrichment.pl
ENRICHWIN=1000
#Composite plot
AVGCDT=$SCRIPT/tag-pileup/pileup-scripts/avg_TopLines_from_Sample-Control_CDT.pl 
TOPSITES=1000
SMOOTH=11
#Heatmap parameters
HEATMAP=$SCRIPT/tag-pileup/heatmap-scripts/jHeatmap.jar
HEATMAPLABEL=$SCRIPT/tag-pileup/heatmap-scripts/label_Heatmap.py
CONTRAST=$SCRIPT/tag-pileup/heatmap-scripts/calculate_Contrast_Threshold.py
PARSE=$SCRIPT/tag-pileup/heatmap-scripts/parse_Contrast.pl
HEATROW=600
HEATCOL=200

#Features of interest
TSS=$REF/TSS/hg19_TSS_2000bp.bed
CTCF=$REF/CTCF/hg19_CTCF_2000bp.bed

mkdir -p $INPUT/feature_pileup/tss_pileup
cd $INPUT/feature_pileup/tss_pileup
java -jar $TAGPILEUP -b $SBAM -i $SBAM\.bai -c $TSS -t $CPU -a 1 -e true -m false -o $INPUT/feature_pileup/tss_pileup
java -jar $TAGPILEUP -b $CBAM -i $CBAM\.bai -c $TSS -t $CPU -a 1 -e true -m false -o $INPUT/feature_pileup/tss_pileup

#Calculate contrast ratio based on sample
python $CONTRAST -i *$SAMPLEID*tabular -o heatmap_contrast.out -q 95 -d T -s 2 -r 600 -l 200
SCALE="$(perl $PARSE $INPUT/feature_pileup/tss_pileup/heatmap_contrast.out)"
#Generate heatmaps
java -jar $HEATMAP -m *$SAMPLEID*tabular -f $SAMPLEID\_tss -a $SCALE -C 0,0,255 -r 1 -c 2 -h $HEATROW -w $HEATCOL
java -jar $HEATMAP -m *CONTROL*tabular -f $CONTROLID\_tss -a $SCALE -C 0,0,0 -r 1 -c 2 -h $HEATROW -w $HEATCOL
#Generate average smoothed composite plots
perl $AVGCDT *$SAMPLEID*tabular *CONTROL*tabular $TOPSITES $SMOOTH $SAMPLEID\_composite.out
#Calculate feature enrichment over background
perl $ENRICH $SAMPLEID\_composite.out $ENRICHWIN $SAMPLEID\_enrich.out
#Clean matrix file
rm *tabular
#Label Heatmaps
read tssrows filename <<< $(wc -l "$TSS")
python $HEATMAPLABEL -i $SAMPLEID\_tss_treeview.png -o $SAMPLEID\_TSS_Heatmap.png -b true -v "-1000,0,1000" -x "Distance from TSS (bp)" -y "N=$tssrows"
python $HEATMAPLABEL -i $CONTROLID\_tss_treeview.png -o $CONTROLID\-$SAMPLEID\_TSS_Heatmap.png -b true -v "-1000,0,1000" -x "Distance from TSS (bp)" -y "N=$tssrows"
#Output to *info.txt file
ls $INPUT/feature_pileup/tss_pileup/$SAMPLEID\_TSS_Heatmap.png > $INPUT/feature_pileup/TSS_pileup-info.txt
ls $INPUT/feature_pileup/tss_pileup/$CONTROLID\-$SAMPLEID\_TSS_Heatmap.png >> $INPUT/feature_pileup/TSS_pileup-info.txt
cat $INPUT/feature_pileup/tss_pileup/$SAMPLEID\_enrich.out >> $INPUT/feature_pileup/TSS_pileup-info.txt
cat $INPUT/feature_pileup/tss_pileup/$SAMPLEID\_composite.out >> $INPUT/feature_pileup/TSS_pileup-info.txt

mkdir -p $INPUT/feature_pileup/ctcf_pileup
cd $INPUT/feature_pileup/ctcf_pileup
java -jar $TAGPILEUP -b $SBAM -i $SBAM\.bai -c $CTCF -t $CPU -a 1 -e true -m false -o $INPUT/feature_pileup/ctcf_pileup
java -jar $TAGPILEUP -b $CBAM -i $CBAM\.bai -c $CTCF -t $CPU -a 1 -e true -m false -o $INPUT/feature_pileup/ctcf_pileup

#Calculate contrast ratio based on sample
python $CONTRAST -i *$SAMPLEID*tabular -o heatmap_contrast.out -q 95 -d T -s 2 -r 600 -l 200
SCALE="$(perl $PARSE $INPUT/feature_pileup/ctcf_pileup/heatmap_contrast.out)"
#Generate heatmaps
java -jar $HEATMAP -m *$SAMPLEID*tabular -f $SAMPLEID\_ctcf -a $SCALE -C 0,0,255 -r 1 -c 2 -h $HEATROW -w $HEATCOL
java -jar $HEATMAP -m *CONTROL*tabular -f $CONTROLID\_ctcf -a $SCALE -C 0,0,0 -r 1 -c 2 -h $HEATROW -w $HEATCOL
#Generate average smoothed composite plots
perl $AVGCDT *$SAMPLEID*tabular *CONTROL*tabular $TOPSITES $SMOOTH $SAMPLEID\_composite.out
#Calculate feature enrichment over background
perl $ENRICH $SAMPLEID\_composite.out $ENRICHWIN $SAMPLEID\_enrich.out
#Clean matrix file
rm *tabular
#Label Heatmaps
read tssrows filename <<< $(wc -l "$CTCF")
python $HEATMAPLABEL -i $SAMPLEID\_ctcf_treeview.png -o $SAMPLEID\_CTCF_Heatmap.png -b true -v "-1000,0,1000" -x "Distance from CTCF midpoint (bp)" -y "N=$tssrows"
python $HEATMAPLABEL -i $CONTROLID\_ctcf_treeview.png -o $CONTROLID\-$SAMPLEID\_CTCF_Heatmap.png -b true -v "-1000,0,1000" -x "Distance from CTCF midpoint (bp)" -y "N=$tssrows"
#Output to *info.txt file
ls $INPUT/feature_pileup/ctcf_pileup/$SAMPLEID\_CTCF_Heatmap.png > $INPUT/feature_pileup/CTCF_pileup-info.txt
ls $INPUT/feature_pileup/ctcf_pileup/$CONTROLID\-$SAMPLEID\_CTCF_Heatmap.png >> $INPUT/feature_pileup/CTCF_pileup-info.txt
cat $INPUT/feature_pileup/ctcf_pileup/$SAMPLEID\_enrich.out >> $INPUT/feature_pileup/CTCF_pileup-info.txt
cat $INPUT/feature_pileup/ctcf_pileup/$SAMPLEID\_composite.out >> $INPUT/feature_pileup/CTCF_pileup-info.txt

