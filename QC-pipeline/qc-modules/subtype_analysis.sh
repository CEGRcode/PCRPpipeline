#!/bin/sh

# Required software for this module:
# python 2.7.14
# python - matplotlib
# Java 8 or later
# perl

# MEME v5+
# RepeatMasker
# bedtools

usage()
{
    echo 'subtype_analysis.sh -i <INPUT PATH> -s <SampleID> -c <ControlID> -a <Path to scripts> -r <Path to references>'
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

# Genome
GENOME=$REF/Genome/hg19.fa
# JASPAR Database
JASPARMEME=$REF/Motif_Coord/JASPAR2020_CORE_vertebrates_non-redundant_pfms_meme.txt

# Scripts for prepping ChExMix peaks
SPLIT=$SCRIPT/format-convert/coordinate-file/split_ChExMix_subtype_BED.pl
EXPAND=$SCRIPT/format-convert/coordinate-file/expand_BED.pl

# TOMTOM scripts
CONVERTTRANSFAC=$SCRIPT/format-convert/motif-file/convert_transfac_to_MEME-ChExMix.pl
MOVEMOTIF=$SCRIPT/motif-enrichment/motif-filter/copy_TOMTOM_to_folder.pl
 
# Pileup
TAGPILEUP=$SCRIPT/tag-pileup/pileup-scripts/TagPileup.jar
SORTCDT=$SCRIPT/tag-pileup/pileup-scripts/sort_strand_seperate_Sample-Control_CDT.pl 
PARSECOMPOSITE=$SCRIPT/tag-pileup/pileup-scripts/combine_StrandSep_Sample-Control_Composite.pl
# Heatmap
CONTRAST=$SCRIPT/tag-pileup/heatmap-scripts/calculate_Contrast_Threshold.py
PARSE=$SCRIPT/tag-pileup/heatmap-scripts/parse_Strand-Seperate_Contrast.pl 
HEATMAP=$SCRIPT/tag-pileup/heatmap-scripts/jHeatmap.jar
HEATMAPMERGE=$SCRIPT/tag-pileup/heatmap-scripts/jMergeHeatmap.jar
HEATMAPLABEL=$SCRIPT/tag-pileup/heatmap-scripts/label_Heatmap.py
HEATTHRESH=90
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
 
# FRIP scripts
CALCULATE=$SCRIPT/FRIP-scripts/calculate_FRIP_Score.pl
FRIPSIZE=100
 
# Peak report script
REPORT=$SCRIPT/report/generate_peak-info.pl

mkdir -p $INPUT/subtype_analysis
cd $INPUT/subtype_analysis
# Check that peak-calling occured
if [ ! -f "$SPEAK" ]; then
	echo "$SPEAK does not exist"
	exit 0
fi

# Not enough peaks for subtype enrichment, ending this pipeline module
if [ 1 -gt $(wc -l < $SPEAK) ]; then
        echo "Insufficient starting peaks for subtype enrichment"
        exit 0
fi

# Split ChExMix peak file into subtype peak files
echo "Splitting subtypes"
perl $SPLIT $SPEAK $SAMPLEID

# Make tag pileup
mkdir -p $INPUT/subtype_analysis/tagpileup
cd $INPUT/subtype_analysis
for file in *.bed
do
        var=$(echo $file | awk -F"." '{print $1}')
        set -- $var
        # Make input for tag pileup
        perl $EXPAND $file $PEXPANSION $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp.bed
	# Tag pileup at subtype midpoints
	java -jar $TAGPILEUP -b $SBAM -i $SBAM\.bai -c $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp.bed -t $CPU -w 5 -e true -x $INPUT/subtype_analysis/tagpileup/$1\_SAMPLE-C.out -o $INPUT/subtype_analysis/tagpileup
	java -jar $TAGPILEUP -b $CBAM -i $CBAM\.bai -c $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp.bed -t $CPU -w 5 -e true -x $INPUT/subtype_analysis/tagpileup/$1\_CONTROL-C.out -o $INPUT/subtype_analysis/tagpileup
	perl $PARSECOMPOSITE $INPUT/subtype_analysis/tagpileup/$1\_SAMPLE-C.out $INPUT/subtype_analysis/tagpileup/$1\_CONTROL-C.out $INPUT/subtype_analysis/tagpileup/$1\_composite.out
	# Make pileup heatmaps
	perl $SORTCDT $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_$SAMPLEID\_read1_sense.tabular $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_$SAMPLEID\_read1_anti.tabular $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_CONTROL_read1_sense.tabular $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_CONTROL_read1_anti.tabular $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_CONTROL_SORT
	#Calculate contrast ratio based on sample
	python $CONTRAST -i $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_sense.tabular -o $INPUT/subtype_analysis/tagpileup/sense_heatmap_contrast.out -q $HEATTHRESH -d T -s 2 -r $HEATROW -l $HEATCOL
        python $CONTRAST -i $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_anti.tabular -o $INPUT/subtype_analysis/tagpileup/anti_heatmap_contrast.out -q $HEATTHRESH -d T -s 2 -r $HEATROW -l $HEATCOL
	SCALE="$(perl $PARSE $INPUT/subtype_analysis/tagpileup/sense_heatmap_contrast.out $INPUT/subtype_analysis/tagpileup/anti_heatmap_contrast.out)"
	# Generate sample heatmap
	java -jar $HEATMAP -m $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_sense.tabular -o $INPUT/subtype_analysis/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_SENSE -a $SCALE -C 0,0,255 -r 1 -c 2 -h $HEATROW -w $HEATCOL
	java -jar $HEATMAP -m $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SAMPLE_SORT_anti.tabular -o $INPUT/subtype_analysis/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_ANTI -a $SCALE -C 255,0,0 -r 1 -c 2 -h $HEATROW -w $HEATCOL
	java -jar $HEATMAPMERGE -s $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SORT_SENSE_treeview.png -a $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SORT_ANTI_treeview.png -o $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_MERGE.png
	read peaks filename <<< $(wc -l "$file")
	python $HEATMAPLABEL -i $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_MERGE.png -o $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SAMPLE.png -b true -v $HEATXAXIS -x "Distance from peak midpoint (bp)" -y "N=$peaks"
	# Generate control heatmap
	java -jar $HEATMAP -m $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_CONTROL_SORT_sense.tabular -o $INPUT/subtype_analysis/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_SENSE -a $SCALE -C 0,0,255 -r 1 -c 2 -h $HEATROW -w $HEATCOL
	java -jar $HEATMAP -m $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_CONTROL_SORT_anti.tabular -o $INPUT/subtype_analysis/tagpileup/ -f $1\_$PEXPANSION\bp_SORT_ANTI -a $SCALE -C 255,0,0 -r 1 -c 2 -h $HEATROW -w $HEATCOL
	java -jar $HEATMAPMERGE -s $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SORT_SENSE_treeview.png -a $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_SORT_ANTI_treeview.png -o $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_MERGE.png
	read peaks filename <<< $(wc -l "$file")
	python $HEATMAPLABEL -i $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_MERGE.png -o $INPUT/subtype_analysis/tagpileup/$1\_$PEXPANSION\bp_CONTROL.png -b true -v $HEATXAXIS -x "Distance from peak midpoint (bp)" -y "N=$peaks"
	# Clean up temp files
	rm $INPUT/subtype_analysis/tagpileup/*.tabular $INPUT/subtype_analysis/tagpileup/*treeview.png $INPUT/subtype_analysis/tagpileup/*MERGE.png $INPUT/subtype_analysis/tagpileup/*contrast.out
done

echo "Calculating FRIP..."
mkdir -p $INPUT/subtype_analysis/frip
cd $INPUT/subtype_analysis
for file in *.bed
do
	var=$(echo $file | awk -F"." '{print $1}')
	set -- $var
	perl $EXPAND $file $FRIPSIZE $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp.bed
	bedtools intersect -a $SBAM -b $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp.bed | samtools view - -f 0x40 > $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp_SAMPLE_FRIP_Peak_Overlap.sam
	bedtools intersect -a $CBAM -b $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp.bed | samtools view - -f 0x40 > $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp_CONTROL_FRIP_Peak_Overlap.sam

	perl $CALCULATE $INPUT/sample_bam_stats.out $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp_SAMPLE_FRIP_Peak_Overlap.sam $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp_SAMPLE_FRIP.out
	perl $CALCULATE $INPUT/control_bam_stats.out $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp_CONTROL_FRIP_Peak_Overlap.sam $INPUT/subtype_analysis/frip/$1\_$FRIPSIZE\bp_CONTROL_FRIP.out
	rm -f $INPUT/subtype_analysis/frip/*sam $INPUT/subtype_analysis/frip/*.bed
done

# Make 4-color plots
echo "Generating 4colour plots"
mkdir -p $INPUT/subtype_analysis/fourcolour
cd $INPUT/subtype_analysis
for file in *.bed
do
	var=$(echo $file | awk -F"." '{print $1}')
	set -- $var
	# Make input for 4color plot FASTA
	perl $EXPAND $file $FOURSIZE $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\bp.bed
	# Get FASTA sequence for 4 color plot
	bedtools getfasta -s -fi $GENOME -bed $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\bp.bed -fo $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\bp.fa
	# Make plot
	java -jar $FOURCOLOUR -f $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\bp.fa -o $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\.png -A 208,0,0 -T 0,208,0 -G 255,180,0 -C 0,0,208
	python $RESIZEPNG -i $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\.png -o $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\_resize.png -r $COLORROW -c $COLORCOL
	read bound filename <<< $(wc -l "$file")
	python $HEATMAPLABEL -i $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\_resize.png -o $INPUT/subtype_analysis/fourcolour/$1\_FourColor.png -b true -v $FOURXAXIS -x "Distance from peak midpoint (bp)" -y "N=$bound"
	rm  $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\.png $INPUT/subtype_analysis/fourcolour/$1\_$FOURSIZE\_resize.png
done
#Remove peakfiles
rm $INPUT/subtype_analysis/fourcolour/*_$FOURSIZE\bp.bed

# Motif analysis using TOMTOM against JASPAR database
echo "Matching enriched motifs against JASPAR motifs"
mkdir -p $INPUT/subtype_analysis/logo
cd $INPUT/subtype_analysis
if [ -s $INPUT/peak_calling/chexmix/intermediate-results/chexmix.experiment.transfac ]; then
        perl $CONVERTTRANSFAC $INPUT/peak_calling/chexmix/intermediate-results/chexmix.experiment.transfac $INPUT/subtype_analysis/meme.txt
        tomtom -no-ssc -min-overlap 5 -dist pearson -evalue -thresh 10.0 -incomplete-scores $INPUT/subtype_analysis/meme.txt $JASPARMEME -png -oc $INPUT/subtype_analysis/TOMTOM
        perl $MOVEMOTIF $INPUT/subtype_analysis/TOMTOM/tomtom.tsv $INPUT/subtype_analysis/TOMTOM $SAMPLEID $INPUT/subtype_analysis/logo
fi

#Make weblogos of PWM
echo "Generating weblogos"
cd $INPUT/subtype_analysis/
for file in  *.bed; do
	var=$(echo $file | awk -F"." '{print $1}' | awk -F"_" '{print $NF}')
	set -- $var
	if grep -q $1 $INPUT/subtype_analysis/meme.txt; then
                ceqlogo -i $INPUT/subtype_analysis/meme.txt -m $1 -d "" -f PNG -o $INPUT/subtype_analysis/logo/$SAMPLEID\_$1\.png
                ceqlogo -i $INPUT/subtype_analysis/meme.txt -m $1 -r -d "" -f PNG -o $INPUT/subtype_analysis/logo/RC_$SAMPLEID\_$1\.png
	fi
done

#Output info.txt files for each subtype
echo "Outputing final subtype enrichment report"
cd $INPUT/subtype_analysis
for file in *.bed
do
	NAME=$(echo $file | awk -F"." '{print $1}')
	SUBTYPEID=$(echo $file | awk -F"." '{print $1}' | awk -F"_" '{print $NF}')
	#Output enriched motif if exists
	if [ -f $INPUT/subtype_analysis/logo/$NAME\.png ]; then
		ls $INPUT/subtype_analysis/logo/$NAME\.png > $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
		ls $INPUT/subtype_analysis/logo/RC_$NAME\.png >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	else
		ls $REF/Motif_Coord/NoMotifDetected.png > $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
		ls $REF/Motif_Coord/NoMotifDetected.png >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	fi
	# Output TOMTOM match if present or report failed TOMTOM comparison
	if [ -f $INPUT/subtype_analysis/logo/$SAMPLEID*_$SUBTYPEID*TOMTOM.png ]; then
        	ls $INPUT/subtype_analysis/logo/$SAMPLEID*_$SUBTYPEID*TOMTOM.png >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	else
        	ls $REF/Motif_Coord/TOMTOM_Fail.png >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	fi
	# Output 4color plot
        ls $INPUT/subtype_analysis/fourcolour/*_$SUBTYPEID\_FourColor.png  >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	# Output sample heatmap
        ls $INPUT/subtype_analysis/tagpileup/*_$SUBTYPEID\_*SAMPLE.png >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	# Output control heatmap
        ls $INPUT/subtype_analysis/tagpileup/*_$SUBTYPEID\_*CONTROL.png >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	# Output sample and control composite plot
	cat $INPUT/subtype_analysis/tagpileup/*_$SUBTYPEID\_*composite.out >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt

	# Output peak statistics
	read peaks filename <<< $(wc -l $file)
	perl $REPORT $peaks $INPUT/subtype_analysis/frip/*_$SUBTYPEID\_*_SAMPLE_FRIP.out $INPUT/subtype_analysis/frip/*_$SUBTYPEID\_*_CONTROL_FRIP.out $INPUT/subtype_analysis/$SUBTYPEID\_peakData.txt
	cat $INPUT/subtype_analysis/$SUBTYPEID\_peakData.txt >> $INPUT/subtype_analysis/$SUBTYPEID\-info.txt
	rm $INPUT/subtype_analysis/$SUBTYPEID\_peakData.txt
done
