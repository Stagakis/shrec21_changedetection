#!/bin/bash

cd ChangeDetectionDatasetViewer
source venv/bin/activate
python3 data_viewer.py
cd ..

cd shrec21
mkdir build
cd build
cmake ..
make
./shrec 1
cd ..
cd ..

cd gerasimos_shrec
/usr/local/MATLAB/R2020a/bin/matlab -nodisplay -nosplash -nodesktop -r "addpath('.');rehash;point_coud_registration_v2;exit;"
cd ..
