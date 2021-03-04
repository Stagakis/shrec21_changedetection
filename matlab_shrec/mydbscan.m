%
% Copyright (c) 2015, Yarpiz (www.yarpiz.com)
% All rights reserved. Please read the "license.txt" for license terms.
%
% Project Code: YPML110
% Project Title: Implementation of DBSCAN Clustering in MATLAB
% Publisher: Yarpiz (www.yarpiz.com)
% 
% Developer: S. Mostapha Kalami Heris (Member of Yarpiz Team)
% 
% Contact Info: sm.kalami@gmail.com, info@yarpiz.com
%
function IDX = DBSCANa(X,MinPts)
    C=0;
    
    n=size(X,1);
    IDX=zeros(n,1);
    
%     D=pdist2(X,X);
  
%%%%% Approach2 : I was looking for a more strict rules in order to seperate close but different 3D objects
anumNeighbours = 25;
if size(X,1) < anumNeighbours
anumNeighbours = size(X,1);
end
akdtreeobj1 = KDTreeSearcher(X);
[aAdjOfPoints1 D] = knnsearch(akdtreeobj1,X,'k',(anumNeighbours+1));
D1 = D(:,2:anumNeighbours); %We find the distance of the 5 closet points (e.g., 1-ring points)
epsilon = 4*(mean(D1,2)); %We estimate the mean distance and we set different epsilons per each point

%%%%% Approach1 : this is the one that i usually used
%    anumNeighbours = 100;
%    akdtreeobj1 = KDTreeSearcher(X);
%   [aAdjOfPoints1 D] = knnsearch(akdtreeobj1,X,'k',(anumNeighbours+1));   
%    D1 = D(:,2:6);
%    epsilon = 5*mean(mean(D1));

    
    visited=false(n,1);
     isnoise=false(n,1);
    
    for i=1:n
        if ~visited(i)
            visited(i)=true;
            
            Neighbors=RegionQuery(i);
            if numel(Neighbors)<MinPts
%                  X(i,:) is NOISE
                 isnoise(i)=true;
            else
                C=C+1;
                ExpandCluster(i,Neighbors,C);
            end
            
        end
    
    end
    
    function ExpandCluster(i,Neighbors,C)
        IDX(i)=C;
        
        k = 1;
        while true
            j = Neighbors(k);
            
            if ~visited(j)
                visited(j)=true;
                Neighbors2=RegionQuery(j);
                if numel(Neighbors2)>=MinPts
                    Neighbors=[Neighbors Neighbors2];   %#ok
                end
            end
            if IDX(j)==0
                IDX(j)=C;
            end
            
            k = k + 1;
            if k > numel(Neighbors)
                break;
            end
        end
    end
    
    function Neighbors=RegionQuery(i)
        Neighbors=find(D(i,:)<=epsilon(i)); %% We also change this in order to have different epsilon per each point since the density of a model might differ from area to area
        Neighbors=aAdjOfPoints1(i,Neighbors(:));
    end
end