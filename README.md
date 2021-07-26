# shrec21_changedetection

This work is done for the SHREC2021 change detection challenge, more info on the challenge is found here: https://kutao207.github.io/

The publication related to the outcome of this work is found here: https://www.sciencedirect.com/science/article/pii/S0097849321001369

## Dependencies
The project uses a combination of python, c++ and matlab.  
The python dependencies are essentially the same as the original ChangeDetectionDatasetViewer repo.  
The c++ dependencies include:  
Cmake version 3.15 or higher  
PCL  
Liblas  
For matlab, the 2020a version is used, although there will probably be no problems with newer/older versions.  

## Runing the program
The program is divided in two parts:
### Preparing and processing of the dataset
The preprocessing script "setup.sh" processes the pointclouds. This needs to be run once.  

### Classification
The run.sh script performs the classification and displays the confusion matrix.  
The confusion.sh script just displays the confusion matrix based on the results of run.sh without performing the classification. It essentially displays the results of the most recent run.

All of these scripts .sh must be edited to provide the correct path of the matlab executable program.  
Config.ini must also be edited in the same way as the ChangeDetectionDatasetViewer, but with the added "out_dir" field needed for both our scripts. This path is where our scripts will save and read any intermediate files.
