clc;clear all;

path = '/mnt/storageDump/Shrec_change_detection_dataset_public/extracted_las_files/';
files_old = '/2016/';
files_new = '/2020/';

place = '0_5D4KVPBP';

median = strcat(path,place);

path_old = strcat(median,files_old);
path_new = strcat(median,files_new);

%%% We find the separated objects of each folder 
oldvertices_listing = dir(path_old);
newvertices_listing = dir(path_new);
dir(path_new).name

lengthoflist = length(oldvertices_listing);

%%% We read all the objects of the two folders 
for file = 5:5 %lengthoflist
    
oldfinlename = oldvertices_listing(file).name;
newfinlename = newvertices_listing(file).name;

fullpath_old = strcat(path_old,oldfinlename);
fullpath_new = strcat(path_new,newfinlename);

oldvertices = lasdata(fullpath_old)
newvertices = lasdata(fullpath_new);

ply = pcread(strcat(path_old,oldvertices_listing(6).name))

ptCloud = pointCloud([oldvertices.x oldvertices.y oldvertices.z]);
[model,inlierIndices,outlierIndices] = pcfitplane(ptCloud,0.5);
remainPtCloud = select(ptCloud,outlierIndices);
oldvertices_sim = remainPtCloud.Location;

ptCloud1 = pointCloud([newvertices.x newvertices.y newvertices.z]);
[model1,inlierIndices1,outlierIndices1] = pcfitplane(ptCloud1,0.5);
remainPtCloud1 = select(ptCloud1,outlierIndices1);
newvertices_sim = remainPtCloud1.Location;


%%% We save the new object
% fileID = fopen(strcat(oldfinlename,'_old.obj'), 'w');
% for i = 1:size(oldvertices_sim,1)
%     fprintf(fileID,'v %f %f %f\n',oldvertices_sim(i,1), oldvertices_sim(i,2), oldvertices_sim(i,3));     
% end
% fclose(fileID);
% 
% fileID = fopen(strcat(newfinlename,'_old.obj'), 'w');
% for i = 1:size(newvertices_sim,1)
%     fprintf(fileID,'v %f %f %f\n',newvertices_sim(i,1), newvertices_sim(i,2), newvertices_sim(i,3));     
% end
% fclose(fileID);

end

k = 5;

class = mydbscan(oldvertices_sim,k);
class = class + 1;
max(class)
min(class)


%%% How many points each cluster has?
 for k = 1:max(class)
      count(k) = sum(class==k);
      ind{k} = find(class==k);
 end

%%% How many of these clusters have more than k points? I choose the 5% of the totally point cloud
bigclusters = floor(0.005*size(oldvertices_sim,1)); %3000; %6000;
numofbigclusters= sum(count>bigclusters);

%%% Create unique colors based on the number of clusters
cmp = colormap(jet(512));
step = floor(size(cmp,1)/max(class));
for k = 1:max(class)
     k1 = rand;
     k2 = rand;
     k3 = rand;
    for j = 1:size(ind{k},1)
        color(ind{k}(j,1),:) = [k1 k2 k3]; %[k/max(class) k1 k2];
    end
end


prename = 'clustering_';
fullname = strcat(prename,oldfinlename);
fullname = string(extractBetween(fullname, 1, length(fullname) - 4)); % to remove the .las
fullnameobj = strcat(fullname,'.obj');

fileID = fopen(fullnameobj, 'w'); %clustering_45.obj
for i = 1:size(oldvertices_sim,1)
        fprintf(fileID,'v %f %f %f %f %f %f\n',oldvertices_sim(i,1), oldvertices_sim(i,2), oldvertices_sim(i,3), color(i,1), color(i,2), color(i,3));     
end
fclose(fileID);


