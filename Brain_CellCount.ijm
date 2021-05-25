/* Marine SILVIN & Erwan GRANDGIRARD
 * Imaging Centre IGBMC
 * silvinm@igbmc.fr & grandgie@igbmc.fr
 * May 2021
 * 
 * Cell counting on brain sections
 * Data: .lif files
 * Dimension: 2 channels, Z-stack
 * Label: DAPI and GFP
 * 
 * Requirement:
 * 	- Fiji (ImageJ) version 1.53i or more recent
 * 	- .lif files
 * 	- source folder and output folder
 * 	
 * How to use:
 *  - 1rst method: 
 *  	Drag&Drop in Fiji
 *  	Click on "run"
 *  - 2nd method:
 *  	Copy paste the macro file in 	C:\...\Fiji.app\macros
 *  	In Fiji, click on Plugins > Macros > Install...
 *  	Restart Fiji
 *  	The macro is now in Plugins > Macros > CellCount_Brain
 * 	
*/


macro "CellCount_Brain" {

// INITIALISE MACRO
print("\\Clear");
               
run("Bio-Formats Macro Extensions");	//enable macro functions for Bio-formats Plugin
print("Select folder with your Raw Data")
dir1 = getDirectory("Choose a Directory");
print("Select the folder for your results")
dir2 = getDirectory("Choose a Results Directory");
list = getFileList(dir1);
setBatchMode(false);


//Choose number of divisions in the global ROI area
Dialog.create("Number of sections?");
Dialog.addNumber("numbers of sections", 10);
Dialog.show();
sections = Dialog.getNumber();

//Parameters given by "Measure" - here: "Integrated Density"
run("Set Measurements...", "integrated display redirect=None decimal=3");

// PROCESS LIF FILES
for (i = 0; i < list.length; i++) {
		sections = sections;
		processFile(list[i]);
		saveOverview(list[i]);
}



/// Requires run("Bio-Formats Macro Extensions");
function processFile(fileToProcess){
	path=dir1+fileToProcess;
	Ext.setId(path);
	Ext.getCurrentFile(fileToProcess);
	Ext.getSeriesCount(seriesCount); // this gets the number of series
	print("Processing the file = " + fileToProcess);

	for (j=0; j<seriesCount; j++) {
    	Ext.setSeries(j);
        Ext.getSeriesName(seriesName);
		run("Bio-Formats Importer", "open=&path color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j+1); 
		fileNameWithoutExtension = File.nameWithoutExtension;
		name=File.getName(seriesName);


		//Max Intensity Projection
		run("Z Project...", "projection=[Sum Slices]");
		
		roiManager("reset");	//reset ROIManager
		
		setTool("rotrect");		//create a rectangle that can be rotated
		makeRotatedRectangle(100, 100, 100, 100, 300);
		waitForUser("select your rectangle Area");

		//saving of the rectangle draw on the source image
		roiManager("Add");
		roiManager("Save", dir2+ name + "-ROI.zip");
		roiManager("reset");

		//duplicate with only the channel of interest 
		run("Duplicate...", "title=ROI duplicate channels=1");
		//divide the large ROI in sub-ROI
		nb = sections;
		W = getWidth();
		H = getHeight();
		bounding= (W/nb);
		bounding = round(bounding);
		selectWindow("ROI");
		for (i = 0;  i< nb; i++) {
		               makeRectangle(i*bounding, 0 , bounding, H);
		               roiManager("add");
		}
		roiManager("show all");

		//Image treatment (Top Hat, Gaussian blur, Find Maxima)
		//to better discriminate all the cells
		run("Top Hat...", "radius=2");
		run("Gaussian Blur...", "sigma=1");
		run("Find Maxima...", "prominence=10 output=[Single Points]");

		//Rename ROI to numerotate it
		for (z = 0 ; z < roiManager("count") ; z++) {
		     roiManager("select", z);
		     nameROI= "ROI";
		     roiManager( "Rename", name + "-" + nameROI + z );
				}

		//Measure Integrated Density on maxima image
		selectWindow("ROI Maxima");
		roiManager("Show All with labels");
		roiManager("Measure");
		close("ROI");
		close("ROI Maxima");

		while (nImages()>0) {
        	selectImage(nImages());  
        	run("Close");
		}

		
	}
			


	//suppress "MaximaROI:" at the beginning of labels
	for (i=0; i<nResults; i++) {
		oldLabel = getResultLabel(i);
		delimiter = indexOf(oldLabel, ":");
		newLabel = substring(oldLabel, delimiter+1);
		setResult("Label", i, newLabel);
  		}

  	//transform result of "Measure" in total count of cells
  	//Because “RawIntDen” is the sum of the values of the pixels in the image or selection
	IJ.renameResults("Results"); // otherwise below does not work...
	for (row=0; row<nResults; row++) {
		counting = getResult("RawIntDen", row) / 255;
	    setResult("Cell Count", row, counting);
	}

	//suppress value that we don't need
	Table.deleteColumn("IntDen");
	Table.deleteColumn("RawIntDen");
	updateResults();

  	//saving in a table format that can be open in Excel
	saveAs("Results", dir2+ "Results of "+ fileNameWithoutExtension +".csv");
	run("Clear Results");
	
  }
 
close("*");
close("Results");
print("\\Clear");


//saving the crop composite image with ROI on it
function saveOverview(fileToProcess){
	path=dir1+fileToProcess;
	Ext.setId(path);
	Ext.getCurrentFile(fileToProcess);
	Ext.getSeriesCount(seriesCount); // this gets the number of series
	print("Processing the file = " + fileToProcess);
	roiManager("reset");
	for (j=0; j<seriesCount; j++) {
    	Ext.setSeries(j);
        Ext.getSeriesName(seriesName);
		run("Bio-Formats Importer", "open=&path color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j+1); 
		fileNameWithoutExtension = File.nameWithoutExtension;
		name=File.getName(seriesName);

		run("Z Project...", "projection=[Sum Slices]");
		run("Make Composite");		//create a composite image (twwo channels merged)
		close("\\Others");		//close the source image
		roiManager("Open", dir2+ name + "-ROI.zip");		//open the ROI set corresponding
		roiManager("Select", 0);
		
		run("Duplicate...", "title=Overview duplicate");		//recreate the crop
		nb = sections;
		W = getWidth();
		H = getHeight();
		bounding= (W/nb);
		bounding = round(bounding);
		selectWindow("Overview");
		for (i = 0;  i< nb; i++) {
		               makeRectangle(i*bounding, 0 , bounding, H);
		               roiManager("add");
		}
		//suppress the global ROI
		roiManager("Select", 0);
		roiManager("delete");
		roiManager("show all");
		//Create an overlay and save it
		run("From ROI Manager");
		saveAs("PNG", dir2 + name + "-OverviewROI.png");
		roiManager("reset");

	}


showMessage("--Process finished--");
}