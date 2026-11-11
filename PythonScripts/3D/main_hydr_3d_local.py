# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# The script configures the radar, and implements the beamforming algorithm locally,
# searches for the maximum amplitude and extracts two slicing planes YZ and XY crossing the point of maximum amplitude
# *************************************************

import AHMAPIpy as m
import serial
import serial.tools.list_ports
import argparse
import string
import sys
import platform
import matplotlib.pyplot as plt
import numpy as np
from pynput import keyboard
import time
from types import SimpleNamespace
from configureDevice import configureDevice
from setupLocalReconstruction import setupLocalReconstruction
from imageReconstruction3D import imageReconstruction3D

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="The script configures the radar, and implements the beamforming algorithm locally, searches for the maximum amplitude and extracts two slicing planes YZ and XY crossing the point of maximum amplitude."
    )
    parser.add_argument("-m", "--mode", required=False, type=str, default="UART", help="Type of communication (default UART)")
    parser.add_argument("-p", "--port", required=False, type=str, default=None, help="COM port")
    parser.add_argument("-b", "--baud", required=False, type=int, default=921600, help="Baud rate default (default 921600)")
    args = parser.parse_args()

# Try to find the connected serial port
available_port = None
if args.port is None:
    ports = serial.tools.list_ports.comports()
    for i in ports:
        if platform.system() != "Windows" and "ttyS" in i.device:
            continue
        try:
            deviceName = i.device
            if platform.system() == "Windows":
                deviceName = "\\\\.\\" + deviceName
            available_port = deviceName
            radar = m.RadarHandler(serial_comunication=args.mode, COM=available_port, BR=args.baud)
            print("Port found")
            break
        except:
            available_port = None
            pass
else:
    try:
        radar = m.RadarHandler(serial_comunication=args.mode, COM=args.port, BR=args.baud)
        available_port = args.port
    except:
        pass

if available_port is None:
    print("Error: port not found")
    sys.exit(1)

##CONFIGURE PARAMETERS####################################

config = SimpleNamespace()

config.algo="DMAS_SR"     #select the algorithm used for reconstruction DAS, DMAS, DAS_SR, DMAS_SR
config.RhoStep = 0.05                #Downrange resolution in meters
config.RhoRange = [1.0, 5.0]          #Downrange span in meters
config.AzimStep = 5 * np.pi/180         #Azimuth angular reconstruction resolution in radiants
config.AzimRange = np.array([-45, 45]) * np.pi/180   #Angular span in radiants
config.ElevRange = np.array([-45, 45]) * np.pi/180   # Elevation angular reconstruction resolution in radiants
config.ElevStep = 5 * np.pi/180

# config.iterations = []  #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1 #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0 #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0
config.multistream=1 #number of acquisition for each data request
config.profile=0
config.fps=20

##END PARAMETERS####################################


config = configureDevice(config, radar)

rhoBase = np.arange(config.RhoRange[0], config.RhoRange[1] + config.RhoStep, config.RhoStep)
azimBase = np.arange(config.AzimRange[0], config.AzimRange[1] + config.AzimStep, config.AzimStep)
zenBase = np.arange(np.radians(np.degrees(config.ElevRange[1])+90), np.radians(np.degrees(config.ElevRange[0]+90)) + config.ElevStep, -config.ElevStep)

distbin = 1.5e8 / config.fs

hradar, AmplCorrection = setupLocalReconstruction(config, radar)

if hradar is None or (
    isinstance(hradar, (list, np.ndarray)) and len(hradar) == 0
):
    print("Error on local reconstruction setup", file=sys.stderr)
    sys.exit()


#end radar intialization code############################

# Continuous acquisition
count = 0
limit = 5
# First acquisition to set the figure
fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(12, 4))
data = radar.rdr_rx_multichannel()

extent_yz = [np.degrees(azimBase).min(), np.degrees(azimBase).max(), np.degrees(config.ElevRange).min(), np.degrees(config.ElevRange).max()]
extent_xy = [np.degrees(azimBase).min(), np.degrees(azimBase).max(), rhoBase.min(), rhoBase.max()]
print(extent_xy)

imageR = imageReconstruction3D(hradar, data, zenBase, azimBase, rhoBase, config.algo)
temp_ind = np.argmax(imageR)
x_max, y_max, z_max = np.unravel_index(temp_ind, imageR.shape)
imgMax = imageR[x_max, :, :]
img2d = imageR[:, :, z_max]

img_yz = axes[0].imshow(np.abs(imgMax), extent=extent_yz, aspect='auto', origin='lower', cmap='turbo')
axes[0].set_title('YZ plane')
axes[0].set_xlabel('Azimuth')
axes[0].set_ylabel('Elevation')
img_xy = axes[1].imshow(np.abs(img2d), extent=extent_xy, aspect='auto', origin='lower', cmap='turbo')
axes[1].set_title('XY plane')
axes[1].set_ylabel('Rho')
axes[1].set_xlabel('Azimuth')
line_xy = axes[1].axhline(y=rhoBase.min(), color='r', linewidth=2)

plt.ion()
plt.draw()
print("Continuous acquisition begun. Press CTRL+C or close the plot window to interrupt.")
try:
    while True:
        if not plt.fignum_exists(fig.number):
            radar.rdr_stop()
            print("\nPlot window closed by user.")
            break
        try:
            # New acquisition
            data = radar.rdr_rx_multichannel()

            for N in range(len(AmplCorrection)):
                data[N,:] = data[N,:] * AmplCorrection[N]

            imageR = imageReconstruction3D(hradar, data, zenBase, azimBase, rhoBase, config.algo)

            if config.algo == "DMAS" or config.algo == "DMAS_SR":
                output_volume = np.real(imageR)
            else:
                output_volume  = np.abs(imageR)

            temp_ind = np.argmax(output_volume)
            x_max, y_max, z_max = np.unravel_index(temp_ind, output_volume.shape)
            max_x = rhoBase[x_max]

            imgMax = output_volume[x_max, :, :]
            img2d = output_volume[:, :, z_max]

            img_yz.set_data(imgMax.T)
            img_yz.set_clim(vmin=0, vmax=np.max(imgMax))

            img_xy.set_data(img2d)
            img_xy.set_clim(vmin=0, vmax=np.max(img2d))

            line_xy.set_ydata([max_x, max_x])
            axes[1].figure.canvas.draw_idle()

            plt.pause(0.005)

            count = 0
        except Exception:
            count += 1

        if count > limit:
            print("Exit for fail");
            radar.rdr_stop()
            break

except KeyboardInterrupt:
    print("\nAcquisition interrupted by the user.")
finally:
    plt.ioff()
    radar.rdr_stop()





