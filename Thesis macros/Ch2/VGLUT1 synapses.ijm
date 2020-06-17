	dir1 = getDirectory("Choose Source Directory "); //select an input folder
 	dir2 = getDirectory("Choose a folder to save to"); //select an output folder. 
 	list = getFileList(dir1); //make a list of the filenames
 	setBatchMode(true); //turn on batch mode to run in the background - RAM keeps filling up!

	run("3D Manager Options", "volume distance_between_centers=10 distance_max_contact=1.80"); //set 3D manager to only measure volumes


for (k=0; k<list.length; k++) { 
 	showProgress(k+1, list.length);
 	filename = dir1 + list[k];
	open(filename);	
	//setMinAndMax(0, 65535); //set bit depth for homogeneous brightness in deconv images
	Imagename = File.nameWithoutExtension;//record image name for saving results

// take off first and last 3 sections!!!!
	end = (nSlices/3)-2;
	run("Duplicate...", "title=Orig duplicate channels=3 slices=3-"+end+"");
	run("Duplicate...", "title=Synapses duplicate");

	run("Subtract Background...", "rolling=10 stack");
	run("Median...", "radius=2 stack");
	//run("Median 3D...", "x=1 y=1 z=1");
	setAutoThreshold("Otsu dark stack"); //moments worked well for most apart from FnAN 4
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark");
	run("Analyze Particles...", "size=10-Infinity circularity=0.50-1.00 show=Masks stack");
	selectWindow("Mask of Synapses");
	rename("FilteredSynapses");
	
//Run the 3Dmanager to 3D segement synapses save the ROIs
		selectWindow("FilteredSynapses");
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_Synapses_Vol"+Imagename+".txt");
		Ext.Manager3D_CloseResult("M");

		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_Count(nb);
		print("Number of synapses_"+Imagename+" = "+nb);
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_Synapses_Objects"+Imagename+".txt"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");
		
		selectWindow("Orig");
		run("8-bit");
		selectWindow("FilteredSynapses");
		run("Invert LUT");
		
		run("Merge Channels...", "c1=[Synapses] c2=[FilteredSynapses] create");
		Stack.setChannel(1);          
		run("Green");
		Stack.setChannel(2); 
		run("Red");

		saveAs("tiff", dir2+Imagename+"_Result");
			
// Close all windows and clear RAM
run("Close All");
		run("Collect Garbage");
		setBatchMode(false);
		run("Collect Garbage");
		setBatchMode(true);
}

selectWindow("Log")
saveAs("Text", dir2+"Log with synapse count");

exit("All done " +k+ " images analsyed");
	