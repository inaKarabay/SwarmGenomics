#!/bin/bash

#run script as sudo
#input= reference website (in quotation marks!), sra website (in quotation marks!), name of species
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

#Example Indri: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/004/363/605/GCA_004363605.1_IndInd_v1_BIUU/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-21/SRR11430608/SRR11430608.1" IndriIndri 
#Vulpes: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/018/345/385/GCF_018345385.1_ASM1834538v1/GCF_018345385.1_ASM1834538v1_genomic.fna.gz" "https://sra-download.ncbi.nlm.nih.gov/traces/era23/ERR/ERR5417/ERR5417979" VulpesLagupos


#directories
trimmomatic_exe='/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir='/vol/storage/'
psmc_dir='/vol/storage/psmc-master'
psmc_plot_dir='/home/ubuntu/Ina/SwarmGenomics'
roh_plot_dir='/home/ubuntu/Ina/SwarmGenomics'

big=`cat $working_dir$3/chromosomes_length.txt | awk '$(NF) >= 1000000  {print $1}'`

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
bcftools roh -G30 --AF-dflt 0.4 $file.vcf > $file_roh_chr.txt
done
#plot density function for all chromosomes
python $roh_plot_dir/roh_density.py all_chromosomes_$3.png *roh_chr.txt 

#get allele frequency
#https://vcftools.github.io/documentation.html
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
python $roh_plot_dir/roh_density.py whole_genome_$3.png roh*.txt 
for run in roh*.txt:
do
python $roh_plot_dir/roh_density.py $run_$3.png $run
done