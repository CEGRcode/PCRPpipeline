# PCRPpipeline
Bioinformatic pipeline used to process PCRP datasets

## Pipeline requirements
* python 2.7.14
* python - matplotlib
* Java 8 or later
* perl v5.10.1 or later
* bedtools v2.27.1 or later
* samtools 1.7
* MEME v5+
* ChExMix v0.45 available here: https://github.com/seqcode/chexmix
* * Compiled JAR should be moved here: /QC-pipeline/external_app/

## Command to run pipeline:
`sh 11_RUN_MEP_QC_XO.sh -s sampleID.txt -a /path/to/QC-pipeline`

## Sample ID file format
4-column tab-delimited file containing the information required to run the pipeline for each sample
SampleID        Full path to SAMPLE.bam      Full path to CONTROL.bam     Full path ro relevant Reference features

