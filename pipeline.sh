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

: '
#OLD
#SNP calling
#mpileup: check each position of the reference if it contains a potential variant
#-f reference fasta
#TODO sample file for ploidy
#-Ou = output uncompressed bcf
#-f = faidx indexed fasta file available
#-Ov = output is unzipped vcf
#-o= outputfile
#-m = alternative model for multiallelic and rare-variant calling (conflicts with -c) -> PROBLEM
#-v =  output variant sites only
bcftools mpileup -Ou -f $working_dir$3/reference.fna $working_dir$3/bwa.sorted.bam | bcftools call -mv -Ov -o $working_dir$3/output.vcf
'

#OR THIS
#CONSENSUS VCFUTILS
#call -c for consensus; conflicts with -m
#The "-c" option does give ploidy status by using IUPAC codes. Look for "K" or "R" characters (etc.) in your consensus calls.
#vcfutils.pl vcf2fq does not work if -mv is used for bcfcall
mkdir $working_dir$3/consensus
samtools mpileup -C50 -uf $working_dir$3/reference.fna  $working_dir$3/bwa.sorted.bam | bcftools call -c $working_dir$3/output.vcf
: '
Explain VCF
DP= combined Depth
MQSB=rms mapping quality
MQ0F=how often mapping quality is zero
AF1=allele frequency
AC1=allele count
DP4=read depth
MQ=rms mapping quality
FQ=-281.989
GT: Genotype (ref=0, alt1=1, alt2=2 etc) 0/0 hemozygot, 0/1 heterozygot
PL Genotype likelihood
'
#-d min coverage, -D max coverage
vcfutils.pl vcf2fq -d 10 -D 100 $working_dir$3/output.vcf > $working_dir$3/consensus/diploid_consensus.fq

: '
#NOT NEEDED
#count total variants
wc -l $working_dir$3/output.vcf
#7.839.513 variants

#sort reference into chromosomes
mkdir $working_dir$3chromosomes
cd $working_dir$3chromosomes
#25 because of 25 chromosomes
head -25 ../reference.fna.fai | sudo faidx -x ../reference.fna
#get chromosomes bigger than 1MB
sudo mkdir $working_dir$3chromosomes/big
for file in *
do
words=`wc -w $file | awk '{print $1}'`
echo $words
if [ $words -gt 1000000 ]
then	
	mv $file $working_dir$3chromosomes/big/$file
fi
done
'

#split consensus files into chromosomes
#Name starts with NC_05..
#contics  start with NW...
csplit $working_dir$3/consensus/diploid_consensus.fq /\@NC\_05_*/ {*}

#PSMC
# infers the history of population sizes
psmc_dir='/vol/storage/psmc-master'
cd $working_dir$3/consensus
#for every fq consensus-file 
for chromosome in *
do
$psmc_dir/utils/fq2psmcfa -q20 $chromosome > $chromosome.psmcfa
$psmc_dir/psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o $chromosome.psmc $chromosome.psmcfa
$psmc_dir/utils/psmc2history.pl $chromosome.psmc | $psmc_dir/utils/history2ms.pl > ms-cmd.sh
#per-generation mutation rate -u and the generation time in years -g
#example -u 3.83e-08 -g 31
$psmc_dir/utils/psmc_plot.pl $chromosome $chromosome.psmc
#open image
#gv $chromosome.eps
done


#ROH
#gzip vcf
bcftools view $working_dir$3/output.vcf -Oz -o $working_dir$3/output.vcf.gz
#split vcf into chromosomes
mkdir $working_dir$3vcf
#index vcf file (output.vcf.gz.tbi)
tabix -p vcf output.vcf.gz
cd $working_dir$3vcf
names=`head -25 ../reference.fna.fai | awk '{print $1}'`
for file in $names
do
tabix ../output.vcf.gz $file > $file.vcf
bcftools roh -G30 --AF-dflt 0.4 $file.vcf > $file_roh.txt
done


