#!/bin/bash

#run script as sudo
#input= reference website (in quotation marks!), sra website (in quotation marks!), name of species
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

#Example Indri: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/004/363/605/GCA_004363605.1_IndInd_v1_BIUU/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-21/SRR11430608/SRR11430608.1" IndriIndri 
#Vulpes: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/018/345/385/GCF_018345385.1_ASM1834538v1/GCF_018345385.1_ASM1834538v1_genomic.fna.gz" "https://sra-download.ncbi.nlm.nih.gov/traces/era23/ERR/ERR5417/ERR5417979" VulpesLagupos

trimmomatic_exe='/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir='/vol/storage/'


#make new folder for species
mkdir $working_dir$3
#download reference
sudo wget  -O $working_dir$3/reference.fna.gz "$1" 
#download sra
#prefetch is recommended
#prefetch -O $working_dir$3 SRA_id
sudo wget  -O $working_dir$3/$3.sra "$2"
#convert to fastq
#--split-files  :for paired end data. Dump each read into separate file. Files will receive suffix corresponding to read number 
#parallel-fastq-dump O $working_dir$3 --threads 18  --split-files --gzip $working_dir$3/$3.sra
sudo fastq-dump -O $working_dir$3 --gzip --split-files $working_dir$3/$3.sra
#quality contol
#-a creates file of adapters
#TODO how to get adapters
fastqc -t 18 -o $working_dir$3  -f fastq $working_dir$3/$3_1.fastq.gz $working_dir$3/$3_2.fastq.gz
#read trimming, remove adapter sequences
#for paired end reads
java -jar $trimmomatic_exe PE  $working_dir$3/$3_1.fastq.gz $working_dir$3/$3_2.fastq.gz $working_dir$3/1trim.fastq.gz $working_dir$3/1untrim.fastq.gz $working_dir$3/2trim.fastq.gz $working_dir$3/2untrim.fastq.gz SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:/vol/storage/Trimmomatic-0.36/adapters/TruSeq3-PE.fa:2:30:10:2:keepBothReads
fastqc -t 18 -o $working_dir$3  -f fastq $working_dir$3/1trim.fastq.gz $working_dir$3/2trim.fastq.gz
#map reads onto reference
sudo bwa index -p $working_dir/$3/index $working_dir$3/reference.fna.gz
#samtools sort -m when a lot of memory available -> needs to specify
#conversion to bam file
bwa mem -t 18 $working_dir/$3/index $working_dir$3/1trim.fastq.gz $working_dir$3/2trim.fastq.gz  | samtools sort -@ 18 -o $working_dir$3/bwa.sorted.bam
samtools index $working_dir$3/bwa.sorted.bam
#unzip reference for samtools
sudo gunzip $working_dir$3/reference.fna.gz
#index reference
sudo samtools faidx $working_dir$3/reference.fna
#SNP calling
#mpileup: check each position of the reference if it contains a potential variant
#-f reference fasta
#TODO saple file for ploidy
bcftools mpileup -Ou -f $working_dir$3/reference.fna $working_dir$3/bwa.sorted.bam | bcftools call -mv -Ob -o $working_dir$3/output.bcf
#convert to vcf
bcftools view $working_dir$3/output.bcf > $working_dir$3/output.vcf
sudo samtools faidx reference.fna
