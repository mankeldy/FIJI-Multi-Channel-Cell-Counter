# FIJI Multi-Channel-Cell-Counter
 
The FIJI Multi-Channel-Cell-Counter macro strings together multiple FIJI plugins in series to automatically processes multi-channel microscopy images. For each field of view, images for each channel are opened based on the filename substring and the desired thresholds are applied. If a general cell counterstain was applied to the sample (e.g. DAPI, SybrGreen, etc.), this image is analyzed first; a watershed is applied (*Process>Binary>Watershed*) to seperate cell aggregates and particles are analyzed (*Analyze>Analyze Particles*). These particle regions are redirected to each subsequent channel and the desired data is output (*Analyze>Set Measurements*). If a counterstain was not used in the experiment, then each channel is analyzed this way independently.

# Getting started:

To run the macro, in FIJI go to *Plugins>Macro>Run* and select `multi-channel-cell-counter.ijm`. You may also go to *Plugins>Macro>Edit* and open the macro that way so that it can be run directly from that window instead.

#

# Tutorial
