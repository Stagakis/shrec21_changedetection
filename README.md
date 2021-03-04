# shrec21_changedetection

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

The preprocessing script "setup.sh" processes the pointclouds. This needs to be run once.
The run.sh script performs the classification and displayes the confusion matrix.

Both of these scripts must be edited to provide the correct path of the matlab executable program.
Config.ini must also be edited in the same way as the ChangeDetectionDatasetViewer, but with the added "out_dir" field needed for both our scripts. This path is where our scripts will save and read any intermediate files.
