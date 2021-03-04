clc;clear all;
config = ini2struct("../ChangeDetectionDatasetViewer/config.ini")
config_out_dir = config.x20160x2D2020.out_dir;

ref_normal = [0,0,1];
degree_tolerance = 15;
sparsity_threshold = 100;

path = config_out_dir; %'/mnt/storageDump/Shrec_change_detection_dataset_public/extracted_las_files_test/';
files_old = '/2016/';
files_new = '/2020/';

scenes = dir(config_out_dir);
for scene = 3:length(scenes) %start from 3 to get past "." and ".." directories
place = scenes(scene).name
%place = '10_5D4KVPXD'


median = strcat(path,place);

path_old = strcat(median,files_old);
path_new = strcat(median,files_new);

%%% We find the separated objects of each folder 
oldvertices_listing = dir(fullfile(path_old, '*_original.ply'));
newvertices_listing = dir(fullfile(path_new, '*_original.ply'));
csv_name = dir(fullfile(median, '*.csv'));

oldvertices_listing_sort=natsortfiles({oldvertices_listing.name});
newvertices_listing_sort=natsortfiles({newvertices_listing.name});

lengthoflist = length(oldvertices_listing);

all_information = readtable(strcat(median,'/',csv_name.name));
point_of_interest = table2array(all_information(:,2:4));
%%% We read all the objects of the two folders 
for file = 1:lengthoflist

oldfinlename = oldvertices_listing_sort{file}; %oldvertices_listing(file).name;
newfinlename = newvertices_listing_sort{file}; %newvertices_listing(file).name;

fullpath_old = strcat(path_old,oldfinlename)
fullpath_new = strcat(path_new,newfinlename);

% oldvertices = lasdata(fullpath_old);
% newvertices = lasdata(fullpath_new);

oldvertices = plyread(fullpath_old);
newvertices = plyread(fullpath_new);

pcl_xyzrgb_old = pointCloud(single([oldvertices.vertex.x oldvertices.vertex.y oldvertices.vertex.z]));
pcl_xyzrgb_old.Color = uint8([oldvertices.vertex.red oldvertices.vertex.green oldvertices.vertex.blue]);

pcl_xyzrgb_new = pointCloud(single([newvertices.vertex.x newvertices.vertex.y newvertices.vertex.z]));
pcl_xyzrgb_new.Color = uint8([newvertices.vertex.red newvertices.vertex.green newvertices.vertex.blue]);

pcwrite(pcl_xyzrgb_old,"old_original.ply");
pcwrite(pcl_xyzrgb_new,"new_original.ply");

ptCloud = pointCloud([oldvertices.vertex.x oldvertices.vertex.y oldvertices.vertex.z]);
[model,inlierIndices,outlierIndices] = pcfitplane(ptCloud,0.5, ref_normal, degree_tolerance);
if(isempty(outlierIndices))
    'empty, filling...'
    outlierIndices = 1:size(ptCloud.Location, 1);
end
remainPtCloud = select(ptCloud,outlierIndices);
oldvertices_sim = remainPtCloud.Location; 

ptCloud1 = pointCloud([newvertices.vertex.x newvertices.vertex.y newvertices.vertex.z]);
[model1,inlierIndices1,outlierIndices1] = pcfitplane(ptCloud1,0.5, ref_normal, degree_tolerance);
if(isempty(inlierIndices1))
    'empty, filling...'
    inlierIndices1 = 1:size(ptCloud1.Location, 1);
end
remainPtCloud1 = select(ptCloud1,outlierIndices1);
newvertices_sim = remainPtCloud1.Location;


if size(select(pcl_xyzrgb_old,outlierIndices).Location,1) < sparsity_threshold || size(select(pcl_xyzrgb_new,outlierIndices1).Location,1) < sparsity_threshold
    'Too sparse after ground removal, saving original and moving on'
    pcwrite(pcl_xyzrgb_old, strcat(fullpath_old(1:size(fullpath_old,2) - 4),'_clustered.ply'));
    pcwrite(pcl_xyzrgb_new, strcat(fullpath_new(1:size(fullpath_new,2) - 4),'_clustered.ply'));
    pcl_xyzrgb_old = select(pcl_xyzrgb_old,outlierIndices);
    pcwrite(pcl_xyzrgb_old,"old_nofloor.ply");
    pcl_xyzrgb_new = select(pcl_xyzrgb_new,outlierIndices1);
    pcwrite(pcl_xyzrgb_new, "new_nofloor.ply");
    continue
end

pcl_xyzrgb_old = select(pcl_xyzrgb_old,outlierIndices);
pcwrite(pcl_xyzrgb_old,"old_nofloor.ply");

pcl_xyzrgb_new = select(pcl_xyzrgb_new,outlierIndices1);
pcwrite(pcl_xyzrgb_new, "new_nofloor.ply");

k = 5;

%we estimate the density clusters of each object
old_class = mydbscan(oldvertices_sim,k);
new_class = mydbscan(newvertices_sim,k);

max(old_class);
max(new_class);

numofsalientneig = 20;  
akdtreeobj_old = KDTreeSearcher(oldvertices_sim,'distance','euclidean');
[closest_point_old, DD] = knnsearch(akdtreeobj_old,point_of_interest(file,:),'k',numofsalientneig);

akdtreeobj_new = KDTreeSearcher(newvertices_sim,'distance','euclidean');
[closest_point_new, DD] = knnsearch(akdtreeobj_new,point_of_interest(file,:),'k',numofsalientneig);

unique_old_classes = unique(old_class(closest_point_old,1));
unique_new_classes = unique(new_class(closest_point_new,1));

ind_old_point = [];
for i = 1:size(unique_old_classes,1)
    ind_old_point = [ind_old_point find(old_class==unique_old_classes(i,1))']; 
end

ind_new_point = [];
for i = 1:size(unique_new_classes,1)
ind_new_point = [ind_new_point find(new_class==unique_new_classes(i,1))']; %new_class(closest_point_new,1)); 
end

cluster_indeces_old = [];
kk = 1;
for i = 1:size(oldvertices_sim,1)
     if sum(find(ind_old_point == i)>0)
         oldvertices_cluster(kk,:) = oldvertices_sim(i,:);
         cluster_indeces_old = [cluster_indeces_old; i];
         kk=kk+1;
     end
end

 jj=1;
 cluster_indeces_new = [];
for i = 1:size(newvertices_sim,1)
      if sum(find(ind_new_point == i)>0)
         newvertices_cluster(jj,:) = newvertices_sim(i,:);
         cluster_indeces_new = [cluster_indeces_new; i];
         jj=jj+1;
      end
end


if size(select(pcl_xyzrgb_old,cluster_indeces_old).Location,1) < sparsity_threshold || size(select(pcl_xyzrgb_new,cluster_indeces_new).Location,1) < sparsity_threshold
    'Too sparse after clustering, saving only with without floor...'
    pcwrite(pcl_xyzrgb_old, strcat(fullpath_old(1:size(fullpath_old,2) - 4),'_clustered.ply'));
    pcwrite(pcl_xyzrgb_new, strcat(fullpath_new(1:size(fullpath_new,2) - 4),'_clustered.ply'));
    pcl_xyzrgb_old = select(pcl_xyzrgb_old,cluster_indeces_old);
    pcwrite(pcl_xyzrgb_old, "old_clustered.ply" );
    pcl_xyzrgb_new = select(pcl_xyzrgb_new,cluster_indeces_new);
    pcwrite(pcl_xyzrgb_new, "new_clustered.ply");
    continue
end
pcl_xyzrgb_old = select(pcl_xyzrgb_old,cluster_indeces_old);
pcwrite(pcl_xyzrgb_old, "old_clustered.ply" );
pcl_xyzrgb_new = select(pcl_xyzrgb_new,cluster_indeces_new);
pcwrite(pcl_xyzrgb_new, "new_clustered.ply");

pcwrite(pcl_xyzrgb_old, strcat(fullpath_old(1:size(fullpath_old,2) - 4),'_clustered.ply'));
pcwrite(pcl_xyzrgb_new, strcat(fullpath_new(1:size(fullpath_new,2) - 4),'_clustered.ply'));
end
end
'DONE'