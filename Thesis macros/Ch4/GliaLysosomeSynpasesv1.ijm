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
	run("Duplicate...", "title=Synapses duplicate channels=2"); //duplicate images to merge at the end
	selectWindow("Orig");
	run("Duplicate...", "title=Lysosomes duplicate channels=3"); //duplicate images to merge at the end

//Identify glial cells
		selectWindow("Microglia");
		run("Duplicate...", "title=glia duplicate");//make a copy to work on
		run("Subtract Background...", "rolling=50 stack");
		run("Median 3D...", "x=1 y=1 z=1");
		run("Remove Outliers...", "radius=4 threshold=200 which=Bright stack");//get rid of nasty spotty background
		setAutoThreshold("Triangle dark stack");//threshold for the histogram of the whole stack
		run("Convert to Mask", "method=Triangle background=Dark");
	//3D processing to select object > 10000 voxels min_size
		run("3D Simple Segmentation", "low_threshold=128 min_size=10000 max_size=-1");
		setThreshold(1, 65535);
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Dark");//3 lines to make the 3D output black and white
	//Close gaps in identified Glia, and fill holes	
		run("Options...", "iterations=5 count=2 pad do=Close stack");
		run("Fill Holes", "stack");
		run("Invert LUT");
		rename("GliaMask");
	//close windows and clear RAM
		selectWindow("glia");
		close();
		selectWindow("Bin");
		close();
		run("Collect Garbage");


//Identify Lysosomes
		selectWindow("Lysosomes");
		run("Duplicate...", "title=lysosomes duplicate");//make a copy to work on
		run("Subtract Background...", "rolling=10 stack");
		setAutoThreshold("Triangle dark stack");//threshold on whole stack histogram
		run("Convert to Mask", "method=Triangle background=Dark");//threshold to a black and white image, the triangle method worked best
	//3D processing to select object >100 voxels
		run("3D Simple Segmentation", "low_threshold=128 min_size=100 max_size=-1");
		setThreshold(1, 65535);
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Dark");//3 lines to make the 3D output black and white
		run("Invert LUT");
		rename("LysoMask");
	//close windows and clear RAM
		selectWindow("lysosomes");
		close();
		selectWindow("Bin");
		close();
		run("Collect Garbage");


//Identify Synapses
		selectWindow("Synapses");
		run("Duplicate...", "title=synapses duplicate");//make a copy to work on
		run("Subtract Background...", "rolling=20 stack");
		setAutoThreshold("Otsu dark stack");//threshold on whole stack histogram
		run("Convert to Mask", "method=Otsu background=Dark");//threshold to a black and white image, the triangle method worked best
	//3D processing to select object >10 voxels
		run("3D Simple Segmentation", "low_threshold=128 min_size=10 max_size=-1");
		setThreshold(1, 65535);
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Dark");//3 lines to make the 3D output black and white
		run("Invert LUT");
		rename("SynapsesMask");
	//close windows and clear RAM
		selectWindow("synapses");
		close();
		selectWindow("Bin");
		close();
		run("Collect Garbage");

//Identify lysosomes inside glia
	imageCalculator("AND create stack", "LysoMask","GliaMask");
	rename("LysoInGlia");

	imageCalculator("AND create stack", "SynapsesMask","LysoInGlia");
	rename("SynapsesInLyso");


//Run the 3Dmanager to 3D segement the Glia & save the ROIs
		selectWindow("GliaMask");
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
		selectWindow("LysoInGlia");
		run("3D Manager");
		//Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		//Ext.Manager3D_SelectAll();
		//Ext.Manager3D_Save(dir2+ImageSet+"-LysoinGlia.zip"); // save the ROIs
		Ext.Manager3D_Close();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-LysoinGliaResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");


//Run the 3Dmanager to 3D segement the synapses inside lysosomes & save the ROIs
		selectWindow("SynapsesInLyso");
		run("3D Manager");
		//Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure(); //measure ROIs
		//Ext.Manager3D_SelectAll();
		//Ext.Manager3D_Save(dir2+ImageSet+"-SynapsesInLyso.zip"); // save the ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_Close();
		Ext.Manager3D_SaveResult("M", dir2+ImageSet+"-SynapsesInLysoResults3D.txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

		
//merge the output images with the original stack, save it.
		selectWindow("Orig Glia");
		run("8-bit");

		selectWindow("Orig Lysosomes");
		run("8-bit");
		
		selectWindow("Orig Synapses");
		run("8-bit");
	
		run("Merge Channels...", "c1=[Orig Glia] c2=[Orig Lysosomes] c3=[Orig Synapses]c4=[GliaMask] c5=[LysoInGlia] c6=[SynapsesMask] c7=[SynapsesInLyso] create");
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

//close all windows, clear the RAM
		run("Close All");
		run("Collect Garbage");
		setBatchMode(false);
		run("Collect Garbage");
		setBatchMode(true);
}
exit("All done " +i/3+ " images analsyed");
