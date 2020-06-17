/* Macro written by Yajing Xu, Jan 2019
 *  Opens a 4 channel stack
 *  Identifies Synapses in channel 2
 *  Measures synapse volumes
 *  Use ch2 mask to identify C1q IntDens on channel 4 using the 3D manager
*/

	dir1 = getDirectory("Choose Source Directory "); //select an input folder
 	dir2 = getDirectory("Choose a folder to save to"); //select an output folder. 
 	list = getFileList(dir1); //make a list of the filenames
 	setBatchMode(true); //turn on batch mode to run in the background - RAM keeps filling up!
 	
 //set 3D manager to measure volumes, IntDens, mean grey value
 	run("3D Manager Options", "volume integrated_density mean_grey_value distance_between_centers=10 distance_max_contact=1.80 drawing=Contour");

// open folders, set up the loop.

for (k=0; k<list.length; k++) { 
 	showProgress(k+1, list.length);
 	filename = dir1 + list[k];
	open(filename);	
	Imagename = File.nameWithoutExtension;
	
	rename ("Orig");
	selectWindow("Orig");
	run("Duplicate...", "title=Synapse duplicate channels=2"); //duplicate images to merge at the end
	selectWindow("Orig");
	run("Duplicate...", "title=Microglia duplicate channels=3"); //duplicate images to merge at the end
	selectWindow("Orig");
	run("Duplicate...", "title=C1q duplicate channels=4"); //duplicate images to merge at the end

//Identify Glia
	selectWindow("Orig");
	run("Duplicate...", "title=MicrogliaOrig duplicate channels=3");
	run("Subtract Background...", "rolling=50 stack");
	run("Gaussian Blur 3D...", "x=1 y=1 z=1");
	setAutoThreshold("Moments dark stack");//threshold for the histogram of the whole stack
	run("Convert to Mask", "method=Moments background=Dark");
	run("Fill Holes", "stack");
	run("Invert LUT");
	rename("MicrogliaMask");
	
//Identify Synapses
	selectWindow("Orig");
	run("Duplicate...", "title=SynapseOrig duplicate channels=2");
	run("Subtract Background...", "rolling=20 stack");
	setAutoThreshold("Moments dark stack");//threshold on whole stack histogram
	run("Convert to Mask", "method=Moments background=Dark");//threshold to a black and white image, the triangle method worked best
	//3D processing to select object >10 voxels
		run("3D Simple Segmentation", "low_threshold=128 min_size=10 max_size=-1");
		setThreshold(1, 65535);
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Dark");//3 lines to make the 3D output black and white
		run("Invert LUT");
	rename("SynapseMask");


//Open C1q channel
	selectWindow("Orig");
	run("Duplicate...", "title=C1qOrig duplicate channels=4");


//Make a binary image of the synapses overlapping with cells
		imageCalculator("AND create stack", "MicrogliaMask","SynapseMask");
		rename("Synapse in MG");

//Run the 3Dmanager to measure MG, synapse, synapse in MG volume
		run("3D Manager");
		selectWindow("MicrogliaMask");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Select(0);
		Ext.Manager3D_Rename("gliaroi");

		selectWindow("SynapseMask");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Select(1);
		Ext.Manager3D_Rename("synapseroi");
		
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Coloc();
		
		selectWindow("Synapse in MG");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Select(2);
		Ext.Manager3D_Rename("synapse_in_glia_roi");

		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Measure();
		
		
		//close, name & save file
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+Imagename+"-glia&synase&overlap.zip"); // save the ROIs
		Ext.Manager3D_SaveResult("M", dir2+Imagename+"-glia&synase&overlap_VolumeResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		Ext.Manager3D_SaveResult("Coloc", dir2+Imagename+"-coloc.txt");
		Ext.Manager3D_CloseResult("Coloc");

		run("Collect Garbage");


// Measure C1q amount in Synapses
	Ext.Manager3D_SelectAll();
	selectWindow("C1qOrig");

	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q", dir2+Imagename+"-C1qIDResults3D.txt"); // save the results
	Ext.Manager3D_CloseResult("Q");
	
	run("Collect Garbage");


	//Make visual output for C1q in synapses and glia
	
	selectWindow("SynapseMask");
	run("Duplicate...", "duplicate");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "C1qOrig","SynapseMask-1");
	selectWindow("Result of C1qOrig");
	rename("SynapsexC1q");

	selectWindow("MicrogliaMask");
	run("Duplicate...", "duplicate");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "C1qOrig","MicrogliaMask-1");
	selectWindow("Result of C1qOrig");
	rename("GliaxC1q");

	//Measure Integrated Density  for C1q in the whole stack, save at the end
	selectWindow("C1qOrig");
	run("Z Project...", "projection=[Sum Slices]");
	run("Measure");

// Merge outputs with original stack and save it
//check that all are same bit depth

		selectWindow("SynapseMask");
		run("16-bit");
		selectWindow("MicrogliaMask");
		run("16-bit");
		selectWindow("Synapse in MG");
		run("16-bit");
		
		run("Merge Channels...", "c1=[Synapse] c2=[Microglia] c3=[SynapseMask] c4=[MicrogliaMask] c5=[Synapse in MG] c6=[SynapsexC1q] c7=[GliaxC1q] create");
		Stack.setChannel(1);
		run("Red");
		Stack.setChannel(2); 
		run("Green");
		Stack.setChannel(3); 
		run("Cyan");
		Stack.setChannel(4); 
		run("Magenta");
		Stack.setChannel(5); 
		run("Yellow");
		Stack.setChannel(6); 
		run("Grays");
		Stack.setChannel(7); 
		run("Grays");
		saveAs("tiff", dir2+Imagename+"Result");

// Close all windows and clear RAM
	run("Close All");
		run("Collect Garbage");
		setBatchMode(false);
		run("Collect Garbage");
		setBatchMode(true);
}

//save Integrated Density  for C1q in the whole stack for all images in the directory
saveAs("Results", dir2+"WholestackC1qID.txt");
run("Clear Results");

exit("All done " +k+ " images analsyed");




