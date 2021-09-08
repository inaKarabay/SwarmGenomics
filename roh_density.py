import sys
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns

#Arguments: RoH-File and Name of Chromosome
#Example: python roh_density.py name.png /vol/storage/VulpesLagupos/results_with_repeats/roh_with_repeats.txt 




for chr in sys.argv[2:]:
	f=open(chr,"r")
	lines=f.readlines()
	result=[]
	counter=0
	for x in lines:
    		counter+=1
    		#only for the first chromosome
    		if counter > 5 and x.split('	')[0]=="RG":
	    		length=(x.split('	')[5])
	    		result.append(length)
	f.close()
	sns.distplot(result, hist = False, kde = True)
	#values, base = np.histogram(result, bins=4000)
	#cumulative = np.cumsum(values)
	#plt.plot(base[:-1], cumulative, c='blue')
	#sorted_data = np.sort(result)
	#plt.step(sorted_data, np.arange(sorted_data.size))  # From 0 to the number of data points-1
	#plt.step(sorted_data[::-1], np.arange(sorted_data.size))  # From the number of data points-1 to 0
plt.title('Density Plot')
plt.ylabel('Density of RoH fragments')
plt.xlabel('Length of RoH in bases')
#log scale
#plt.yscale('log') 
plt.savefig(sys.argv[1])



