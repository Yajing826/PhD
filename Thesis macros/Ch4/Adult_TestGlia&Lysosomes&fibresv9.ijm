/* Macro written by Dale Moulding UCL GOS Light Microscopy Facility, November 2018
 *  Opens a 3 channel stack
 *  Identifies Glia in channel 1
 *  Identifies lysosomes in channel 2
 *  Identifies fibers in channel 3
 *  Identifies overlaps bewteen channels then using the 3D ROI manager and measures 
 *  microglia cell number and volumes, 
 *  lysosomes number per cell and their volumes
 *  fibers coincident with lysosomes. The fiber volume.
*/

	dir1 = getDirectory("Choose Source Directory "); //select an input folder
 	dir2 = getDirectory("Choose a folder to save to"); //select an output folder. 
 	list = getFileList(dir1); //make a list of the filenames
 	setBatchMode(true); //turn on batch mode to run in the background - RAM keeps filling up!

 	
 //set 3D manager to only measure volumes & grey value
 	run("3D Manager Options", "volume integrated_density mean_grey_value distance_between_centers=10 distance_max_contact=1.80 drawing=Contour");

// open folders, set up the loop.


for (k=0; k<list.length; k++) { 
 	showProgress(k+1, list.length);
 	filename = dir1 + list[k];
	open(filename);	
	//setMinAndMax(0, 65535); //set bit depth for homogeneous brightness in deconv images
	Imagename = File.nameWithoutExtension;
	ImageSet = substring(Imagename, 0, lengthOf(Imagename)); // record the file name for saving later
	
	//remove first 2 and last 2 slices to correct for artefacts
	end = nSlices-2;
	run("Duplicate...", "duplicate slices=3-"+end+"");
	
	rename ("Orig");
	selectWindow("Orig");
	run("Duplicate...", "title=Microglia duplicate channels=1"); //duplicate images to merge at the end
	resetMinAndMax();
	selectWindow("Orig");
	run("Duplicate...", "title=Lyso duplicate channels=2"); //duplicate images to merge at the end
	resetMinAndMax();
	selectWindow("Orig");
	run("Duplicate...", "title=Fibers duplicate channels=3"); //duplicate images to merge at the end
	resetMinAndMax();
		
// Identify Glial cells
	selectWindow("Orig");
	run("Duplicate...", "title=MicrogliaOrig duplicate channels=1");
	run("Subtract Background...", "rolling=20 stack");
	run("Median...", "radius=1.5 stack");
	//run("Median 3D...", "x=1 y=1 z=1");
	setAutoThreshold("Triangle dark stack");
	//setOption("BlackBackground", false);
	run("Convert to Mask", "method=Triangle background=Dark");
	rename("GliaMaskFiltered");


// Identify lysosomes
	selectWindow("Orig");
	run("Duplicate...", "title=LysoOrig duplicate channels=2");
	//run("Remove Outliers...", "radius=2 threshold=20 which=Bright stack");
	run("Subtract Background...", "rolling=10 stack");
	run("Median...", "radius=1 stack");
	setAutoThreshold("RenyiEntropy dark stack");
	//setOption("BlackBackground", false);
	run("Convert to Mask", "method=RenyiEntropy background=Dark");	
	rename("LysoMask");

// Identify fibers
	selectWindow("Orig");
	run("Duplicate...", "title=FibersOrig duplicate channels=3");
	run("Subtract Background...", "rolling=25 stack");
	run("Gaussian Blur 3D...", "x=0.5 y=0.5 z=0.5");
	setAutoThreshold("Otsu dark stack");//threshold for the histogram of the whole stack
	run("Convert to Mask", "method=Otsu background=Dark");
	rename("FibersMask");

// Identify lysosomes inside glia
	imageCalculator("AND create stack", "LysoMask", "GliaMaskFiltered");
	rename("LysoMorphRecon"); // Identified fibres inside lysosomes "FibersInLyso"


// Identify fibres inside the lysosomes
	imageCalculator("AND create stack", "FibersMask","LysoMorphRecon");
	rename("FibersInLyso"); // Identified fibres inside lysosomes "FibersInLyso"


//measure IBA1 & CD68 integrated density inside glia
	selectWindow("Orig");
	run("Duplicate...", "title=GliaOrig duplicate channels=1");
	selectWindow("Orig");
	run("Duplicate...", "title=CD68Orig duplicate channels=2");	

	run("3D Manager");
	selectWindow("GliaMaskFiltered"); //use glia mask mask as template
	Ext.Manager3D_AddImage();
	Ext.Manager3D_Select(0);
	Ext.Manager3D_Rename("gliaroi");

	selectWindow("GliaOrig");
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q", dir2+Imagename+"-Iba1_IDResults3D.txt"); // save the results
	Ext.Manager3D_CloseResult("Q");

	selectWindow("CD68Orig");
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q", dir2+Imagename+"-CD68_IDResults3D.txt"); // save the results
	Ext.Manager3D_CloseResult("Q");
	run("Collect Garbage");
	
	//mask + image (AND function) -> sum projection --> output & add to final output
	//for Neurons
	selectWindow("GliaMaskFiltered");
	run("Duplicate...", "duplicate");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "GliaOrig","GliaMaskFiltered-1");
	rename("Iba1");

	selectWindow("GliaMaskFiltered");
	run("Duplicate...", "duplicate");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "CD68Orig","GliaMaskFiltered-1");
	rename("CD68");

	run("Merge Channels...", "c1=[Iba1] c2=[CD68] create");
		Stack.setChannel(1);          
		run("Green");
		Stack.setChannel(2);
		run("Red");
	saveAs("tiff", dir2+"GliaIntDens-"+ImageSet);


//Run the 3Dmanager to 3D segement the Glia & save the ROIs
		selectWindow("GliaMaskFiltered");
		run("3D Manager");
		//Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		//Ext.Manager3D_SelectAll();
		//Ext.Manager3D_Save(dir2+ImageSet+"-Glia.zip"); // save the ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-GliaResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

//Run the 3Dmanager to 3D segement the lysosomes inside microglia & save the ROIs
		selectWindow("LysoMorphRecon");
		run("3D Manager");
		//Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		//Ext.Manager3D_SelectAll();
		//Ext.Manager3D_Save(dir2+ImageSet+"-LysoinGlia.zip"); // save the ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-LysoinGliaResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

//Run the 3Dmanager to 3D segement the fibers inside lysosomes & save the ROIs
		selectWindow("FibersInLyso");
		run("3D Manager");
		//Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		//Ext.Manager3D_SelectAll();
		//Ext.Manager3D_Save(dir2+ImageSet+"-FibresinLyso.zip"); // save the ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();	
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-FibresinLysoResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

		
// Merge outputs with original stack and save it
//check that all are same bit depth - chnage lysomorph recon
	selectWindow("Microglia");
	run("8-bit");
	selectWindow("Lyso");
	run("8-bit");
	selectWindow("Fibers");
	run("8-bit");

		
		run("Merge Channels...", "c1=[Microglia] c2=[Lyso] c3=[Fibers] c4=[GliaMaskFiltered] c5=[LysoMorphRecon] c6=[FibersMask] c7=[FibersInLyso] create");
		Stack.setChannel(1);          
		run("Green");
		Stack.setChannel(2); 
		run("Grays");
		Stack.setChannel(3); 
		run("Red"); 
		Stack.setChannel(4); 
		run("Magenta");
		Stack.setChannel(5);
		run("Yellow");
		Stack.setChannel(6);
		run("Blue");
		Stack.setChannel(7);
		run("Cyan");
		saveAs("tiff", dir2+ImageSet+"Result");


// Close all windows and clear RAM
run("Close All");
		run("Collect Garbage");
		setBatchMode(false);
		run("Collect Garbage");
		setBatchMode(true);
}
exit("All done " +k+ " images analsyed");
 