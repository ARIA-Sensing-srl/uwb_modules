# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# This script configures the radar and execute the beamforming algorithm locally
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
import time
from types import SimpleNamespace
from configureDevice import configureDevice
from setupLocalReconstruction import setupLocalReconstruction
from imageReconstruction import imageReconstruction

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="This script configures the radar and execute the beamforming algorithm locally"
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
            available_port = i.device
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
    sys.exit()

##CONFIGURE PARAMETERS####################################

config = SimpleNamespace()

config.algo="DMAS_SR"   #select the algorithm used for reconstruction DAS, DMAS, DAS_SR, DMAS_SR
config.RhoStep = 0.05                 #Downrange resolution in meters
config.RhoRange = [1, 5.0]             #Downrange span in meters
config.AzimStep = 5 * np.pi/180        #Angular reconstruction resolution in radiants
config.AzimRange = np.array([-45, 45]) * np.pi/180 #Angular span in radiants

# config.iterations = []  #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1 #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0 #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0
config.profile=0
config.multistream=1 #number of acquisition for each data request
config.fps=20

##END PARAMETERS####################################

# Start radar initialization code############################

config = configureDevice(config, radar)

rhoBase = np.arange(config.RhoRange[0], config.RhoRange[1]+config.RhoStep, config.RhoStep)
azimBase = np.arange(config.AzimRange[0], config.AzimRange[1]+config.AzimStep, config.AzimStep)

distbin = 1.5e8 / config.fs

hradar, AmplCorrection = setupLocalReconstruction(config, radar)

if hradar is None or len(vars(hradar)) == 0:
    print("Error on local reconstruction setup")
    sys.exit()

# end radar initialization code############################

# Continuous acquisition

count = 0
limit = 5

# First acquisition to set the figure
fig, ax = plt.subplots()
data = radar.rdr_rx_multichannel()

extent = [np.degrees(azimBase).min(), np.degrees(azimBase).max(), rhoBase.min(), rhoBase.max()]

imageR = imageReconstruction(hradar, data, azimBase, rhoBase, config.algo)
img = ax.imshow(np.abs(imageR.T), extent = extent, origin='lower', aspect='auto', cmap='turbo')
ax.set_xlabel('Azimut')
ax.set_ylabel('Rho')

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

            imageR = imageReconstruction(hradar, data, azimBase, rhoBase, config.algo)

            if config.algo == "DMAS" or config.algo == "DMAS_SR":
                output_image  = np.real(imageR)
            else:
                output_image  = np.abs(imageR)

            img.set_data(output_image.T)
            img.set_clim(0, vmax=np.max(output_image))

            plt.draw()
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
    radar.rdr_stop()
