/* Macro written by Dale Moulding & Yajing Xu, UCL, November 2018
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

 	
 	run("3D Manager Options", "volume distance_between_centers=10 distance_max_contact=1.80"); //set 3D manager to only measure volumes

// open folders, set up the loop.

for (k=0; k<list.length; k++) { 
 	showProgress(k+1, list.length);
 	filename = dir1 + list[k];
	open(filename);	
	//setMinAndMax(0, 65535); //set bit depth for homogeneous brightness in deconv images
	Imagename = File.nameWithoutExtension; // make a working copy of each channel
	ImageSet = substring(Imagename, 0, lengthOf(Imagename)); // record the file name for saving later

	rename ("Orig");
	selectWindow("Orig");
	run("Duplicate...", "title=Microglia duplicate channels=1"); //duplicate images to merge at the end
	selectWindow("Orig");
	run("Duplicate...", "title=Lyso duplicate channels=2"); //duplicate images to merge at the end
	selectWindow("Orig");
	run("Duplicate...", "title=Fibers duplicate channels=3"); //duplicate images to merge at the end

// Identify Glial cells
	selectWindow("Orig");
	run("Duplicate...", "title=MicrogliaOrig duplicate channels=1");
	run("Subtract Background...", "rolling=50 stack");
	run("Median 3D...", "x=1.5 y=1.5 z=1.5");
	setAutoThreshold("Triangle dark stack");//threshold for the histogram of the whole stack
	run("Convert to Mask", "method=Triangle background=Dark");
	rename("GliaMask");
//3D processing to select object > 20 voxels min_size
	run("3D Simple Segmentation", "low_threshold=128 min_size=20 max_size=-1");
	setThreshold(1, 65535);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Dark");//3 lines to make the 3D output black and white
//Close gaps in identified cells, and fill holes	
	//run("Options...", "iterations=5 count=2 pad do=Close stack");
	//run("Fill Holes", "stack");
	run("Invert LUT");
	rename("GliaMaskFiltered"); // Result of Glial cell identification called GliaMaskFiltered

// Identify lysosomes
	selectWindow("Orig");
	run("Duplicate...", "title=LysoOrig duplicate channels=2");
	run("Remove Outliers...", "radius=2 threshold=20 which=Bright stack");
	run("Subtract Background...", "rolling=10 stack");
	run("Median...", "radius=2.0 stack");
	//run("Gaussian Blur 3D...", "x=0.2 y=0.2 z=0.2");
	setAutoThreshold("Moments dark stack");//threshold for the histogram of the whole stack otsu or moments
	run("Convert to Mask", "method=Moments background=Dark");
	rename("LysoMask");
	
// Identify fibers
	selectWindow("Orig");
	run("Duplicate...", "title=FibersOrig duplicate channels=3");
	run("Subtract Background...", "rolling=25 stack");
	run("Gaussian Blur 3D...", "x=0.5 y=0.5 z=0.5");
	setAutoThreshold("Triangle dark stack");//threshold for the histogram of the whole stack
	run("Convert to Mask", "method=Triangle background=Dark");
	rename("FibersMask");


// Identify lysosomes inside glia
	// use morpho recomnstruction to grow lysosomes to full size
	// or try 3D spot segmentation
	
	selectWindow("Orig");
	x = getWidth();
	y = getHeight();

	selectWindow("GliaMaskFiltered");
	n=nSlices;
	newImage("LysoMorphRecon", "8-bit white", x, y, n); // Identified Lysosomes "LysoMorphRecon"
		
	for (i = 1; i < n+1; i++) {
	 	selectWindow("GliaMaskFiltered");
	 	setSlice(i);
	 	selectWindow("LysoMask");
	 	setSlice(i);
	 	run("Morphological Reconstruction", "marker=GliaMaskFiltered mask=LysoMask type=[By Dilation] connectivity=4");
	 	selectWindow("GliaMaskFiltered-rec");
	 	run("Select All");
		run("Copy");
		selectWindow("LysoMorphRecon");
		setSlice(i);
		run("Paste");
		selectWindow("GliaMaskFiltered-rec");
		close();
	 }
	
// Identify fibres inside the lysosomes
	imageCalculator("AND create stack", "FibersMask","LysoMorphRecon");
	rename("FibersInLyso"); // Identified fibres inside lysosomes "FibersInLyso"


//Run the 3Dmanager to 3D segement the Glia & save the ROIs
		selectWindow("GliaMaskFiltered");
		run("3D Manager");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+ImageSet+"-Glia.zip"); // save the ROIs
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-GliaResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

//Run the 3Dmanager to 3D segement the lysosomes inside microglia & save the ROIs
		selectWindow("LysoMorphRecon");
		run("3D Manager");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+ImageSet+"-LysoinGlia.zip"); // save the ROIs
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-LysoinGliaResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

//Run the 3Dmanager to 3D segement the fibers inside lysosomes & save the ROIs
		selectWindow("FibersInLyso");
		run("3D Manager");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+ImageSet+"-FibresinLyso.zip"); // save the ROIs
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-FibresinLysoResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");
		
// Merge outputs with original stack and save it
//check that all are same bit depth
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
	