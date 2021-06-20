#!/bin/bash

#run script as sudo
#input= reference website (in quotation marks!), sra website (in quotation marks!), name of species, sraID
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

#Example: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/004/363/605/GCA_004363605.1_IndInd_v1_BIUU/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-21/SRR11430608/SRR11430608.1" IndriIndri2 SRR11430608

trimmomatic_exe='/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir='/vol/storage/'

#make new folder for species
mkdir $working_dir$3
#download reference
sudo wget  -O $working_dir$3/reference.fna.gz "$1" 
#download sra
sudo wget  -O $working_dir$3/$4 "$2"
#convert to fastq
#--split-files  :for paired end data. Dump each read into separate file. Files will receive suffix corresponding to read number 
parallel-fastq-dump --sra-id $4 --threads 18  --split-files --gzip > $working_dir$3/1.fastq.gz $working_dir$3/2.fastq.gz
#quality contol
#-a creates file of adapters
#TODO how to get adapters
fastqc -t 18 -o $working_dir$3  -f fastq $working_dir$3/1.fastq.gz $working_dir$3/2.fastq.gz
#read trimming, remove adapter sequences
#for paired end reads
java -jar $trimmomatic_exe PE  $working_dir$3/1.fastq.gz $working_dir$3/2.fastq.gz $working_dir$3/1trim.fastq.gz $working_dir$3/1untrim.fastq.gz $working_dir$3/2trim.fastq.gz $working_dir$3/2untrim.fastq.gz SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:/vol/storage/Trimmomatic-0.36/adapters/TruSeq3-PE.fa:2:30:10:2:keepBothReads
#map reads onto reference
bwa index -p $working_dir/$3/bwa_index/index $working_dir$3/reference.fna.gz
#TODO make bam directly -> see Tonis file
bwa mem -t 18 $working_dir/$3/bwa_index/index $working_dir$3/1trim.fastq.gz SRR11430608.1_2.trim.fastq.gz > $working_dir$3/bwa.sam #2> $working_dir$3/bwa.log
#conversion to bam file
#-m when a lot of memory available -> needs to specify
samtools sort -@ 18  -o $working_dir$3/bwa.sorted.bam $working_dir$3/bwa.sam
samtools index $working_dir$3/bwa.sorted.bam
#unzip reference for samtools
sudo gunzip $working_dir$3/reference.fna.gz
#index reference
sudo samtools faidx $working_dir$3/reference.fna
#SNP calling
#mpileup: check each position of the reference if it contains a potential variant
#-f reference fasta
# --ploidy 1 treats all samples as haploid
bcftools mpileup -Ou -f $working_dir$3/reference.fna $working_dir$3/bwa.sorted.bam | bcftools call --ploidy 1 -mv -Ob -o $working_dir$3/output.bcf
bcftools view $working_dir$3/output.bcf > $working_dir$3/output.vcf


#vcf
#runs of homozygosity:
#use heterozygosity to estimate diversity (hardy weinberg: one genome is enough to estimate diversity)
#PSMC demography (get data from database: size, size when infant leaves parents (correlation: bigger= less diversity))
# -> question: is demography linked with runs of homozygosity?
#ref seq (annotations -> get coding areas -> relation of silent and non_silent mutations

#remove sex chromosomes?
