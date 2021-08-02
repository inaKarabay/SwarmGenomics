import sys
import numpy as np
import matplotlib.pyplot as plt

#Arguments: RoH-File and Name of Chromosome
#Example: python roh_plot.py /vol/storage/VulpesLagupos/new_roh.txt NC_054824.1 name.png

print(sys.argv[1])
f=open(sys.argv[1],"r")
lines=f.readlines()
result=[]
counter=0
for x in lines:
    counter+=1
    #only take every 1111th number and for samples under 100000
    #if counter > 5 and counter%1111==2 and counter < 100000:
    #only for the first chromosome
    if counter > 5 and x.split('	')[2]==sys.argv[2]:
	    number=(x.split('	')[4])
	    if number=='0' or number=='1':
	    	result.append(number)
f.close()
y=np.arange(len(result))

print(len(y))

plt.plot(y, result, '.')
plt.ylabel('1=Homozygote, 0=Heterozygote')
plt.xlabel('Coordinate in Chromosome ' + sys.argv[1])
plt.savefig(sys.argv[2])

