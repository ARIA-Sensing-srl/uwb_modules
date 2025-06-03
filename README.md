# uwb_modules
Official Collection of UWB Radar Modules definition for ARIA-RDK
This includes:
The new emPulse familiy and the current product line:

1. LT102V2
2. LT103OEM
3. AHM3D
4. AHM2D
5. AHM2DSC
6. AHM2DL

the modules_xD folders contain the *.arm ("Aria radar module") definitions. This files must be included into the project file to communicate with the device

1. modules_1D
	LT102V2
	LT103OEM

2. modules_2D
	AHM2D
	AHM2DSC
	AHM2DL
3. modules_3D
	AHM3D.
	
The folders modules_xD/OctaveScripts contain scripts for native Octave environment (require aria_uwb_toolbox version >= 0.1.1)

The folder ARIA_RDK_template contains example projects for acquire data from the modules (image or raw)

.ARIA_RDK_template/AHM2D
Setups the device and gets the 2D reconstructed image into "output_image" variable. The image is computed by the microcontroller.
	ahm2d_init: setup the device (user can range and acquistion parameters here)
	init_2D_embed: additional init procedure, setup the device for execute image build into microcontroller
	read_image: get the recontructed image 
	
.ARIA_RDK_template/AHM2DL
Setups the device and gets the 2D reconstructed image into "output_image" variable. The image is computed by the microcontroller.
	ahm2dl_init: setup the device (user can range and acquistion parameters here)
	init_2D_embed: additional init procedure, setup the device for execute image build into microcontroller
	read_image: get the recontructed image 
	
.ARIA_RDK_template/AHM2D_local
Setups the device and gets the 2D reconstructed image into "output_image" variable. The image is computed on PC.
Partially processed data (antenna polarity correction) are stored into "output_data_final". 
	ahm2d_init: setup the device (user can range and acquistion parameters here)
	init_2D_local_reconstruction: additional init procedure, setup the device for execute image build locally (PC). User can modifiy recontruction range here.
	read_raw_data: get one stream for each antenna pair and compensates the antenna polariy
	reconstruct_image: combine the streams to get the output image	

.ARIA_RDK_template/AHM2DL_local
Setups the device and gets the 2D reconstructed image into "output_image" variable. The image is computed on PC.
Partially processed data (antenna polarity correction) are stored into "output_data_final". 
	ahm2dl_init: setup the device (user can range and acquistion parameters here)
	init_2D_local_reconstruction: additional init procedure, setup the device for execute image build locally (PC). User can modifiy recontruction range here.
	read_raw_data: get one stream for each antenna pair and compensates the antenna polariy
	reconstruct_image: combine the streams to get the output image

.ARIA_RDK_template/AHM2DSC
Setups the device and gets the 2D reconstructed image into "output_image" variable. The image is computed by the microcontroller.
	ahm2dsc_init: setup the device (user can range and acquistion parameters here)
	init_2D_embed: additional init procedure, setup the device for execute image build into microcontroller
	read_image: get the recontructed image 

.ARIA_RDK_template/AHM2DSC_local
Setups the device and gets the 2D reconstructed image into "output_image" variable. The image is computed on PC.
Partially processed data (antenna polarity correction) are stored into "output_data_final". 
	ahm2dsc_init: setup the device (user can range and acquistion parameters here)
	init_2D_local_reconstruction: additional init procedure, setup the device for execute image build locally (PC). User can modifiy recontruction range here.
	read_raw_data: get one stream for each antenna pair and compensates the antenna polariy
	reconstruct_image: combine the streams to get the output image

.ARIA_RDK_template/AHM3D_local
Setups the device and gets the 2D reconstructed image into "output_volume" variable. The volume is computed on PC.
Partially processed data (antenna polarity correction) are stored into "output_data_final". 
	ahm3d_init: setup the device (user can range and acquistion parameters here)
	init_3D_local_reconstruction: additional init procedure, setup the device for execute image build locally (PC). User can modifiy recontruction range here.
	read_raw_data: get one stream for each antenna pair and compensates the antenna polariy
	reconstruct_volume: combine the streams to get the output volume
	3d_max2d_split: auxiliary script, used only for visualization purpose, search for the max amplitude inside the volume and generate two 2D image (one plane parallel to X-Y plane and one parallel to Y-Z plane). The two planes cross the point where the maximum amplitude is detected.


   
