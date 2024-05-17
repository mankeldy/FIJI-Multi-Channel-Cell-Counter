//inputDir=getDirectory("C:\\Users\\dylan\\Desktop\\2024_04_20_MCR_dual_BONCAT\\All data");
//fileList=getFileList(inputDir);

//Create the dialog GUI box for user
Dialog.create("Multi-channel Microscopy");

//Directory box
path=getDirectory("image");
Dialog.addDirectory("Images path",path);

//Add Channels and Thresholds
Dialog.addMessage("Add each channel substring (e.g. _ch00) and what thresholding you'd like (see Image>Adjust>Threshold):");

threshold_items = newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen");

channel_array = newArray("C1","C2","C3","C4","C5","C6","C7","C8");

for (i=0; i<lengthOf(channel_array); i++) {
    Dialog.addString(channel_array[i], "None");
    Dialog.addToSameRow();
    Dialog.addChoice("Threshold:", threshold_items);
}

//Select counter-stain
Dialog.addMessage("");//just adding a gap
Dialog.addString("Counter-Stain:","");
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
path=Dialog.getString();

//looping through the channel selections and putting them into new arrays
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

selected_counter_stain = Dialog.getString();();

//looping the set measurements selections and make string variable with the correct arguments to call
set_measurements_arguments = "";
set_measurments_imagej_args = newArray("area", "mean", "standard", "modal" ,"min", "centroid", "center" ,"perimeter", "bounding" ,"fit" ,"shape" ,"feret's" ,"integrated", "median" ,"skewness" ,"kurtosis" ,"area_fraction" ,"stack")

for (i=0; i<lengthOf(set_measurements_labels); i++){
	set_measurements_boolean = Dialog.getCheckbox();
	if (set_measurements_boolean==1){
		set_measurements_arguments = set_measurements_arguments + " "+ set_measurments_imagej_args[i];
	}
}

size=Dialog.getString();
unit=Dialog.getString();
//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
////////////////////////////////////////////////////////



//Array.print(fileList);
print("-----Running------");
print("Here are your variables:");
print("path = ", path);
for (i=0; i<lengthOf(selected_channels); i++) {
	print("C",i+1," = ",selected_channels[i],"    Threshold =",selected_thresholds[i]);
}
print("Counter-stain = ",selected_counter_stain)
print("Set Measurements Args = ",set_measurements_arguments);
print("Particle size = ",size," ",unit)


run("Clear Results");
target = "ch00";
iregex = ".*" + target +".*";
close("*");

for (i = 0; i < lengthOf(fileList); i++)
{ 
	run("Set Measurements...", "area_fraction redirect=None");
	if(matches(fileList[i], iregex)){
	print("-----Analyzing"+ fileList[i]+ "-----");
	imageName = substring(fileList[i], 0, lengthOf(fileList[i])-9);
	imageFile = inputDir+imageName;
		
	open(imageFile+"_ch01.tif");
	run("8-bit");
	setOption("BlackBackground", true);
	setAutoThreshold("Yen dark");
	run("Convert to Mask");

	open(imageFile+"_ch02.tif");
	run("8-bit");
	setOption("BlackBackground", true);
	setAutoThreshold("Yen dark");
	run("Convert to Mask");

	open(imageFile+"_ch00.tif");
	
	run("8-bit");
	setOption("BlackBackground", true);
	setAutoThreshold("Moments dark");
	run("Convert to Mask");

	run("Watershed");
	prevNumResults = nResults;
	run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
	for (row = prevNumResults; row < nResults; row++){
		setResult("FileName", row, imageName+"_ch00.tif");
	}
	
	prevNumResults = nResults;
	run("Set Measurements...", "area_fraction redirect=["+imageName+"_ch01.tif]");
	run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
	for (row = prevNumResults; row < nResults; row++){
		setResult("FileName", row, imageName+"_ch01.tif");
	}
	prevNumResults = nResults;
	run("Set Measurements...", "area_fraction redirect=["+imageName+"_ch02.tif]");
	run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
	for (row = prevNumResults; row < nResults; row++){
		setResult("FileName", row, imageName+"_ch02.tif");
	}
	close("*");
	}
}


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