cd gerasimos_shrec
/usr/local/MATLAB/R2020a/bin/matlab -nodisplay -nosplash -nodesktop -r "addpath('.');rehash;gerasimos_point_coud_registration_v2;exit;"
cd ..

cd shrec21
cd build
./shrec

cd ..
cd ..
cd gerasimos_shrec
/usr/local/MATLAB/R2020a/bin/matlab -nosplash -nodesktop -r "addpath('.');rehash;my_predicted = readcell('my_predicted.txt'); true_labels = readcell('true.txt') ;cm = confusionchart(true_labels, my_predicted); cm.RowSummary = 'row-normalized'; cm.ColumnSummary = 'column-normalized'"
cd ..