import os
import pandas as pd
import numpy as np
import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
from datetime import datetime
import sys
import configparser
from shutil import copy2
from utils import (
load_las,
compare_clouds,
extract_area,
random_subsample,
compare_clouds,
view_cloud_plotly,
save_EVERYTHING,
dummy
)
config = configparser.ConfigParser()
config.read('config.ini')
config_dict = config['2016-2020']
dir_1 = config_dict['dir_1']
dir_2 = config_dict['dir_2']
out_dir = config_dict['out_dir']
class_labels = ['nochange','removed',"added",'change',"color_change","unfit"]
classified_dir = config_dict['classified_dir']

point_list_dir = classified_dir
clearance = 3
point_size = 1.5

classified_point_list_files = [os.path.join(classified_dir,f) for f in os.listdir(classified_dir) if os.path.isfile(os.path.join(classified_dir, f))]


# File Directory creation and csv copyting ##########################################################
files_dir_1_filenameonly = [f for f in os.listdir(dir_1) if os.path.isfile(os.path.join(dir_1, f)) and f.split(".")[-1]=='las']
#scene_names = [filename[:-4] for filename in files_dir_1_filenameonly]
scene_names = [classified_point_list_files[i].split("/")[-1][:-4].split("_")[0] + "_" + classified_point_list_files[i].split("/")[-1][:-4].split("_")[1] for i in range(len(classified_point_list_files))]
#print([classified_point_list_files[i].split("/")[-1][:-4] for i in range(len(classified_point_list_files))])
#print(scene_names)
for i in range(len(scene_names)):
    os.makedirs(os.path.join(out_dir, scene_names[i]), exist_ok=True)
    os.makedirs(os.path.join(out_dir, scene_names[i], "2016"), exist_ok=True)
    os.makedirs(os.path.join(out_dir, scene_names[i], "2020"), exist_ok=True)
    #print("Creating Folder: ", os.path.join(out_dir, scene_names[i]))
    #print("Copying file: ", classified_point_list_files[i])
    #print("To: ", os.path.join(out_dir, scene_names[i]))
    #print("=======================================================")
    copy2(classified_point_list_files[i], os.path.join(out_dir, scene_names[i]) + "/")
######################################################################################################
scene_numbers = [int(os.path.basename(x).split('_')[0]) for x in classified_point_list_files]
sample_size = 100000


classified_point_list_dfs = {scene_num:pd.read_csv(path) for scene_num,path in zip(scene_numbers,classified_point_list_files)}

files_dir_1 = [os.path.join(dir_1,f) for f in os.listdir(dir_1) if os.path.isfile(os.path.join(dir_1, f)) and f.split(".")[-1]=='las']
files_dir_2 = [os.path.join(dir_2,f) for f in os.listdir(dir_2) if os.path.isfile(os.path.join(dir_2, f))and f.split(".")[-1]=='las']


files_dir_1 = {int(os.path.basename(x).split("_")[0]):x for x in files_dir_1}
files_dir_2 = {int(os.path.basename(x).split("_")[0]):x for x in files_dir_2}

classified_point_list_files = {int(os.path.basename(x).split("_")[0]):x for x in classified_point_list_files}


# Actual Saving #############################################################################
for i in scene_numbers:
    print("Scene name: ", classified_point_list_files[i].split("/")[-1])
    save_EVERYTHING(point_list_df=classified_point_list_dfs[i], file_1=files_dir_1[i], file_2=files_dir_2[i], clearance=clearance, out_dir=out_dir)
    print("=============================================================================================================")
#############################################################################################





