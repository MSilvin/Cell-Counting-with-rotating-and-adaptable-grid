/* Marine SILVIN & Erwan Grandgirard
 * Imaging Centre IGBMC
 * silvinm@igbmc.fr & grandgie@igbmc.fr
 * May 2021
 * 
 * 
 * Open .lif serie, create ROI
 * 
 * Requirement:
 * 	- 
 * 	
 * How to use:
 *  - 
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


run("Set Measurements...", "integrated display redirect=None decimal=3");

// PROCESS LIF FILES
for (i = 0; i < list.length; i++) {
		processFile(list[i]);
}


/// Requires run("Bio-Formats Macro Extensions");
function processFile(fileToProcess){
	path=dir1+fileToProcess;
	Ext.setId(path);
	Ext.getCurrentFile(fileToProcess);
	Ext.getSeriesCount(seriesCount); // this gets the number of series
	print("Processing the file = " + fileToProcess);
	// see http://imagej.1557.x6.nabble.com/multiple-series-with-bioformats-importer-td5003491.html

	for (j=0; j<seriesCount; j++) {
    	Ext.setSeries(j);
        Ext.getSeriesName(seriesName);
		run("Bio-Formats Importer", "open=&path color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j+1); 
		fileNameWithoutExtension = File.nameWithoutExtension;
		name=File.getName(seriesName);
	
		setResult("Name of the image", j, name);
		//print(fileNameWithoutExtension);
		//MIP
		run("Z Project...", "projection=[Sum Slices]");

		roiManager("reset");	//reset ROIManager
		
		setTool("rotrect");		//create a rectangle that can be rotated
		makeRotatedRectangle(100, 100, 100, 100, 300);
		waitForUser("select your rectangle Area");

		run("Duplicate...", "title=ROI duplicate channels=1");
		Dialog.create("Number of sections?");
		Dialog.addNumber("numbers of sections", 10);
		Dialog.show();
		nb = Dialog.getNumber();
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

		run("Top Hat...", "radius=2");
		run("Gaussian Blur...", "sigma=1");
		run("Find Maxima...", "prominence=10 output=[Single Points]");
		
		for (i =0 ; i < roiManager("count") ; i++) {
		     roiManager("select", i);
		     nameROI= "ROI";
		     roiManager( "Rename", nameROI + i );
		}

		selectWindow("ROI Maxima");
		roiManager("Show All with labels");
		roiManager("Measure");
		close("ROI");
		close("ROI Maxima");
		//waitForUser("Gabuzomeuh");
		run("Close");
	}
	saveAs("Results", dir2+ "Results of "+ fileNameWithoutExtension +".csv");
	run("Clear Results");

  }

}