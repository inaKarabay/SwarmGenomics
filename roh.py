import sys
import numpy as np
import matplotlib.pyplot as plt


print(sys.argv[1])
f=open(sys.argv[1],"r")
lines=f.readlines()
result=[]
counter=0
for x in lines:
    counter+=1
    #only take every 1111th number and for samples under 100000
    if counter > 5 and counter%1111==2 and counter < 100000:
	    number=(x.split('	')[4])
	    if number=='0' or number=='1':
	    	result.append(number)
f.close()
y=np.arange(len(result))

print(len(y))

plt.plot(y, result)
plt.ylabel('length')
plt.xlabel('RoH')
plt.show()

