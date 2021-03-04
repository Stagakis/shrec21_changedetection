import seaborn as sns
import csv
import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
import pandas as pd
import colorsys

def plotRGBHistogram(pixels, bin_number, title):
    plt.figure()
    y_lim = [0, 0.03]

    fig = plt.gcf()
    fig.canvas.set_window_title(title)
    fig.set_size_inches(8, 13)

    plt.subplot(3, 1, 1)
    plt.hist(x=pixels.iloc[:,0], bins=bin_number, color=[1,0,0], density=True)
    plt.title(pixels.columns[0])

    axes = plt.gca()
    axes.set_ylim(y_lim)

    plt.subplot(3, 1, 2)
    plt.hist(x=pixels.iloc[:,1], bins=bin_number, color=[0,1,0], density=True)
    plt.title(pixels.columns[1])

    axes = plt.gca()
    axes.set_ylim(y_lim)

    plt.subplot(3, 1, 3)
    plt.hist(x=pixels.iloc[:,2], bins=bin_number, color=[0,0,1], density=True)
    plt.title(pixels.columns[2])

    axes = plt.gca()
    axes.set_ylim(y_lim)

def plotBothHistograms(pixels_2016, pixels_2020, bin_number):
    bin_width = 255/bin_number
    fig, axs = plt.subplots(3, 2, sharex=False, sharey='row', gridspec_kw={'hspace': 0.1, 'wspace': 0})
    fig.suptitle('2016 vs 2020')

    fig.canvas.set_window_title("HistogramComparison")
    fig.set_size_inches(16, 13)

    #RED
    (n, bins, patches) = axs[0,0].hist(range = (0,255), x=pixels_2016.iloc[:,0], edgecolor='black',bins=bin_number, color=[1,0,0], density=False)
    print("2016", n)
    (n, bins, patches) = axs[0,1].hist(range = (0,255),x=pixels_2020.iloc[:,0], edgecolor='black',bins=bin_number, color=[1,0,0], density=False)
    print("2020", n)

    #Green
    axs[1,0].hist(range = (0,255), x=pixels_2016.iloc[:,1], edgecolor='black',bins=bin_number, color=[0,1,0], density=True)
    axs[1,1].hist(range = (0,255), x=pixels_2020.iloc[:,1], edgecolor='black',bins=bin_number, color=[0,1,0], density=True)

    #Blue
    axs[2,0].hist(range = (0,255), x=pixels_2016.iloc[:,2], edgecolor='black',bins=bin_number, color=[0,0,1], density=True)
    axs[2,1].hist(range = (0,255), x=pixels_2020.iloc[:,2], edgecolor='black',bins=bin_number, color=[0,0,1], density=True)

def convertDfRGB2HSV(in_dataframe):
    return pd.DataFrame([rgb2hsv(in_dataframe.iloc[i,0], in_dataframe.iloc[i,1], in_dataframe.iloc[i,2]) for i in range(in_dataframe.shape[0])])

def rgb2hsv(r, g, b):
    hsv = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
    return [int(hsv[0]*255), int(hsv[1]*255), int(hsv[2]*255)]

bin_width = 5
bin_number = int(255/bin_width)

scene = "67_5D4L1TX7"
index = 8

pcl_2016 = pd.DataFrame(genfromtxt("csv/2016_" + scene + "_" + str(index) + ".csv" , delimiter=","))
pcl_2020 = pd.DataFrame(genfromtxt("csv/2020_" + scene + "_" + str(index) + ".csv" , delimiter=","))

#print(pcl_2016.shape[0])
#print(pcl_2020.shape[0])

pcl_2016.columns= ["Red", "Green", "Blue"]
pcl_2020.columns= ["Red", "Green", "Blue"]


manual_histogram = [0 for i in range(bin_number)]
for i in range(pcl_2020.shape[0]):
    red = pcl_2020.iloc[i,0]
    manual_histogram[ min(int(red/bin_width), bin_number - 1)] = manual_histogram[ min(int(red/bin_width), bin_number - 1)] + 1
print("Manual:", manual_histogram)
#plotRGBHistogram(pcl_2016, bin_number, title="2016")
#plotRGBHistogram(pcl_2020, bin_number, title="2020")

#convertDfRGB2HSV(pcl_2016)
#convertDfRGB2HSV(pcl_2020)

plotBothHistograms(pcl_2016, pcl_2020, bin_number)

plt.show()
