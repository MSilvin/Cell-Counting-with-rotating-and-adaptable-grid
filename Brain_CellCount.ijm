/* Marine SILVIN
 * Imaging Centre IGBMC
 * silvinm@igbmc.fr
 * May 2021
 * 
 * Requirement:
 * 	- 
 * 	
 * How to use:
 *  - 
 * 	
*/


/* ----------------------------------------------------------------------------------------------------------------*/
/*                Clean Everything to start
/* ----------------------------------------------------------------------------------------------------------------*/

print("\\Clear");
roiManager("reset");

if (isOpen("Results")) {      //Clean Results
	selectWindow("Results");
	run("Close");
} 

while (nImages > 0){          //Close Images
	close();
}


/* ----------------------------------------------------------------------------------------------------------------*/
/*                Convert lif to tif (boolean version so you can skip if not necessary)
/* ----------------------------------------------------------------------------------------------------------------*/

if (getBoolean("Do you need to convert .lif to .tiff?")) {     //if yes, do the conversion
    Z_PROJECT = "True";    // "True" to make a max projection; "False" to leave z stacks intact

	run("Bio-Formats Macro Extensions");
	
	dir1 = getDirectory("Choose folder with lif files ");
	list = getFileList(dir1);
	
	setBatchMode(true);
	
	// create folders for the tifs
	dir1parent = File.getParent(dir1);
	dir1name = File.getName(dir1);
	dir2 = dir1parent+File.separator+dir1name+"--Tiff_MIP";
	if (File.exists(dir2)==false) 
		{
		File.makeDirectory(dir2);   // new directory for tiff
	    }
	 
	for (i=0; i<list.length; i++) 
		{
	    showProgress(i+1, list.length);
	    print("processing ... "+i+1+"/"+list.length+"\n         "+list[i]);
	    path=dir1+list[i];
	
	    //how many series in this lif file?
	    Ext.setId(path);    // Initializes the given path (filename).
	    Ext.getSeriesCount(seriesCount);    // Gets the number of image series in the active dataset.
	    
	    for (j=1; j<=seriesCount; j++) 
	    	{
	        run("Bio-Formats", "open=path autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j);
	        name=File.nameWithoutExtension;
	
		    //retrieve name of the series from metadata
	        text=getMetadata("Info");
	        n1=indexOf(text," Name = ")+8;    // the Line in the Metadata reads "Series 0 Name = ". Complete line cannot be taken, because
	                                          // The number changes of course. But at least in the current version of Metadata this line is the 
	                                          // only occurence of " Name ="
	        n2=indexOf(text,"SizeC = ");      // this is the next line in the Metadata
	        seriesname=substring(text, n1, n2-2);
			seriesname=replace(seriesname,"/","-");
			rename(seriesname);
			
		    // project and save
	    	getDimensions(width, height, channels, slices, frames);    // check if is a stack of any kind
	    	if (slices>1)    // it is a z stack
	    		{
	        	if (Z_PROJECT == "True")
	        		{
	        		run("Z Project...", "projection=[Sum Slices]");
	        		selectWindow("SUM_"+seriesname);
	        		}
		        saveAs("Tiff", dir2+File.separator+name+"_"+seriesname+"_MIP_"+j+".tif");    
	    		}
	        else
	        	{
		        saveAs("Tiff", dir2+File.separator+name+"_"+seriesname+"_MIP_"+j+".tif");
	        	}    
	        run("Close All");
	        run("Collect Garbage");
			setBatchMode(false);
			}
		}
		showMessage("Conversion finished. Let's segment everything! :D");
	    	
}else {		//if you don't need to convert
        showMessage("Let's go to segmentation then! :)");
        dir2 = getDirectory("Choose folder with .tif files");
	}




/* ----------------------------------------------------------------------------------------------------------------*/
/*                Create ROI + select segmentation of the ROI rectangle
/* ----------------------------------------------------------------------------------------------------------------*/
{
roiManager("reset");   //Clean everything
run("Clear Results");

list = getFileList(dir2);

for (i=0; i<list.length; i++)                  //afficher la progression
	{
    showProgress(i+1, list.length);
    print("processing ... "+i+1+"/"+list.length+"\n         "+list[i]);
    
    path=dir2+list[i];
	FileName = File.getName(path);								/* recup nom complet de l'image */
	SequenceName = substring(FileName, 0, lastIndexOf(FileName, ".tif")); 
	open(path + File.separator + SequenceName + ".tif");

	
	test=1;
	i=1;	
	while (test==1)
	{
		i=i+1;
		test=File.exists(dir2 + File.separator + SequenceName + ".tif");
		if (test ==1) open(path + File.separator + SequenceName + ".tif");		//load toutes les images
			} 
	setBatchMode("exit and display");

	setTool("line");
	waitForUser("Draw ROI line by hand, then click on OK" );  
	listRoi= roiManager("count");
	for(j = 0; j != listRoi; j++){
		roiManager("select", j);
		roiManager("Rename", "ROI_" + j+1);
			}
	}


