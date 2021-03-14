clc;clear all;
config = ini2struct("../ChangeDetectionDatasetViewer/config.ini")
config_out_dir = config.x20160x2D2020.out_dir;

path = config_out_dir;
files_old = '/2016/';
files_new = '/2020/';
true_labels = [];
predicted_labels = [];
places = [];
scenes = dir(path); %'extracted_las_files/'
create_figures = 0;

for scene = 3:length(scenes) %start from 3 to get past "." and ".." directories
place = scenes(scene).name
places = [places; {place}]
%place = '16_5D4KVT48/';

median = strcat(path,place);

path_old = strcat(median,files_old);
path_new = strcat(median,files_new);

%%% We find the separated objects of each folder 
oldvertices_listing = dir(fullfile(path_old, '*_original.ply'));
newvertices_listing = dir(fullfile(path_new, '*_original.ply'));
csv_name = dir(fullfile(median, '*.csv'));

oldvertices_listing_sort=natsortfiles({oldvertices_listing.name});
newvertices_listing_sort=natsortfiles({newvertices_listing.name});

% oldvertices = lasdata('extracted_las_files/0_5D4KVPBP/2016/0_5D4KVPBP_0.las');
% newvertices = lasdata('extracted_las_files/0_5D4KVPBP/2020/0_5D4KVPBP_0.las');

lengthoflist = length(oldvertices_listing);

path_csv = strcat(median,csv_name.name);

all_information = readtable(strcat(median,'/',csv_name.name));
point_of_interest = table2array(all_information(:,2:4));
labels = table2array(all_information(:,5:5));

%%% We read all the objects of the two folders 
for file = 1:lengthoflist
file
true_labels = [true_labels ; labels(file)];

oldfinlename = oldvertices_listing_sort{file} %oldvertices_listing(file).name;
newfinlename = newvertices_listing_sort{file}; %newvertices_listing(file).name;

fullpath_old = strcat(path_old,oldfinlename);
fullpath_new = strcat(path_new,newfinlename);

% oldvertices = lasdata(fullpath_old);
% newvertices = lasdata(fullpath_new);

oldvertices = plyread(fullpath_old);
newvertices = plyread(fullpath_new);


% oldvertices_sim(:,1) = oldvertices.x(:,1);
% oldvertices_sim(:,2) = oldvertices.y(:,1);
% oldvertices_sim(:,3) = oldvertices.z(:,1);

%  newvertices_sim(:,1) = newvertices.x(:,1);
%  newvertices_sim(:,2) = newvertices.y(:,1);
%  newvertices_sim(:,3) = newvertices.z(:,1);

%%% We remove the biggest plane area of each object 
ptCloud = pointCloud([oldvertices.vertex.x oldvertices.vertex.y oldvertices.vertex.z]);
[model,inlierIndices,outlierIndices] = pcfitplane(ptCloud,0.9, [0, 0, 1], 25);
if(isempty(outlierIndices))
    oldvertices_sim_o = [0 0 0];
else
    remainPtCloud = select(ptCloud,outlierIndices);
    oldvertices_sim_o = remainPtCloud.Location;
end

ptCloud1 = pointCloud([newvertices.vertex.x newvertices.vertex.y newvertices.vertex.z]);
[model1,inlierIndices1,outlierIndices1] = pcfitplane(ptCloud1,0.9, [0, 0, 1], 25);
if(isempty(outlierIndices1))
    newvertices_sim_o = [0 0 0];
else
   remainPtCloud1 = select(ptCloud1,outlierIndices1);
    newvertices_sim_o = remainPtCloud1.Location;
end

oldvertices_sim = oldvertices_sim_o;
newvertices_sim = newvertices_sim_o;


thres1_new = 100; %floor(0.01*size(newvertices.vertex.x,1));
thres1_old = 100; %floor(0.01*size(oldvertices.vertex.x,1));

% if floor(0.1*size(newvertices.vertex.x,1)) < thres1_new
thres2_new = 200;
% else
% thres2_new = floor(0.1*size(newvertices.vertex.x,1));
% end

% if floor(0.1*size(oldvertices.vertex.x,1)) < thres1_old
thres2_old = 200;
% else
% thres2_old = floor(0.1*size(oldvertices.vertex.x,1));
% end



if size(newvertices_sim,1) < thres1_new && size(oldvertices_sim,1) < thres1_old
    'nochange' 
    true_labels{file}
    predicted_labels = [predicted_labels; {'nochange'}];
%     continue;
elseif size(newvertices_sim,1) < thres1_new && size(oldvertices_sim,1) > thres2_old
    'removed' 
    true_labels{file}
    predicted_labels = [predicted_labels; {'removed'}];
%     continue;
elseif size(newvertices_sim,1) > thres2_new && size(oldvertices_sim,1) < thres1_old
    'added' 
    true_labels{file}   
    predicted_labels = [predicted_labels; {'added'}];
%     continue;
else

if create_figures
%%% We save the new object
fileID = fopen(strcat(oldfinlename,'_old.obj'), 'w');
for i = 1:size(oldvertices_sim,1)
    fprintf(fileID,'v %f %f %f\n',oldvertices_sim(i,1), oldvertices_sim(i,2), oldvertices_sim(i,3));     
end
fclose(fileID);

fileID = fopen(strcat(newfinlename,'_new.obj'), 'w');
for i = 1:size(newvertices_sim,1)
    fprintf(fileID,'v %f %f %f\n',newvertices_sim(i,1), newvertices_sim(i,2), newvertices_sim(i,3));     
end
fclose(fileID);
end

k = 20;

%we estimate the density clusters of each object
old_class = mydbscan(oldvertices_sim,k);
new_class = mydbscan(newvertices_sim,k);

% max(old_class);
% max(new_class);
% 
% 
% for k = 1:max(old_class)
%       count_old(k) = sum(old_class==k);
%       ind_old{k} = find(old_class==k);
% end
% 
% index_old_small_patches = find(count_old<20);
% 
% index_old_small_patches_all = [];
% for i=1:size(index_old_small_patches,2)
%    index_old_small_patches_all =  [index_old_small_patches_all ind_old{index_old_small_patches(1,i)}'];
% end
% 
% oldvertices_sim(index_old_small_patches_all,:) = [];
% 
% 
% 
% for k = 1:max(new_class)
%       count_new(k) = sum(new_class==k);
%       ind_new{k} = find(new_class==k);
% end
% 
% index_new_small_patches = find(count_new<20);
% 
% index_new_small_patches_all = [];
% for i=1:size(index_new_small_patches,2)
%    index_new_small_patches_all =  [index_new_small_patches_all ind_new{index_new_small_patches(1,i)}'];
% end
% 
% newvertices_sim(index_new_small_patches_all,:) = [];

% cmp = colormap(jet(512));
% step = floor(size(cmp,1)/max(old_class));
% 
% for k = 1:max(old_class)
%      k1 = rand;
%      k2 = rand;
%      k3 = rand;
%     for j = 1:size(ind{k},1)
%         color(ind{k}(j,1),:) = [k1 k2 k3]; %[k/max(class) k1 k2];
%     end
% end
% 
% prename = 'clustering_';
% fullname = strcat(prename,oldfinlename);
% fullnameobj = strcat(fullname,'_.obj');
% 
% fileID = fopen(fullnameobj, 'w'); %clustering_45.obj
% for i = 1:size(oldvertices_sim,1)
%         fprintf(fileID,'v %f %f %f %f %f %f\n',oldvertices_sim(i,1), oldvertices_sim(i,2), oldvertices_sim(i,3), color(i,1), color(i,2), color(i,3));     
% end
% fclose(fileID);



numofsalientneig = 25;  
akdtreeobj_old = KDTreeSearcher(oldvertices_sim,'distance','euclidean');
[closest_point_old, DD_old] = knnsearch(akdtreeobj_old,point_of_interest(file,:),'k',numofsalientneig);

akdtreeobj_new = KDTreeSearcher(newvertices_sim,'distance','euclidean');
[closest_point_new, DD_new] = knnsearch(akdtreeobj_new,point_of_interest(file,:),'k',numofsalientneig);

if DD_old(1,1)>1.5
    ind_old_point = [1 2 3];
else
    unique_old_classes = unique(old_class(closest_point_old,1));

    ind_old_point = [];
    for i = 1:size(unique_old_classes,1)
        ind_old_point = [ind_old_point find(old_class==unique_old_classes(i,1))']; 
    end
end


if DD_new(1,1)>1.5
    ind_new_point = [1 2 3];
else
    unique_new_classes = unique(new_class(closest_point_new,1));
    
    ind_new_point = [];
    for i = 1:size(unique_new_classes,1)
        ind_new_point = [ind_new_point find(new_class==unique_new_classes(i,1))']; %new_class(closest_point_new,1)); 
    end
end

% if create_figures
% %%% We save the new object
% fileID = fopen(strcat(oldfinlename,'_cluster_old.obj'), 'w');
 kk = 1;
for i = 1:size(oldvertices_sim,1)
     if sum(find(ind_old_point == i)>0)
%         fprintf(fileID,'v %f %f %f\n',oldvertices_sim(i,1), oldvertices_sim(i,2), oldvertices_sim(i,3));
         oldvertices_cluster(kk,:) = oldvertices_sim(i,:);
         kk=kk+1;
     end
end
% fclose(fileID);

% fileID = fopen(strcat(newfinlename,'_cluster_new.obj'), 'w');
 jj=1;
for i = 1:size(newvertices_sim,1)
      if sum(find(ind_new_point == i)>0)
%         fprintf(fileID,'v %f %f %f\n',newvertices_sim(i,1), newvertices_sim(i,2), newvertices_sim(i,3)); 
         newvertices_cluster(jj,:) = newvertices_sim(i,:);
         jj=jj+1;
      end
end
% fclose(fileID);
% end

    clearvars oldvertices_sim newvertices_sim
oldvertices_sim = oldvertices_cluster;
newvertices_sim = newvertices_cluster;



% fileID = fopen(strcat(oldfinlename,'_old.obj'), 'w');
% o = 1;
% for i = 1:size(oldvertices.x,1)
% %     if oldvertices.z(i,1) > min(oldvertices.z) + 0.1
%            fprintf(fileID,'v %f %f %f\n',oldvertices.x(i,1), oldvertices.y(i,1), oldvertices.z(i,1));     
%             oldvertices_sim(o,1) = oldvertices.x(i,1);
%             oldvertices_sim(o,2) = oldvertices.y(i,1);
%             oldvertices_sim(o,3) = oldvertices.z(i,1);
%             o = o + 1;
% %     end
% %    fprintf(fileID,'v %f %f %f\n',oldvertices.x(i,1), oldvertices.y(i,1), oldvertices.z(i,1));     
% end
% fclose(fileID);
% 
% fileID = fopen(strcat(newfinlename,'_new.obj'), 'w');
% o1 = 1;
% for i = 1:size(newvertices.x,1)
% %    if newvertices.z(i,1) > min(newvertices.z) + 0.1
%         fprintf(fileID,'v %f %f %f\n',newvertices.x(i,1), newvertices.y(i,1), newvertices.z(i,1));     
%         newvertices_sim(o1,1) = newvertices.x(i,1);
%         newvertices_sim(o1,2) = newvertices.y(i,1);
%         newvertices_sim(o1,3) = newvertices.z(i,1);
%         o1 = o1 + 1;
% %    end
% %    fprintf(fileID,'v %f %f %f\n',newvertices.x(i,1), newvertices.y(i,1), newvertices.z(i,1));     
% end
% fclose(fileID);


% if size(newvertices_sim,1) < 300 || size(oldvertices_sim,1) < 300
%     clearvars oldvertices_sim newvertices_sim
% %     oldvertices_sim(:,1) = oldvertices.vertex.x;
% %     oldvertices_sim(:,2) = oldvertices.vertex.y;
% %     oldvertices_sim(:,3) = oldvertices.vertex.z;
% %     
% %     newvertices_sim(:,1) = newvertices.vertex.x;
% %     newvertices_sim(:,2) = newvertices.vertex.y;
% %     newvertices_sim(:,3) = newvertices.vertex.z;
%     oldvertices_sim = oldvertices_sim_o;
%     newvertices_sim = newvertices_sim_o;  
% end
% 



if size(newvertices_sim,1) > 3 && size(oldvertices_sim,1) > 3
%%%%%%%%%%%%%%%% Registration 
ptCloud_new = pointCloud([newvertices_sim(:,1) newvertices_sim(:,2) newvertices_sim(:,3)]);
ptCloud_old = pointCloud([oldvertices_sim(:,1) oldvertices_sim(:,2) oldvertices_sim(:,3)]);

% [TR,TT,registred] = myweighedticp(newvertices_sim',oldvertices_sim',0);
[tform,register] = pcregrigid(ptCloud_new,ptCloud_old); %pcregrigid pcregisterndt

registered = register.Location;
newvertices_sim = registered;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fileID = fopen(strcat('registered_',strcat(newfinlename,'_old.obj')), 'w');
% for i = 1:size(registred,2)
%         fprintf(fileID,'v %f %f %f\n',registred(1,i), registred(2,i), registred(3,i));     
% end
% fclose(fileID);

% ptCloud_old_sim = pointCloud([oldvertices_sim(:,1) oldvertices_sim(:,2) oldvertices_sim(:,3)]);
% ptCloudOut_old_sim = pcdownsample(ptCloud_old_sim,'gridAverage',0.9);
% 
% ptCloud_new_sim = pointCloud([newvertices_sim(:,1) newvertices_sim(:,2) newvertices_sim(:,3)]);
% ptCloudOut_new_sim = pcdownsample(ptCloud_new_sim,'gridAverage',0.9);
% 
% 
% clearvars oldvertices_sim newvertices_sim
% oldvertices_sim = ptCloudOut_old_sim.Location;
% newvertices_sim = ptCloudOut_new_sim.Location;


%%%%%%%%%%%%%%%%%%%%%%%%%
numofsalientneig = 25;  %%%We search for the closest point of the other point cloud

%%%%% Distance between neighbor points of reference frame to remove spatial outliers
% apoints11 = double(newvertices1);
akdtreeobj = KDTreeSearcher(newvertices_sim,'distance','euclidean');
[aAdjOfPoints, DD] = knnsearch(akdtreeobj,oldvertices_sim,'k',numofsalientneig);%registered
% [k1 l1] = hist(DD);
adjofpoints = unique(aAdjOfPoints);
newvertices_simnewvertices_sim = newvertices_sim;
newvertices_simnewvertices_sim(adjofpoints,:) = [];
% 

akdtreeobj1 = KDTreeSearcher(oldvertices_sim,'distance','euclidean');
[aAdjOfPoints1, DD1] = knnsearch(akdtreeobj1,newvertices_sim,'k',numofsalientneig);
% [k2 l2] = hist(DD1);
adjofpoints1 = unique(aAdjOfPoints1);
oldvertices_simoldvertices_sim = oldvertices_sim;
oldvertices_simoldvertices_sim(adjofpoints1,:) = [];
% 


% fileID = fopen('new.obj', 'w');     
% for i = 1:size(newvertices_simnewvertices_sim,1)
%          fprintf(fileID,'v %f %f %f \n',newvertices_simnewvertices_sim(i,1), newvertices_simnewvertices_sim(i,2), newvertices_simnewvertices_sim(i,3));
% end
% fclose(fileID);
% fileID = fopen('old.obj', 'w');     
% for i = 1:size(oldvertices_simoldvertices_sim,1)
%          fprintf(fileID,'v %f %f %f \n',oldvertices_simoldvertices_sim(i,1), oldvertices_simoldvertices_sim(i,2), oldvertices_simoldvertices_sim(i,3));
% end
% fclose(fileID);


% figure(file)
% hist1 = histogram(DD);
% hold on
% hist2 = histogram(DD1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if create_figures
%%%%%%%%%%%%%%%%%%%%%%%% Create heatmap 
  range2 = max(DD(:,1)); 
  cmp = colormap(jet);
  sizecmp2 = size(cmp,1);
  step2 = range2/sizecmp2;

     for i = 1:size(aAdjOfPoints,1)
         k = 1;
         while((DD(i,1) > k*step2) && k < sizecmp2) %% we use only 16 from a 64 colormap  
             k = k + 1;
         end
         color(i,:) = cmp((k-1) + 1,:);
     end

     
fileID = fopen(strcat('registered_',strcat(newfinlename,'_old.obj')), 'w');
for i = 1:size(oldvertices_sim,1)
         fprintf(fileID,'v %f %f %f %f %f %f\n',oldvertices_sim(i,1), oldvertices_sim(i,2), oldvertices_sim(i,3), color(i,1), color(i,2), color(i,3));
end
fclose(fileID);


  range21 = max(DD1(:,1)); 
  cmp = colormap(jet);
  sizecmp21 = size(cmp,1);
  step21 = range21/sizecmp21;

     for i = 1:size(aAdjOfPoints1,1)
         k = 1;
         while((DD1(i,1) > k*step21) && k < sizecmp21) %% we use only 16 from a 64 colormap  
             k = k + 1;
         end
         color1(i,:) = cmp((k-1) + 1,:);
     end

fileID = fopen(strcat('registered_',strcat(newfinlename,'_new.obj')), 'w');     
% fileID = fopen(strcat(newfinlename,strcat('_registered','_old.obj')), 'w');
for i = 1:size(newvertices_sim,1)
         fprintf(fileID,'v %f %f %f %f %f %f\n',newvertices_sim(i,1), newvertices_sim(i,2), newvertices_sim(i,3), color1(i,1), color1(i,2), color1(i,3));
end
fclose(fileID);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% corre(file,1) = corr2(k1, k2);
   
% Obtain the vectors of bin counts. Use the set of edges returned from the first call
% as an input to the second call so the vector of bin counts are the same length and
% measure "apples to apples"
if size(DD,2) > 10
    DD_rec = 10;
else
    DD_rec = size(DD,2);
end

if size(DD1,2) > 10
    DD1_rec = 10;
else
    DD1_rec = size(DD1,2);
end
[n1, edges1] = histcounts(mean(DD(:,1:DD_rec),2),50);
[n2, edges2] = histcounts(mean(DD1(:,1:DD1_rec),2),50);

 mean_DD = mean(DD(:,1:DD_rec),2);
 mean_DD1 = mean(DD1(:,1:DD1_rec),2);
% 
index_DD_far = find(mean_DD > min(edges1(1,40),edges2(1,40)));
index_DD1_far = find(mean_DD1 > min(edges1(1,40),edges2(1,40)));
% 
 vertices_old_DD_far = oldvertices_sim(index_DD_far,:);
 vertices_new_DD_far = newvertices_sim(index_DD1_far,:);

 nn1 = n1(1,40:50)*edges1(1,41:51)';
 nn2 = n2(1,40:50)*edges2(1,41:51)';

% %  if size(vertices_old_DD_far,1) >=7 && size(vertices_new_DD_far,1) >=7
%      try
% [TriIdx_old, V_old] = convhull(vertices_old_DD_far(:,1),vertices_old_DD_far(:,2),vertices_old_DD_far(:,3));
%    Vall_old(file,1) = V_old;
%      catch 
%  Vall_old(file,1) = 0;
%      end
%  
%        try
%      [TriIdx_new, V_new] = convhull(vertices_new_DD_far(:,1),vertices_new_DD_far(:,2),vertices_new_DD_far(:,3));
%     Vall_new(file,1) = V_new;
%        catch 
%  Vall_new(file,1) = 0;
%        end
%      
%      Vall(file,1) = Vall_new(file,1)-Vall_old(file,1);

% old_RR = vertices_old_DD_far'*vertices_old_DD_far;
% [old_eigv old_eigev] = eig(old_RR);
% 
% new_RR = vertices_new_DD_far'*vertices_new_DD_far;
% [new_eigv new_eigev] = eig(new_RR);
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fileID = fopen('test_old.obj', 'w');
% % fileID = fopen(strcat('test_',strcat(newfinlename,'_old.obj')), 'w');
% for i = 1:size(vertices_old_DD_far,1)
%          fprintf(fileID,'v %f %f %f\n',vertices_old_DD_far(i,1), vertices_old_DD_far(i,2), vertices_old_DD_far(i,3));
% end
% fclose(fileID);
% 
% fileID = fopen('test_new.obj', 'w');
% % fileID = fopen(strcat('test_',strcat(newfinlename,'_old.obj')), 'w');
% for i = 1:size(vertices_new_DD_far,1)
%          fprintf(fileID,'v %f %f %f\n',vertices_new_DD_far(i,1), vertices_new_DD_far(i,2), vertices_new_DD_far(i,3));
% end
% fclose(fileID);

% corr2(old_RR,new_RR)

% sum_percentage = 0;
% for i = 30:50
%    sum_percentage =  sum_percentage + abs(n1(1,i)-n2(1,i))./max(n1(1,i),n2(1,i));
% end

% if max(edges1) > max(edges2)
% n2 = histcounts(DD1, edges1);
% else
% n1 = histcounts(DD, edges2);
% end
 per_all = (sum(n1(1,40:end))-sum(n2(1,40:end)))./sum(n2(1,40:end));
 norm_all = norm(n1(1,40:end)-n2(1,40:end),2); %/abs(sum(n1(1,30:end))-sum(n2(1,30:end))); %./max(n1(1,30:end),n2(1,30:end))
sum_all = sum(n1(1,40:end)-n2(1,40:end));
%    [norm_all per_all max(edges1) max(edges2)]% min(size(index_DD_far,1),size(index_DD1_far,1))/max(size(index_DD_far,1),size(index_DD1_far,1))] %sum_all size(newvertices_sim,1)\size(oldvertices_sim,1)
% [old_eigev(1,1) old_eigev(2,2) old_eigev(3,3)]  
% [new_eigev(1,1) new_eigev(2,2) new_eigev(3,3)]  
% norm(old_eigev-new_eigev,2)
%  Vall(file,1) 
if size(newvertices_sim,1) <=3 && size(oldvertices_sim,1) <=3
   'nochange'
    true_labels{file}   
    predicted_labels = [predicted_labels; {'nochange'}];
%     continue;
elseif size(newvertices_sim,1) <=3 && size(oldvertices_sim,1) >50
%     if norm_all < 10
%     'change2'
%     true_labels{file}    
%     predicted_labels = [predicted_labels; {'change'}];
%     else
    'removed'
    true_labels{file}    
    predicted_labels = [predicted_labels; {'removed'}];
%     continue;
%     end
elseif size(newvertices_sim,1) >50 && size(oldvertices_sim,1) <=3
%     if norm_all < 10
%     'change2'
%     true_labels{file}    
%     predicted_labels = [predicted_labels; {'change'}];
%     else
    'added'
    true_labels{file}    
    predicted_labels = [predicted_labels; {'added'}];
%     continue;
%     end
else  
    if norm_all < 110
%            if min(size(index_DD_far,1),size(index_DD1_far,1))/max(size(index_DD_far,1),size(index_DD1_far,1)) < 0.1 && norm_all < 10
%            'change'       
%             predicted_labels = [predicted_labels; {'change'}];
%            else
%         if (size(vertices_new_DD_far,1) >300 && size(vertices_new_DD_far,1) <600) && size(vertices_old_DD_far,1) <=10
%             'change3'   
%             predicted_labels = [predicted_labels; {'change'}];
%         else
   if (size(oldvertices_simoldvertices_sim,1) < 5) && (size(newvertices_simnewvertices_sim,1) > 300) %abs(Vall(file,1)) > 2.5
            'change'   
            predicted_labels = [predicted_labels; {'change'}];
           else
            'nochange'        
            predicted_labels = [predicted_labels; {'nochange'}];
            end
          true_labels{file}
    elseif norm_all >=110 && norm_all< 220
%         if norm(old_eigev-new_eigev,2) < 1e+13
%             'nochange'       
%              predicted_labels = [predicted_labels; {'nochange'}];
%         else
            'change'
            predicted_labels = [predicted_labels; {'change'}]; 
%         end
            true_labels{file} 
    elseif norm_all >=220 && sum_all > 0
%           if norm(old_eigev-new_eigev,2) < 1e+13
%             'nochange'       
%              predicted_labels = [predicted_labels; {'nochange'}];
%          else
        'removed'
        predicted_labels = [predicted_labels; {'removed'}];
%           end
         true_labels{file}
    else
%         if norm(old_eigev-new_eigev,2) < 1e+13
%             'nochange'       
%              predicted_labels = [predicted_labels; {'nochange'}];
%          else
        'added'
        predicted_labels = [predicted_labels; {'added'}];
%         end
        true_labels{file}
    end
end
% sum_percentage

% Compute the correlation coefficient between the vectors of bin counts
% aoo = corrcoef(n1, n2)
% corre(file,2) = aoo(1,2);
% corre(file,3) = max(edges1);
% corre(file,4) = max(edges2);

end
       clearvars -except places all_labels create_figures true_labels predicted_labels scenes scene labels point_of_interest oldvertices_listing_sort all_information newvertices_listing_sort path files_old files_new place median path_old path_new oldvertices_listing newvertices_listing lengthoflist file corre

end

% save(place,'corre')
end
writecell(true_labels, "true.txt")
writecell(places, "place.txt")
writecell(predicted_labels, "predicted.txt")

% save test
% load test
