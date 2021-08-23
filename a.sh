#!/bin/bash

#run script as sudo
#input= reference website (in quotation marks!), sra website (in quotation marks!), name of species
#IMPORTANT: reference from 1 individual only; collect data (sex; are fregments big enough)

#Example Indri: sudo ./pipeline.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/004/363/605/GCA_004363605.1_IndInd_v1_BIUU/GCA_004363605.1_IndInd_v1_BIUU_genomic.fna.gz" "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos3/sra-pub-run-21/SRR11430608/SRR11430608.1" IndriIndri 
#Vulpes: sudo ./a.sh "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/018/345/385/GCF_018345385.1_ASM1834538v1/GCF_018345385.1_ASM1834538v1_genomic.fna.gz" "https://sra-download.ncbi.nlm.nih.gov/traces/era23/ERR/ERR5417/ERR5417979" VulpesLagupos


#directories
trimmomatic_exe='/vol/storage/Trimmomatic-0.36/trimmomatic-0.36.jar'
working_dir='/vol/storage/'
psmc_dir='/vol/storage/psmc-master'
psmc_plot_dir='/home/ubuntu/Ina/SwarmGenomics'
roh_plot_dir='/home/ubuntu/Ina/SwarmGenomics'

cd $working_dir$3/vcf
for file in *
do 
echo $file
#-G genotypes (instead of genotype likelihoods)
bcftools roh -G30 --AF-dflt 0.4 $file > $working_dir$3/roh/$file.roh_chr.txt
python $roh_plot_dir/roh_density.py $file.roh.png $working_dir$3/roh/$file.roh_chr.txt
done
#plot density function for all chromosomes
python $roh_plot_dir/roh_density.py all_chromosomes_$3.png $working_dir$3/roh/*roh_chr.txt 
