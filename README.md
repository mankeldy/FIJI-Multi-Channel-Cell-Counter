# FIJI Multi-Channel-Cell-Counter
 
The FIJI Multi-Channel-Cell-Counter macro strings together multiple FIJI plugins in series to automatically processes multi-channel microscopy images. For each field of view, images for each channel are opened based on the filename substring and the desired thresholds are applied. If a general cell counterstain was applied to the sample (e.g. DAPI, SybrGreen, etc.), this image is analyzed first; a watershed is applied (*Process>Binary>Watershed*) to seperate cell aggregates and the particles are analyzed (*Analyze>Analyze Particles*). These particle regions are redirected to each subsequent channel and the desired data is output (*Analyze>Set Measurements*). If a counterstain was not used in the experiment, then each channel is analyzed this way independently.

# Getting started:

To run the macro, in FIJI go to *Plugins>Macro>Run* and select `multi-channel-cell-counter.ijm`. You may also go to *Plugins>Macro>Edit* and open the macro that way so that it can be run directly from that window instead.

Here is an example of a filled out GUI:

<p align="center">
<img src="/tutorial/Multi-channel-cell-counter-ui-as_of_01-05-2025.jpg" alt="GUI Example" width="500px"/>
</p>

### 1) Open Image Path
Press **Browse** and select the folder containing your images

### 2) Add Channels
Write the substring (e.g. ch00, DAPI, etc.) for each channel that is contained within the image filenames. The location of this substring within the filename should not matter, but for this to work correctly, the rest of the image name must be the same between channels within the same field of view.

For each channel, select the desired threshold, if any. This should be determined ahead of time (see *Image>Adjust>Threshold* or https://imagej.net/plugins/auto-threshold) (Note: For now, this is limited to automatic thresholds but future additions to the macro may allow for manual thresholding).

Lastly, if necessary, select which channel(s) is the counter-stain that a counterstain was used (for instance, we use DAPI to identify all microbial cells within the sample). If selected, the particles in this channel will be analyzed first and redirected to the other channels.

### 3) Select Measurements
Select what particle data you would like to report for your downstream analyses (see *Analyze>Set Measurements*).

### 4) Optional: Apply Watershed
For particles that overlap, a watershed could be applied to seperate these particles. 

### 5) Limit Particle Parameters
Finally, adjust the desired particle size (see *Analyze>Analyze Particles*) and circularity. 

### 6) Optional: Align with MultiStackReg
If your channels are slightly misaligned (e.g. due to chromatic abberation or slight misalignments in laser optics), you can applied a representative transformation to realign all channels and fields of view. Simply press Browse and select your transformation file from [MultiStackReg](https://imagej.net/plugins/multistackreg).

### 5) Run
Press **OK** and the analysis should begin. For each run, a `log` file will be saved with your chosen inputs. Once complete, **save** the `Results` window.

# Tutorial

Download the [`tutorial`](tutorial) folder if you don't already have it. It contains three example images from the same field of view, the GUI (shown above) with field entries that result in the corresponding `log` and `Results`. Run the macro and input the information as shown. Press **OK**, and the macro should analyze each image and output a new log and Results window (which you will need to save after each run).
