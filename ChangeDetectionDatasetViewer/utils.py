import numpy as np
import time
from laspy.file import File
import laspy
import laspy.header
import pandas as pd
import plotly.graph_objects as go
import os


def load_las(path, also_return_lasfile=False):
    input_las = File(path, mode='r')
    point_records = input_las.points.copy()
    las_scaleX = input_las.header.scale[0]
    las_offsetX = input_las.header.offset[0]
    las_scaleY = input_las.header.scale[1]
    las_offsetY = input_las.header.offset[1]
    las_scaleZ = input_las.header.scale[2]
    las_offsetZ = input_las.header.offset[2]

    # calculating coordinates
    p_X = np.array((point_records['point']['X'] * las_scaleX) + las_offsetX)
    p_Y = np.array((point_records['point']['Y'] * las_scaleY) + las_offsetY)
    p_Z = np.array((point_records['point']['Z'] * las_scaleZ) + las_offsetZ)

    points = np.vstack((p_X,p_Y,p_Z,input_las.red,input_las.green,input_las.blue)).T

    if(also_return_lasfile):
        return points, input_las
    else:
        return points

def my_write_las(filename, points, header):

    outfile = laspy.file.File(filename, mode="w", header=header)
    outfile.points = points
    outfile.close()

def view_cloud_plotly(points,rgb=None,fig=None,point_size=2,show=True,axes=False,show_scale=False,colorscale=None):
    if not isinstance(rgb,np.ndarray):
        rgb = np.zeros_like(points)
    else:
        rgb = np.rint(np.divide(rgb,rgb.max(axis=0))*255).astype(np.uint8)
    if fig==None:
        fig = go.Figure()
    fig.add_scatter3d(
        x=points[:,0], 
        y=points[:,1], 
        z=points[:,2], 
        marker=dict(
        size=point_size,
        color=rgb,  
        colorscale=colorscale,
        showscale=show_scale,
        opacity=1
    ), 
        
        opacity=1, 
        mode='markers',
        
    )


    if not axes:
            fig.update_layout(
            scene=dict(
            xaxis=dict(showticklabels=False,visible= False),
            yaxis=dict(showticklabels=False,visible= False),
            zaxis=dict(showticklabels=False, visible= False),
            )
)

    if show:
        fig.show()
    return fig


def write_pointcloud(filename, data, index):
    xyz = data[:, :3]
    rgb = data[:, 3:]
    xmax, ymax, zmax = rgb.max(axis=0)
    values = [xmax, ymax, zmax]
    rgb = rgb / values
    rgb = rgb * 255

    xyz.astype('float32').tofile("las_files/las_test_" + str(index) + '_' + str(filename) + '.bin')
    scan = np.fromfile("las_files/las_test_" + str(index) + '_' + str(filename) + '.bin', dtype=np.float32)
    rgb.astype('float32').tofile("las_files/las_test_" + str(index) + '_col_' + str(filename) + '.bin')
    scan = np.fromfile("las_files/las_test_" + str(index) + '_col_' + str(filename) + '.bin', dtype=np.float32)
    



def compare_clouds(extraction_1,extraction_2,class_labels):
    rgb1 =     np.rint(np.divide(extraction_1[:,3:],extraction_1[:,3:].max(axis=0))*255).astype(np.uint8)
    rgb2 =     np.rint(np.divide(extraction_2[:,3:],extraction_2[:,3:].max(axis=0))*255).astype(np.uint8)
    
    # class_to_return = None
    points1 = extraction_1[:,:3]
    
    points2 = extraction_2[:,:3]
    points2[:,0]+=10
    axes = plt.axes(projection='3d')
    axes.scatter(points1[:,0], points1[:,1], points1[:,2], c = rgb1/255, s=0.1)
    #Add time labels avove
    axes.text(x=points1[:,0].mean(),y=points1[:,1].mean(),z=points1[:,2].max()+0.1,s="t1")

    axes.scatter(points2[:,0], points2[:,1], points2[:,2], c = rgb2/255, s=0.1)
    axes.text(x=points2[:,0].mean(),y=points2[:,1].mean(),z=points2[:,2].max()+0.1,s="t2")
    plt.axis('off')
    
    props = ItemProperties(labelcolor='black', bgcolor='yellow',
                        fontsize=10, alpha=0.2)
    hoverprops = ItemProperties(labelcolor='white', bgcolor='blue',
                                fontsize=10, alpha=0.2)

    menuitems = []

    def on_select(item):
        global class_to_return
        class_to_return = item.labelstr
        plt.close()
        print('you selected %s' % item.labelstr)
    for label in class_labels:
      
        item = MenuItem(plt.gcf(), label, props=props, hoverprops=hoverprops,
                        on_select=on_select)
        menuitems.append(item)

    menu = Menu(plt.gcf(), menuitems)
    plt.show()
    

    return class_to_return

def extract_area_mask(full_cloud,center,clearance,shape= 'cylinder'):
    if shape == 'square':
        x_mask = ((center[0]+clearance)>full_cloud[:,0]) &   (full_cloud[:,0] >(center[0]-clearance))
        y_mask = ((center[1]+clearance)>full_cloud[:,1]) &   (full_cloud[:,1] >(center[1]-clearance))
        mask = x_mask & y_mask
    elif shape == 'cylinder':
        mask = np.linalg.norm(full_cloud[:,:2]-center,axis=1) <  clearance
    return mask

def extract_area(full_cloud,center,clearance,shape= 'cylinder'):
    if shape == 'square':
        x_mask = ((center[0]+clearance)>full_cloud[:,0]) &   (full_cloud[:,0] >(center[0]-clearance))
        y_mask = ((center[1]+clearance)>full_cloud[:,1]) &   (full_cloud[:,1] >(center[1]-clearance))
        mask = x_mask & y_mask
    elif shape == 'cylinder':
        mask = np.linalg.norm(full_cloud[:,:2]-center,axis=1) <  clearance
    return full_cloud[mask]



def random_subsample(points,n_samples):
    if points.shape[0]==0:
        print('No points found at this center replacing with dummy')
        points = np.zeros((1,points.shape[1]))
    #No point sampling if already 
    if n_samples < points.shape[0]:
        random_indices = np.random.choice(points.shape[0],n_samples, replace=False)
        points = points[random_indices,:]
    return points




def save_EVERYTHING(point_list_df, file_1, file_2, clearance, out_dir):
    count = 0
    scene_name = file_1[:-4].split("/")[-1]
    output_scene_filename = os.path.join(out_dir,scene_name)
    print("File1: " + file_1.split("/")[-1])
    print("File2: " + file_2.split("/")[-1])
    print("Saving to folder",    output_scene_filename.split("/")[-1])
    try:
        points1, las_file1 = load_las(file_1, also_return_lasfile=True)
        points2, las_file2 = load_las(file_2, also_return_lasfile=True)
    except:
        print("Unable to load files!!!")
        return
    for index, row in point_list_df.iterrows():
        center = np.array([row['x'], row['y']])
        mask1 = extract_area_mask(points1, center, clearance, 'cylinder')
        mask2 = extract_area_mask(points2, center, clearance, 'cylinder')
        try:
            points_kept1 = las_file1.points[mask1]
            points_kept2 = las_file2.points[mask2]
        except:
            print("The try/except triggered")
            continue
        if(points1[mask1].shape[0] == 0 or points2[mask2].shape[0] == 0):
            print("Zero points remained after the area extraction, index=" + str(index))
            continue
        out_filename = os.path.join(output_scene_filename, "2016", scene_name + "_" + str(index) + ".las")
        my_write_las(out_filename, points_kept1, las_file1.header)
        out_filename = os.path.join(output_scene_filename, "2020", scene_name + "_" + str(index) + ".las")
        my_write_las(out_filename, points_kept2, las_file2.header)
        count = count + 1
    print("Total Saved: ", count)
    return

def dummy(test):
    print(test)


