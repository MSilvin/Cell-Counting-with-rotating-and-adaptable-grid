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

		
		//print(fileNameWithoutExtension);
		//MIP
		run("Z Project...", "projection=[Sum Slices]");
		
		roiManager("reset");	//reset ROIManager
		
		setTool("rotrect");		//create a rectangle that can be rotated
		makeRotatedRectangle(100, 100, 100, 100, 300);
		waitForUser("select your rectangle Area");

		roiManager("Add");
		roiManager("Save", dir2+ name + "-ROI.zip");
		roiManager("reset");
		

		run("Duplicate...", "title=ROI duplicate channels=1");
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

		run("Top Hat...", "radius=2");
		run("Gaussian Blur...", "sigma=1");
		run("Find Maxima...", "prominence=10 output=[Single Points]");

		for (z = 0 ; z < roiManager("count") ; z++) {
		     roiManager("select", z);
		     nameROI= "ROI";
		     roiManager( "Rename", name + "-" + nameROI + z );
				}

	
		selectWindow("ROI Maxima");
		roiManager("Show All with labels");
		roiManager("Measure");
		close("ROI");
		close("ROI Maxima");
		//waitForUser("Gabuzomeuh");
		//run("Close");


	}
	
	for (i=0; i<nResults; i++) {
		oldLabel = getResultLabel(i);
		delimiter = indexOf(oldLabel, ":");
		newLabel = substring(oldLabel, delimiter+1);
		setResult("Label", i, newLabel);
  		}

  	
	IJ.renameResults("Results"); // otherwise below does not work...
	for (row=0; row<nResults; row++) {
		counting = getResult("RawIntDen", row) / 255;
	    setResult("Cell Count", row, counting);
	}
	Table.deleteColumn("IntDen");
	Table.deleteColumn("RawIntDen");
	updateResults();
  	
	saveAs("Results", dir2+ "Results of "+ fileNameWithoutExtension +".csv");
	run("Clear Results");
	
  }
 
close("*");
close("Results");
print("\\Clear");


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
		run("Make Composite");
		close("\\Others");
		roiManager("Open", dir2+ name + "-ROI.zip");
		roiManager("Select", 0);
		
		run("Duplicate...", "title=Overview duplicate");
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
		roiManager("Select", 0);
		roiManager("delete");
		roiManager("show all");
		//waitForUser("Overlay??");
		run("From ROI Manager");
		saveAs("PNG", dir2 + name + "-OverviewROI.png");
		roiManager("reset");
		//waitForUser;
	}


showMessage("--Process finished--");
}