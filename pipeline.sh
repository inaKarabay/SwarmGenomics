#!/bin/bash

#input= reference website, sra website, name of species
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

trimmomatic_exe = '/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir = '/vol/storage/'

mkdir $3
#download reference
sudo wget  $1  -P working_dir $3 > $3
#download sra
sudo wget  $2 -P working_dir $3
#convert to fastq
#--split-files  :for paired end data. Dump each read into separate file. Files will receive suffix corresponding to read number 
parallel-fastq-dump --sra-id SRR2244401 --threads 18 --outdir out/ --split-files --gzip
#quality contol
fastqc -t 18 -f fastq FASTQ-FILE
#read trimming, remove adapter sequences
#for paired end reads
java -jar trimmomatic_exe PE R11430608.1_1.fastq.gz SRR11430608.1_2.fastq.gz SRR11430608.1_1.trim.fastq.gz SRR11430608.1_1un.trim.fastq.gz SRR11430608.1_2.trim.fastq.gz SRR11430608.1_2un.trim.fastq.gz SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:../Trimmomatic-0.36/adapters/TruSeq3-PE.fa:2:30:10:2:keepBothReads
#map reads onto reference
bwa index -p bwa_index/index ncbi-genomes-2021-05-28/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz
#TODO make bam directly -> see Tonis file
bwa mem -t 18 bwa_index/index SRR11430608.1_1.trim.fastq.gz SRR11430608.1_2.trim.fastq.gz > SRR11430608.1_bwa.sam #2> SRR11430608.1_bwa.log
#conversion to bam file
#-m when a lot of memory available -> needs to specify
samtools sort -@ 18  -o SRR11430608.1_bwa.sorted.bam SRR11430608.1_bwa.sam 
samtools index SRR11430608.1_bwa.sorted.bam 
#unzip reference for samtools
sudo gunzip GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz 
#index reference
sudo samtools faidx GCA_004363605.1_IndInd_v1_BIUU_genomic.fna
#SNP calling
#mpileup: check each position of the reference if it contains a potential variant
#-f referernce fasta
samtools mpileup -f ncbi-genomes-2021-05-28/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna SRR11430608.1_bwa.sorted.bam | bcftools call -mv -o output.vcf
#TODO bcftools call -mv -o output.vcf SRR11430608.1_raw.bcf

#vcf
#runs of homozygosity:
#PSMC demography (get data from database: size, size when infant leaves parents (correlation: bigger= less diversity))
#ref seq (annotations -> get coding areas -> relation of silent and non_silent mutations

#remove sex chromosomes?
