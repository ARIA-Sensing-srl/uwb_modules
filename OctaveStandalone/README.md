# Octave Native

The folders contain scripts for Octave.

## Prerequisites


* **aria_uwb_toolbox** — Octave toolbox implementing communication and processing, required version > 2.0.0 (https://github.com/ARIA-Sensing-srl/ARIA_uwb_toolbox.git).

## Structure

* **2D** — Examples for 2D Series devices focused on image reconstruction and visualization.
  * `main_hydr_2d_embed` — Sets up the device and visualizes the 2D reconstructed image. The image is computed by the microcontroller. 
  * `main_hydr_2d_local` — Sets up the device and visualizes the 2D reconstructed image. The image is computed on the PC.
  * `configureDevice`, `setupLocalReconstruction` — Utility functions used in the scripts above for device configuration.

* **3D** — Examples for 3D Series devices focused on image reconstruction and visualization.
  * `main_hydr_3d_local` — Sets up the device and visualizes the 3D reconstructed image. The image is computed on the PC.
  * `configureDevice`, `setupLocalReconstruction` — Utility functions used in the scripts above for device configuration.
  
* **data acquisition 2D 3D** — Examples for 2D and 3D Series devices for visualize plot and data acquisition.
  * `main_hydr_acq2file` — Sets up the device, acquires data for a specified duration (in seconds), and stores it in a custom-named JSON file. 
  * `main_hydr_acqplot` — Sets up the device and visualizes real, imaginary, and envelope plots from the acquired data.
  * `configureDevice` — Utility function used in the scripts above for device configuration.

## Usage

Start the main scripts inside the Octave environment.

## Automatic serial port scan

Scripts implement initial device discovering by means of `openDevice` function<br>
Under Windows, if bluetooth-UART are present, autoscan fails and manual configuration of the serial port is required
```
board = openDevice('COM3', [])
```
Explicit serial port declaration is generally required if multiple devices are connected and connection to specific device is required
