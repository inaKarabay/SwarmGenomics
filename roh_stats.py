import sys
import numpy as np
from numpy import mean


#Arguments: RoH-File and Name of Chromosome
#Example: python roh_plot.py /vol/storage/VulpesLagupos/new_roh.txt

print(sys.argv[1])
f=open(sys.argv[1],"r")
lines=f.readlines()
result_1=[]
result_0=[]
length_roh=[]
counter=0
for x in lines:
    counter+=1
    #only take every 1111th number and for samples under 100000
    #if counter > 5 and counter%1111==2 and counter < 100000:
    #only for the first chromosome
    if counter > 5 and x.split('	')[0]=="RG":
	    length_roh.append(int(x.split('	')[5]))
	    
    if counter > 5:
	    number=(x.split('	')[4])
	    if number=='0':
	    	result_0.append(number)
	    if number=='1':
	    	result_1.append(number)
    
	
f.close()

print("Heterozygot", len(result_0))
print("Homozygot", len(result_1))
print("Amount of RG", len(length_roh))
print("Average length", sum(length_roh) / len(length_roh))

