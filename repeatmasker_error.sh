#!/bin/bash

#check if h5py is installed and module can be imported
python /vol/storage/test2.py

#run h5py test
# -> 3 errors
python /vol/storage/test.py

read -p "Press any key to continue"

#run repeatmasker
cd /vol/storage/RepeatMasker/
sudo perl ./configure
# Enter: /home/ubuntu/miniconda3/bin/trf  (trf-path)
# Enter: 2 (RMBlast)
# Enter: /usr/local/rmblast/bin (RMBLAST_DIR)
# Enter: Y
# Enter: 5

#ModuleNotFoundError