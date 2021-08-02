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
#example -u 3.83e-08 mutation rate
# -g 31 generation in years
$psmc_dir/utils/psmc_plot.pl $chromosome $chromosome.psmc
python $psmc_plot_dir/psmc_plot.py $chromosome.png $chromosome.psmc
#open image
#gv $chromosome.eps
done
python $psmc_plot_dir/psmc_plot.py all.png *.psmc

