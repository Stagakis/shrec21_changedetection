import seaborn as sns
import csv
import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
import pandas as pd

added_data = genfromtxt("added.csv", delimiter="\n")
print("Added data             size: ", added_data.shape[0], " mean", np.mean(added_data), "std", np.std(added_data))

removed_data = genfromtxt("removed.csv", delimiter="\n")
print("Removed_data data      size: ", removed_data.shape[0], " mean", np.mean(removed_data), "std", np.std(removed_data))

change_data = genfromtxt("change.csv", delimiter="\n")
print("Change_data data       size: ", change_data.shape[0], " mean", np.mean(change_data), "std", np.std(change_data))

color_change_data = genfromtxt("color_change.csv", delimiter="\n")
print("Color_change_data data size: ", color_change_data.shape[0], " mean", np.mean(color_change_data), "std", np.std(color_change_data), "max", np.max(color_change_data))

nochange_data = genfromtxt("nochange.csv", delimiter="\n")
print("Nochange_data data     size: ", nochange_data.shape[0], " mean", np.mean(nochange_data), "std", np.std(nochange_data), "max", np.max(nochange_data))

x_axis = ["Added", "Removed", "Changed", "ColorChanged", "NoChange"]

added_df = pd.DataFrame(added_data, columns = ["Added"])
removed_df = pd.DataFrame(removed_data, columns = ["Removed"])
changed_df = pd.DataFrame(change_data, columns = ["Changed"])
color_change_df = pd.DataFrame(color_change_data, columns = ["ColorChange"])
no_change_df = pd.DataFrame(nochange_data, columns = ["NoChange"])

all_dfs = [added_df, removed_df, changed_df, color_change_df, no_change_df ]

final_data_dataframe = pd.concat(all_dfs,  ignore_index=True, axis=1)
final_data_dataframe.columns = x_axis

max_dist = final_data_dataframe.max().max()
print(max_dist)
step = 30
bin_ranges = [int(max_dist)/step * i for i in range(step+1)]
#, ylim=(0, 22000)
ax = sns.boxplot(data=final_data_dataframe).set(xlabel="Label Names", ylim=(0, 500), ylabel="HistogramDistance")

for i in range((len(x_axis))):
    fig = sns.displot(all_dfs[i]).set(title=x_axis[i], ylim=(0, 50))
plt.show()