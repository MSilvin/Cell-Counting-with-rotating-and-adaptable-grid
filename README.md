[![CC BY 4.0][cc-by-shield]][cc-by]
[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg

# Cell Counting with rotating and adaptable grid
 Macro created for counting GFP-stained cells in brain. Acquisition from a confocal microscope.
 
 
 ## Goal of this macro
 The goal of this macro is to count cells on a brain sections on which we put a grid with division.
 Number of divisions can be adaptated in function of how many the user wants.
 
 ## Outputs
 At the end, we obtain a .csv file with counting of each ROI from each .tif files presents in the .lif.
 Also, it give a .zip file containing the ROI of the global region we want to analyse.
 And we obtain a PNG image of the crop with all the labelled ROI on it to see which part of the brain section corresponds to each ROI.
 
 
 ## Requirement
- Fiji (ImageJ) version 1.53i or more recent
- .lif files
- source folder and output folder
	
 
 
 ## Installation
- 1rst method: 
		Drag&Drop in Fiji
		Click on "run"
- 2nd method:
		Copy paste the macro file in 	C:\...\Fiji.app\macros
		In Fiji, click on Plugins > Macros > Install...
		Restart Fiji
		The macro is now in Plugins > Macros > CellCount_Brain
