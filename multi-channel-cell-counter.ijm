//Create the dialog GUI box for user
Dialog.create("Multi-channel Microscopy");

//Directory box
inputDir=getDirectory("image");
Dialog.addDirectory("Images path",inputDir);

//Add Channels and Thresholds
Dialog.addMessage("Add each channel substring (e.g. ch00) and what thresholding you'd like (see Image>Adjust>Threshold):");

//List of threshold items in ImageJ
threshold_items = newArray("None","Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen");

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

//Add watershed information
Dialog.addMessage("Add watershed parameters (Default: 0.5, if this is adjusted then make sure you have the Adjustable Watershed plugin!):");
Dialog.addCheckbox("Watershed?",true); 
Dialog.addToSameRow();
Dialog.addString("Tolerance", "0.5");

//Add analyze particles information
Dialog.addMessage("Add particle size information (see Analyze>Analyze Particles):");
Dialog.addString("size", "0-Infinity");
Dialog.addToSameRow();
Dialog.addString("unit (e.g. micron, pixel)", "micron");

//Show the dialog window
Dialog.show();

////////////////////////////////////////////////
//        Getting Input Variables            //
//////////////////////////////////////////////

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

//Watershed Inputs
do_watershed=Dialog.getCheckbox();
watershed_tolerance=Dialog.getString();

if (do_watershed == 1) {
    watershed_result = "true";
} else {
    watershed_result = "false";
}

//Analyze Particicles Inputs
size=Dialog.getString();
unit=Dialog.getString();

//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
////////////////////////////////////////////////////////

print("-----Running------");
print("Here are your variables:");
print("path = ", inputDir);
for (i=0; i<lengthOf(selected_channels); i++) {
	print("C",i+1," = ",selected_channels[i],"    Threshold =",selected_thresholds[i]);
}

print("Counter-stain = ",selected_counter_stain);
print("Set Measurements Args = ",selected_set_measurements_arguments);
print("Perform Watershed = ", watershed_result);
print("Watershed Tolerance = ", watershed_tolerance);
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
		// Remove only the first occurrence of the counter-stain from selected_channels
		selected_data_channels = newArray();
		removed = false;
		for (i = 0; i < lengthOf(selected_channels); i++) {
		    if (!removed && selected_channels[i] == selected_counter_stain) {
		        removed = true;
		    } else {
		        selected_data_channels = Array.concat(selected_data_channels, selected_channels[i]);
		    }
		}
	}
} else {
	target_substring = selected_channels[0];
	selected_data_channels = selected_channels;
}

iregex = ".*" + target_substring +".*";


////////////////////////////////////////////////
/////////// Main Analysis Loop /////////////////
////////////////////////////////////////////////

for (i = 0; i < lengthOf(fileList); i++){
	// Variable to track if the counter-stain has been found
	counter_stain_found = false;
	
	//enters the if-statement for each unique field of view (based on the counter-stain images)
	if(matches(fileList[i], iregex)){
		print("-----Analyzing "+ fileList[i]+ "-----");

		//splits the file name in to two halves to get the file name structure so that it can be used to open each channel		
		//array of left (0) and right side (1) of the file name 
		index_channel_substring = indexOf(fileList[i], target_substring);
		imageName_split_by_channel = newArray(substring(fileList[i], 0, index_channel_substring),substring(fileList[i], index_channel_substring+lengthOf(target_substring)));
		
		//for error testing if the images aren't opening properly
		//print(imageName_split_by_channel[0],imageName_split_by_channel[1]);
	
		//Opens every channel image in each field of view 
		for (j = 0; j < lengthOf(selected_channels); j++){
		    img_path = inputDir + imageName_split_by_channel[0] + selected_channels[j] + imageName_split_by_channel[1];
		    print("opening " + img_path);
		    open(img_path);
		    run("8-bit");
		    setOption("BlackBackground", true);
            
		    // Check if this is the first occurrence of the counter-stain in the sequence
		    if (selected_channels[j] == selected_counter_stain && !counter_stain_found) {
		    	// Selecting the window so we can change the name
		    	selectWindow(imageName_split_by_channel[0] + selected_channels[j] + imageName_split_by_channel[1]);
		        // Rename the original image so it can be preserved and referred to later
		        counter_stain_image_name = "counter_stain_image";
		        rename(counter_stain_image_name);
		        print("Renamed the counter-stain to: " + counter_stain_image_name);
		        // Mark counter-stain as found
		        counter_stain_found = true;
		    }
		    
		    //thresholding the image
		    if (selected_thresholds[j] != "None") {
		        setAutoThreshold(selected_thresholds[j] + " dark");
		        run("Convert to Mask");
		    } else {
		        print("Skipping thresholding for channel: " + selected_channels[j]);
		    } 
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
			selectWindow(counter_stain_image_name);
		
			//Watershed algorithm seperates overlapping blobs
			//Runs the default Watershed algorithm if tolerance is 0.5, otherwise it uses the adjustable plugin (must be installed)
			if (do_watershed == 1) {
				if (watershed_tolerance == 0.5){
					run("Watershed");
				} else {
					run("Adjustable Watershed", "tolerance="+watershed_tolerance);
				}
			}
		
			run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
			
			for (row = prevNumResults; row < nResults; row++){
				setResult("FileName", row, imageName_split_by_channel[0]+selected_counter_stain+imageName_split_by_channel[1]);
				setResult("Image Type", row, "counter-stain");
				setResult("Cell Number", row, row-prevNumResults);
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
				if (do_watershed == 1) {
					if (watershed_tolerance == 0.5){
						run("Watershed");
					} else {
						run("Adjustable Watershed", "tolerance="+watershed_tolerance);
					}
				}
			}
			
			run("Analyze Particles...", "size="+size+" "+unit+" "+"show=Overlay overlay display exclude");
			for (row = prevNumResults; row < nResults; row++){
				setResult("FileName", row, imageName_split_by_channel[0]+selected_data_channels[channel]+imageName_split_by_channel[1]);
				setResult("Image Type", row, "data");
				setResult("Cell Number", row, row-prevNumResults);
				}
		}
		//Closing the images for this field of view to start it fresh for the next one
		close("*");
		}
	}


//Auto-save Log
selectWindow("Log");
File.makeDirectory(inputDir+"/cell_counter_log");
log_path = inputDir+"/cell_counter_log/cell_counter_log.txt";
saveAs("Text",log_path);