# PythonScripts

The folders contain scripts for native Python environment.

## Prerequisites

This project requires **Python 3.12+** and the following third-party libraries: <!-- Ho messo la versione di python che sto usando io -->

* **AHMAPIpy** — Proprietary library for the AHM API (Provided directly by us; please follow the instructions in the dedicated section).
* **pyserial** — For serial communication with devices (pip install pyserial).
* **matplotlib** — For data visualization and plotting (pip install matplotlib).
* **numpy** — For numerical computing and array manipulation (pip install numpy).
* **scipy** — For scientific computing and interpolation (pip install scipy).

## Structure

* **2D** — Examples for 2D Series devices focused on image reconstruction and visualization.
  * `main_hydr_2d_embed.py` — Sets up the device and visualizes the 2D reconstructed image. The image is computed by the microcontroller. 
  * `main_hydr_2d_local.py` — Sets up the device and visualizes the 2D reconstructed image. The image is computed on the PC.
  * `configureDevice.py`, `setupLocalReconstruction.py`, `imageReconstruction.py` — Utility functions used in the scripts above for device configuration and image reconstruction algorithms.

* **3D** — Examples for 3D Series devices focused on image reconstruction and visualization.
  * `main_hydr_3d_local.py` — Sets up the device and visualizes the 3D reconstructed image. The image is computed on the PC.
  * `configureDevice.py`, `setupLocalReconstruction.py`, `imageReconstruction3D.py` — Utility functions used in the scripts above for device configuration and image reconstruction algorithms.
  
* **data acquisition 2D 3D** — Examples for 2D and 3D Series devices for visualize plot and data acquisition.
  * `main_hydr_acq2file.py` — Sets up the device, acquires data for a specified duration (in seconds), and stores it in a custom-named JSON file. 
  * `main_hydr_acqplot.py` — Sets up the device and visualizes real, imaginary, and envelope plots from the acquired data.
  * `configureDevice.py` — Utility function used in the scripts above for device configuration.

## Usage

Each main script is designed to be executed via the command line. They all support command-line arguments to customize execution. If the argument is not provide the script will use its predefined default values.

You can pass the following options to any main script:

| Short | Long | Type | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-m` | `--mode` | `str` | `"UART"` | Type of communication interface. |
| `-p` | `--port` | `str` | `None` | The specific COM/serial port. If left as `None`, the script will automatically scan and select an available port. |
| `-b` | `--baud` | `int` | `921600` | Baud rate for the serial communication. |
| `-t` | `--time` | `float` | `10.0` | **(`main_hydr_acq2file.py` only)** Acquisition time in seconds. |

## Exemples

Navigate to the directory containing the file you want to run, then start the execution:

**Running with automatic port detection (default):**
```bash
python main_hydr_2d_local.py
```

**Specifying a specific serial port (Linux) and duration:**
```bash
python main_hydr_2d_local.py -p /dev/ttyUSB0 -t 1
```



