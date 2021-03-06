#!/bin/bash

#run script as sudo
#input= reference website (in quotation marks!), sra website (in quotation marks!), name of species
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

#Example Indri: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/004/363/605/GCA_004363605.1_IndInd_v1_BIUU/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-21/SRR11430608/SRR11430608.1" IndriIndri 
#Vulpes: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/018/345/385/GCF_018345385.1_ASM1834538v1/GCF_018345385.1_ASM1834538v1_genomic.fna.gz" "https://sra-download.ncbi.nlm.nih.gov/traces/era23/ERR/ERR5417/ERR5417979" VulpesLagupos
# PanPaniscus: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/013/052/645/GCA_013052645.3_Mhudiblu_PPA_v2/GCA_013052645.3_Mhudiblu_PPA_v2_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-20/SRR13998205/SRR13998205.1" PanPaniscus
#FelisCatus: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/181/335/GCA_000181335.4_Felis_catus_9.0/GCA_000181335.4_Felis_catus_9.0_genomic.fna.gz" "https://sra-download.ncbi.nlm.nih.gov/traces/sra54/SRR/015148/SRR15512225" FelisCatus
#DryobatesPubescens:  sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/014/839/835/GCA_014839835.1_bDryPub1.pri/GCA_014839835.1_bDryPub1.pri_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos1/sra-pub-run-5/SRR949791/SRR949791.2" DryobatesPubescens
#MeropsNubicus: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/009/819/595/GCA_009819595.1_bMerNub1.pri/GCA_009819595.1_bMerNub1.pri_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos1/sra-pub-run-5/SRR958516/SRR958516.2" MeropsNubicus
<<COMMENT1
Installations required:
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
COMMENT1

#TODO: change name for psmc_plot_dir (directory of psmc_plot.py) and roh_plot_dir (directory of roh_density.py and roh_stats.py)

#directories
trimmomatic_exe='/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir='/vol/storage/'
psmc_dir='/vol/storage/psmc-master'
psmc_plot_dir='/home/ubuntu/SwarmGenomics'
roh_plot_dir='/home/ubuntu/SwarmGenomics'
python_dir='/home/ubuntu/miniconda3/bin/python3.7'


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
mkdir $working_dir$3/fast_qc
mv $working_dir$3/*fastqc* $working_dir$3/fast_qc/
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

#CONSENSUS VCFUTILS
#call -c for consensus; conflicts with -m
#The "-c" option does give ploidy status by using IUPAC codes. Look for "K" or "R" characters (etc.) in your consensus calls.
#vcfutils.pl vcf2fq does not work if -mv is used for bcfcall
samtools mpileup -C50 -uf $working_dir$3/reference.fna  $working_dir$3/bwa.sorted.bam | bcftools call -c -o $working_dir$3/output.vcf
#remove not needed files


#make bed file with repeats
perl -lne 'if(/^(>.*)/){ $head=$1 } else { $fa{$head} .= $_ } END{ foreach $s (sort(keys(%fa))){ print "$s\n$fa{$s}\n" }}'  $working_dir$3/reference.fna | perl -lne 'if(/^>(\S+)/){ $n=$1} else { while(/([a-z]+)/g){ printf("%s\t%d\t%d\n",$n,pos($_)-length($1),pos($_)) } }'  > $working_dir$3/repeats.bed
#remve repeats from vcf
bedtools subtract -header -a $working_dir$3/output.vcf -b $working_dir$3/repeats.bed > $working_dir$3/output_no_repeats.vcf
#make vcf without repeats standard vcf file
mv $working_dir$3/output_no_repeats.vcf $working_dir$3/output.vcf


#get chromosomes/contigs and size
cat $working_dir$3/reference.fna | awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($0,2) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' > $working_dir$3/chromosomes_length.txt
#get name of bigger chromosomes >1MB
big=`cat $working_dir$3/chromosomes_length.txt | awk '$(NF) >= 1000000  {print $1}'`
echo $big

#gzip vcf (needed to index file)
bcftools view $working_dir$3/output.vcf -Oz -o $working_dir$3/output.vcf.gz
#index vcf file (output.vcf.gz.tbi)
tabix -p vcf $working_dir$3/output.vcf.gz
mkdir $working_dir$3/vcf
cd $working_dir$3/vcf
for file in $big
do
#generate vcf file of chromosome
tabix -h $working_dir$3/output.vcf.gz $file > $working_dir$3/vcf/$file.vcf
done

mkdir $working_dir$3/consensus
#make consensus file for chromosomes
for chromosome in *
do
#-d min coverage, -D max coverage
vcfutils.pl vcf2fq -d 10 -D 100 $chromosome > $working_dir$3/consensus/$chromosome.fq
done
cd $working_dir$3/consensus
#make consensus file of whole genome
cat *.fq > $working_dir$3/consensus/genome.fq


#PSMC
# infers the history of population sizes
#for every fq consensus-file 
for chromosome in *.fq
do
#-q20
$psmc_dir/utils/fq2psmcfa -q20 $chromosome > $chromosome.psmcfa
$psmc_dir/psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o $chromosome.psmc $chromosome.psmcfa
$psmc_dir/utils/psmc2history.pl $chromosome.psmc | $psmc_dir/utils/history2ms.pl > ms-cmd.sh
#per-generation mutation rate -u and the generation time in years -g
#example -u 3.83e-08 mutation rate
# -g 31 generation in years
$psmc_dir/utils/psmc_plot.pl $chromosome $chromosome.psmc
$python_dir $psmc_plot_dir/psmc_plot.py $chromosome.png $chromosome.psmc
#open image
#gv $chromosome.eps
#convert eps to png: gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop -r600 -sDEVICE=pngalpha -sOutputFile=IMAGE.png IMAGE.eps
done
$python_dir $psmc_plot_dir/psmc_plot.py all.png *.psmc

#----------------------------
#same with more conservative coverage
mkdir $working_dir$3/consensus_depth20_50
cd $working_dir$3/vcf
#make consensus file for chromosomes
for chromosome in *
do
echo $chromosome
#-d min coverage, -D max coverage
vcfutils.pl vcf2fq -d 20 -D 50 $chromosome > $working_dir$3/consensus_depth20_50/$chromosome.fq
done
sudo chmod 777 $working_dir$3/consensus_depth20_50
cd $working_dir$3/consensus_depth20_50
#make consensus file of whole genome
cat *.fq > $working_dir$3/consensus_depth20_50/genome.fq
#PSMC
# infers the history of population sizes
#for every fq consensus-file 
for chromosome in *.fq
do
#-q20
$psmc_dir/utils/fq2psmcfa -q20 $chromosome > $chromosome.psmcfa
$psmc_dir/psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o $chromosome.psmc $chromosome.psmcfa
$psmc_dir/utils/psmc2history.pl $chromosome.psmc | $psmc_dir/utils/history2ms.pl > ms-cmd.sh
#per-generation mutation rate -u and the generation time in years -g
#example -u 3.83e-08 mutation rate
# -g 31 generation in years
$psmc_dir/utils/psmc_plot.pl $chromosome $chromosome.psmc
$python_dir $psmc_plot_dir/psmc_plot.py $chromosome.png $chromosome.psmc
#open image
#gv $chromosome.eps
done
$python_dir $psmc_plot_dir/psmc_plot.py all.png *.psmc
#----------------------------

#ROH
mkdir $working_dir$3/roh
#for RoH on all vcf files (all big chromosomes)
cd $working_dir$3/vcf
for file in *
do 
echo $file
#-G genotypes (instead of genotype likelihoods)
bcftools roh -G30 --AF-dflt 0.4 $file > $working_dir$3/roh/$file.roh_chr.txt
$python_dir $roh_plot_dir/roh_density.py $file.roh.png $working_dir$3/roh/$file.roh_chr.txt
done
#plot density function for all chromosomes
$python_dir $roh_plot_dir/roh_density.py all_chromosomes_$3.png $working_dir$3/roh/*roh_chr.txt 

#get allele frequency
#https://vcftools.github.io/documentation.html
#./vcftools --vcf output.vcf --freq --out outputfreq
#bcftools roh --AF-tag $working_dir$3/outputfreq.frq $working_dir$3/output.vcf > $working_dir$3/roh/roh_freq_tab.txt
#roh for whole genome
#--GTs-only ignoring genotype likelihoods (FORMAT/PL)
bcftools roh -G30 --AF-dflt 0.4 $working_dir$3/output.vcf > $working_dir$3/roh/roh.txt
#AF 0.5
bcftools roh --AF-dflt 0.5 $working_dir$3/output.vcf > $working_dir$3/roh/roh_AF05.txt
#-e estimate AC and AF on the fly
#very slow
#bcftools roh -e GT - $working_dir$3/output.vcf > $working_dir$3/roh/roh_estimate.txt
#no indels
#bcftools roh -e PL - -i $working_dir$3/output.vcf > $working_dir$3/roh/roh_estimate_no_indels.txt
cd $working_dir$3/roh/
$python_dir $roh_plot_dir/roh_density.py whole_genome_$3.png roh*.txt 
for run in roh*.txt
do
$python_dir $roh_plot_dir/roh_density.py $run.png $run
$python_dir $roh_plot_dir/roh_stats.py $run
done

sudo rm $working_dir$3/$3.sra
sudo rm $working_dir$3/*fastq.*
sudo rm $working_dir$3/*bam*
sudo rm $working_dir$3/index*
sudo rm $working_dir$3/output.vcf
