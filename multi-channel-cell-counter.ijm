//inputDir=getDirectory("C:\\Users\\dylan\\Desktop\\2024_04_20_MCR_dual_BONCAT\\All data");
//fileList=getFileList(inputDir);

//Create the dialog GUI box for user
Dialog.create("Multi-channel Microscopy");

//Directory box
inputDir=getDirectory("image");
Dialog.addDirectory("Images path",inputDir);

//Add Channels and Thresholds
Dialog.addMessage("Add each channel substring (e.g. _ch00) and what thresholding you'd like (see Image>Adjust>Threshold):");

//List of threshold items in ImageJ
threshold_items = newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen");

//List of available channels, can increase more if necessary (in the ideal world, a user could add new channels, but it's unclear if it's possible in the macro language)
channel_array = newArray("C1","C2","C3","C4","C5","C6","C7","C8");

//Creating the Channel and Threshold boxes
for (i=0; i<lengthOf(channel_array); i++) {
    Dialog.addString(channel_array[i], "None");
    Dialog.addToSameRow();
    Dialog.addChoice("Threshold:", threshold_items);
}

//Select counter-stain
Dialog.addMessage("");//just adding a gap

Dialog.addCheckbox("Counter-stain?",true); 
Dialog.addToSameRow(); 
Dialog.addMessage("(unchecking will mean particles will not necessarily overlap between channels)");

Dialog.addString("Counter-stain substring","");
Dialog.addToSameRow();
Dialog.addMessage("Make sure it is one of the channels listed above!");

// Add Set Measurements checkboxes
Dialog.addMessage("Select the information you'd like to report (see Analyze>Set Measurements):");
rows = 9
columns = 2
set_measurements_labels = newArray("Area","Mean gray value", "Standard deviation", "Modal gray value", "Min & max gray value", "Centroid", "Center of mass", "Perimeter", "Bounding rectangle", "Fit ellipse", "shape descriptors", "Feret's diameter", "Integrated density", "Median", "Skewness", "Kurtosis", "Area fraction", "Stack position");
set_measurements_defaults = newArray(lengthOf(set_measurements_labels));
for (i=0; i<lengthOf(set_measurements_labels); i++) {
    set_measurements_defaults[i] = false;
}
Dialog.addCheckboxGroup(rows,columns,set_measurements_labels,set_measurements_defaults);


//Add analyze particles information
Dialog.addMessage("Add particle size information (see Analyze>Analyze Particles):");
Dialog.addString("size", "2-Infinity");
Dialog.addToSameRow();
Dialog.addString("unit (e.g. micron, pixel)", "micron");

//Show the dialog window
Dialog.show();

//////////////////////////////////////////
//        Getting Variables            //
/////////////////////////////////////////

//Get path string
inputDir=Dialog.getString();

//looping through the channel selections and putting them into new arrays without the None
selected_channels = newArray();
selected_thresholds = newArray();

for (i=0; i<lengthOf(channel_array); i++) {
	current_channel = Dialog.getString();
	current_threshold = Dialog.getChoice();
		if (current_channel!="None"){
			selected_channels = Array.concat(selected_channels, current_channel);
			selected_thresholds = Array.concat(selected_thresholds, current_threshold);
		}
}

is_there_a_counter_stain = Dialog.getCheckbox();
selected_counter_stain = Dialog.getString();


//looping the set measurements selections and make string variable with the correct arguments to call
selected_set_measurements_arguments = "";
set_measurments_imagej_args = newArray("area", "mean", "standard", "modal" ,"min", "centroid", "center" ,"perimeter", "bounding" ,"fit" ,"shape" ,"feret's" ,"integrated", "median" ,"skewness" ,"kurtosis" ,"area_fraction" ,"stack");

for (i=0; i<lengthOf(set_measurements_labels); i++){
	set_measurements_boolean = Dialog.getCheckbox();
	if (set_measurements_boolean==1){
		selected_set_measurements_arguments = selected_set_measurements_arguments + " "+ set_measurments_imagej_args[i];
	}
}
//if no set measurement args are selected, it defaults to area fraction
if (selected_set_measurements_arguments == ""){
	print("No Set Measurements arguments were selected, defaulting to Area Fraction");
	selected_set_measurements_arguments = "area_fraction";
}


size=Dialog.getString();
unit=Dialog.getString();
//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
////////////////////////////////////////////////////////



//Array.print(fileList);
print("-----Running------");
print("Here are your variables:");
print("path = ", inputDir);
for (i=0; i<lengthOf(selected_channels); i++) {
	print("C",i+1," = ",selected_channels[i],"    Threshold =",selected_thresholds[i]);
}

print("Counter-stain = ",selected_counter_stain);
print("Set Measurements Args = ",selected_set_measurements_arguments);
print("Particle size = ",size," ",unit);
//////////////////////////////////////////////////////////////

run("Clear Results");
close("*");
fileList = getFileList(inputDir);

//selects the counter-stain as the reference for determining file names
//if there is no counter-stain, then the first channel is used.
if (is_there_a_counter_stain==1){
	if (selected_counter_stain == ""){
		exit("Counter-stain selected but no counter-stain channel was specified. Please indicate correctly whether you used a counter-stain, and specify the correct channe!");
	} else {
	target_substring = selected_counter_stain;
	selected_data_channels = Array.deleteValue(selected_channels, selected_counter_stain);
	}
} else {
	target_substring = selected_channels[0];
	selected_data_channels = selected_channels;
}

iregex = ".*" + target_substring +".*";

for (i = 0; i < lengthOf(fileList); i++){
	
	//enters the if-statement for each unique field of view (based on the counter-stain images)
	if(matches(fileList[i], iregex)){
		print("-----Analyzing "+ fileList[i]+ "-----");

		//splits the file name in to two halves to get the file name structure so that it can be used to open each channel
		imageName_split_by_channel = split(fileList[i], target_substring);
		print(imageName_split_by_channel[0]);

	
		//Opens the channel images in each field of view 
		for (j = 0; j < lengthOf(selected_channels); j++){
			print("opening "+inputDir+imageName_split_by_channel[0]+selected_channels[j]+imageName_split_by_channel[1]);
			open(inputDir+imageName_split_by_channel[0]+selected_channels[j]+imageName_split_by_channel[1]);
			run("8-bit");
			setOption("BlackBackground", true);
			setAutoThreshold(selected_thresholds[j]);
			run("Convert to Mask");
			}
		
		//Setting initial set measurements
		//If there is a counter-stain, only this line will apply for the counter-stain and the rest must be redirected
		//If there is no counter-stain, then this line will be used for all images
		run("Set Measurements...", selected_set_measurements_arguments+" "+"redirect=None");
		
		//////////////////////////////////////
		//selecting the counter-stain image, if applicable.
		/////////////////////////////////////
		//prevNumResults allows data from each channel and FOV to be added to the same results page
		prevNumResults = nResults;
		
		//Runs the counter stain first if there is one
		if (is_there_a_counter_stain == 1){
			selectWindow(imageName_split_by_channel[0]+selected_counter_stain+imageName_split_by_channel[1]);
		
			//Watershed algorithm seperates overlapping blobs
			run("Watershed");
		
			run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
			
			
			for (row = prevNumResults; row < nResults; row++){
				setResult("FileName", row, imageName_split_by_channel[0]+selected_counter_stain+imageName_split_by_channel[1]);
				setResult("Image Type", row, "counter-stain");
			}
		}
		////////////////////////////////////////
		// Analyzing data images
		///////////////////////////////////////
		for (channel = 0; channel < lengthOf(selected_data_channels);channel++){
			prevNumResults = nResults;
			
			//if there is a counter-stain, then we need to reset the set measurements, keeping the counter-stain window open
			//if there is no counter-stain, then we use the initial set measurements from above and instead must select each window and run watershed
			if (is_there_a_counter_stain == 1){
				run("Set Measurements...", selected_set_measurements_arguments+" "+"redirect=["+imageName_split_by_channel[0]+selected_data_channels[channel]+imageName_split_by_channel[1]+"]");
			}
			else {
				selectWindow(imageName_split_by_channel[0]+selected_data_channels[channel]+imageName_split_by_channel[1]);
				run("Watershed");
			}
			
			run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
			for (row = prevNumResults; row < nResults; row++){
				setResult("FileName", row, imageName_split_by_channel[0]+selected_data_channels[channel]+imageName_split_by_channel[1]);
				setResult("Image Type", row, "data");
				}
		}
		//Closing the images for this field of view to start it fresh for the next one
		close("*");
		}

	
	}
	
	






//run("Clear Results");
//target = "ch00";
//iregex = ".*" + target +".*";
//close("*");
//
//for (i = 0; i < lengthOf(fileList); i++)
//{ 
//	run("Set Measurements...", "area_fraction redirect=None");
//	if(matches(fileList[i], iregex)){
//	print("-----Analyzing"+ fileList[i]+ "-----");
//	imageName = substring(fileList[i], 0, lengthOf(fileList[i])-9);
//	imageFile = inputDir+imageName;
//		
//	open(imageFile+"_ch01.tif");
//	run("8-bit");
//	setOption("BlackBackground", true);
//	setAutoThreshold("Yen dark");
//	run("Convert to Mask");
//
//	open(imageFile+"_ch02.tif");
//	run("8-bit");
//	setOption("BlackBackground", true);
//	setAutoThreshold("Yen dark");
//	run("Convert to Mask");
//
//	open(imageFile+"_ch00.tif");
//	
//	run("8-bit");
//	setOption("BlackBackground", true);
//	setAutoThreshold("Moments dark");
//	run("Convert to Mask");
//
//	run("Watershed");
//	prevNumResults = nResults;
//	run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
//	for (row = prevNumResults; row < nResults; row++){
//		setResult("FileName", row, imageName+"_ch00.tif");
//	}
//	
//	prevNumResults = nResults;
//	run("Set Measurements...", "area_fraction redirect=["+imageName+"_ch01.tif]");
//	run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
//	for (row = prevNumResults; row < nResults; row++){
//		setResult("FileName", row, imageName+"_ch01.tif");
//	}
//	prevNumResults = nResults;
//	run("Set Measurements...", "area_fraction redirect=["+imageName+"_ch02.tif]");
//	run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
//	for (row = prevNumResults; row < nResults; row++){
//		setResult("FileName", row, imageName+"_ch02.tif");
//	}
//	close("*");
//	}
//}
//

//open("D:\\graduate material\\2024_04_20_MCR_dual_BONCAT\\DMSL005\\"+image_name+"_ch00.tif"



//run("8-bit");
//setOption("BlackBackground", true)
//setAutoThreshold("Default dark");
//setThreshold(40,255,"raw");
//run("Convert to Mask");

//run("Watershed");

//run("Analyze Particles...", "size=2-Infinity micron show=Outlines exclude summarize");



//roiManager("add");

//roiManager("Select",0);
//roiManager("Delete");

//close();
//close();