cd matlab_shrec
/usr/local/MATLAB/R2020a/bin/matlab -nosplash -nodesktop -r "addpath('.');rehash;my_predicted = readcell('my_predicted.txt'); true_labels = readcell('true.txt') ;cm = confusionchart(true_labels, my_predicted); cm.RowSummary = 'row-normalized'; cm.ColumnSummary = 'column-normalized'"
cd ..