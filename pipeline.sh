#!/bin/bash

#run script as sudo
#input= reference website (in quotation marks!), sra website (in quotation marks!), name of species
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

#Example Indri: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/004/363/605/GCA_004363605.1_IndInd_v1_BIUU/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-21/SRR11430608/SRR11430608.1" IndriIndri 
#Vulpes: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/018/345/385/GCF_018345385.1_ASM1834538v1/GCF_018345385.1_ASM1834538v1_genomic.fna.gz" "https://sra-download.ncbi.nlm.nih.gov/traces/era23/ERR/ERR5417/ERR5417979" VulpesLagupos

: '
Installations:
fastq-dump
fastqc
trimmomatic
bwa
samtools
bcftools
vcfutils
vcftools
csplit
psmc
bedtools
tabix
'

#directories
trimmomatic_exe='/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir='/vol/storage/'
psmc_dir='/vol/storage/psmc-master'
psmc_plot_dir='/home/ubuntu/Ina/SwarmGenomics'
roh_plot_dir='/home/ubuntu/Ina/SwarmGenomics'

: '
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
sudo rm *.sra
#quality contol
#-a creates file of adapters
#TODO how to get adapters
fastqc -t 18 -o $working_dir$3  -f fastq $working_dir$3/$3_1.fastq.gz $working_dir$3/$3_2.fastq.gz
#read trimming, remove adapter sequences
#for paired end reads
java -jar $trimmomatic_exe PE  $working_dir$3/$3_1.fastq.gz $working_dir$3/$3_2.fastq.gz $working_dir$3/1trim.fastq.gz $working_dir$3/1untrim.fastq.gz $working_dir$3/2trim.fastq.gz $working_dir$3/2untrim.fastq.gz SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:/vol/storage/Trimmomatic-0.36/adapters/TruSeq3-PE.fa:2:30:10:2:keepBothReads
fastqc -t 18 -o $working_dir$3  -f fastq $working_dir$3/1trim.fastq.gz $working_dir$3/2trim.fastq.gz
mkdir fast_qc
mv *fastqc* fast_qc/
#map reads onto reference
sudo bwa index -p $working_dir/$3/index $working_dir$3/reference.fna.gz
#samtools sort -m when a lot of memory available -> needs to specify
#conversion to bam file
bwa mem -t 18 $working_dir/$3/index $working_dir$3/1trim.fastq.gz $working_dir$3/2trim.fastq.gz  | samtools sort -@ 18 -o $working_dir$3/bwa.sorted.bam
sudo rm *fastq.*
samtools index $working_dir$3/bwa.sorted.bam
#unzip reference for samtools
sudo gunzip $working_dir$3/reference.fna.gz
#index reference
sudo samtools faidx $working_dir$3/reference.fna

#CONSENSUS VCFUTILS
#call -c for consensus; conflicts with -m
#The "-c" option does give ploidy status by using IUPAC codes. Look for "K" or "R" characters (etc.) in your consensus calls.
#vcfutils.pl vcf2fq does not work if -mv is used for bcfcall
mkdir $working_dir$3/consensus
samtools mpileup -C50 -uf $working_dir$3/reference.fna  $working_dir$3/bwa.sorted.bam | bcftools call -c $working_dir$3/output.vcf
#remove not needed files
sudo rm *bam*
sudo rm index*

#make bed file with repeats
perl -lne 'if(/^(>.*)/){ $head=$1 } else { $fa{$head} .= $_ } END{ foreach $s (sort(keys(%fa))){ print "$s\n$fa{$s}\n" }}'  $working_dir$3/reference.fna | perl -lne 'if(/^>(\S+)/){ $n=$1} else { while(/([a-z]+)/g){ printf("%s\t%d\t%d\n",$n,pos($_)-length($1),pos($_)) } }'  > $working_dir$3/repeats.bed
#remve repeats from vcf
bedtools subtract -header -a $working_dir$3/output.vcf -b $working_dir$3/repeats.bed > $working_dir$3/output_no_repeats.vcf
#make vcf without repeats standard vcf file
sudo rm $working_dir$3/output.vcf
mv $working_dir$3/output_no_repeats.vcf $working_dir$3/output.vcf
'

#make consensus file
#-d min coverage, -D max coverage
vcfutils.pl vcf2fq -d 10 -D 100 $working_dir$3/output.vcf > $working_dir$3/consensus/diploid_consensus.fq

#get chromosomes/contigs and size
cat $working_dir$3/reference.fna | awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($0,2) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' > $working_dir$3/chromosomes_length.txt
#get name of bigger chromosomes >1MB
big=`cat $working_dir$3/chromosomes_length.txt | awk '$(NF) >= 1000000  {print $1}'`
echo $big
cd
#split consensus files into chromosomes
for chromosome in $big
do
csplit $working_dir$3/consensus/diploid_consensus.fq /\@$chromosome/ {*} 
done

#PSMC
# infers the history of population sizes
cd $working_dir$3/consensus
#for every fq consensus-file 
for chromosome in *
do
#-q20
$psmc_dir/utils/fq2psmcfa -q20 $chromosome > $chromosome.psmcfa
$psmc_dir/psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o $chromosome.psmc $chromosome.psmcfa
$psmc_dir/utils/psmc2history.pl $chromosome.psmc | $psmc_dir/utils/history2ms.pl > ms-cmd.sh
#per-generation mutation rate -u and the generation time in years -g
#example -u 3.83e-08 -g 31
$psmc_dir/utils/psmc_plot.pl $chromosome $chromosome.psmc
python $psmc_plot_dir/psmc_plot.py $chromosome.png $chromosome.psmc
#open image
#gv $chromosome.eps
done
python $psmc_plot_dir/psmc_plot.py all.png *.psmc


#ROH
#for RoH on all vcf files (all big chromosomes)
#gzip vcf (needed to index file)
bcftools view $working_dir$3/output.vcf -Oz -o $working_dir$3/output.vcf.gz
#index vcf file (output.vcf.gz.tbi)
tabix -p vcf output.vcf.gz
mkdir $working_dir$3vcf
cd $working_dir$3vcf
for file in $big
do
#generate vcf file of chromosome
tabix -h ../output.vcf.gz $file > $file.vcf
#-G genotypes (instead of genotype likelihoods)
bcftools roh -G30 --AF-dflt 0.4 $file.vcf > $file_roh.txt
python $roh_plot_dir/roh_plot.py $file_roh.txt $file $file.png
done

#get allele frequency
#https://vcftools.github.io/documentation.html
vcftools --vcf $working_dir$3/output.vcf --freq --out outputfreq
bcftools roh --AF-tag outputfreq.frq $working_dir$3/output.vcf > roh_freq_tab.txt
#roh for whole genome
#--GTs-only ignoring genotype likelihoods (FORMAT/PL)
bcftools roh -G30 --AF-dflt 0.4 $working_dir$3/output.vcf > roh.txt
#AF 0.5
bcftools roh --AF-dflt 0.5 $working_dir$3/output.vcf > roh_AF05.txt
#without specification
bcftools roh $working_dir$3/output.vcf > roh_no_params.txt
#-e estimate AC and AF on the fly
bcftools roh -e $working_dir$3/output.vcf > roh_estimate.txt
#no indels
bcftools roh -e -i $working_dir$3/output.vcf > roh_estimate_no_indels.txt

#output: chromosome - position - state (1:Autozygous/0:HardyWeinberg) - quality
#ST = state, RG= region (when input is multiple vcf files)
#how often Hardy Weinberg:
awk '{print $5}' roh.txt | grep "0" | wc -l
#for roh_call_mv: 6.411.728 
#for new_roh.txt: 6.525.129
#how often autozygote (homozygote):
awk '{print $5}' roh.txt | grep "1" | wc -l
#for roh_call_mv: 1.383.983 
#for new_roh.txt: 1.230.577

#9665 times RG
#7783890 times ST

#number of heterozygose sites 
for file in $working_dir$3vcf/*
do
wc -l $file 
done
> size.txt

