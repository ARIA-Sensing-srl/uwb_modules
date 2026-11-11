# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# This script configures the device and get the image reconstructed by the module
# *************************************************

import AHMAPIpy as m
import serial.tools.list_ports
import argparse
import string
import sys
import platform
import matplotlib.pyplot as plt
import numpy as np
import time
import types
from configureDevice import configureDevice

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="This script configures the device and get the image reconstructed by the module"
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

## USER PARAMETERS ####################################

config = types.SimpleNamespace()

config.RhoStep = 0.1   #Downrange resolution in meters
config.RhoRange = [0, 7.0]             #Downrange span in meters
config.AzimStep = 5 * np.pi/180            #Angular reconstruction resolution in radiants
config.AzimRange = np.array([-45, 45]) * np.pi/180   #Angular span in radiants
# config.iterations = []  #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1 #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0 #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 1
config.profile=0
config.multistream=1 #number of acquisition for each data request
config.fps=20

##END PARAMETERS####################################

#start radar initialization code###########################

compatible_codes = {int("a2d0", 16), int("a2d1", 16), int("a2d5", 16)}

#setup canvas
config.canvasData = m.canvas2d_param() # Instantiate CanvasData from module AHMAPIpy before configuring its properties
config.canvasData.algo = 1
config.canvasData.rhoMin = config.RhoRange[0]
config.canvasData.rhoStep = config.RhoStep
config.canvasData.rhoMax = config.RhoRange[1]
config.canvasData.phiMin = config.AzimRange[0]*180/np.pi
config.canvasData.phiStep= config.AzimStep*180/np.pi
config.canvasData.phiMax = config.AzimRange[1]*180/np.pi

config = configureDevice(config,radar)

distbin = 1.5e8/config.fs
print("Configuration completed")

if config.hwcode not in compatible_codes:
    print(f"Error: HW is not supported. Hardware code: {hex(config.hwcode)}")
    sys.exit()

#end radar intialization code############################

count = 0
limit = 5

# First acquisition to set the figure
plt.ion()
fig, ax = plt.subplots()
data = radar.rdr_get_image()
numRho = data.shape[0]
numAzim = data.shape[1]

rhoBase = np.arange(config.RhoRange[0], config.RhoRange[1]+config.RhoStep, config.RhoStep)
azimBase = np.arange(config.AzimRange[0], config.AzimRange[1]+config.AzimStep, config.AzimStep)
extent = [np.degrees(azimBase.min()), np.degrees(azimBase.max()), rhoBase.min(), rhoBase.max()]

# Note: data.T is need it for visualization
img = ax.imshow(abs(data).T, extent=extent, aspect='auto', origin='lower', cmap='viridis')
ax.set_xlabel('Azimut')
ax.set_ylabel('Rho')

print("Continuous acquisition begun. Press CTRL+C to interrupt.")
try:
    while True:
        if not plt.fignum_exists(fig.number):
            radar.rdr_stop()
            print("\nPlot window closed by user.")
            break
        try:
            # New acquisition
            imageR = radar.rdr_get_image()

            img.set_data(imageR.T)
            img.set_clim(vmin=imageR.min(), vmax=imageR.max())

            plt.pause(0.005)

            count = 0
        except Exception:
            count += 1

        if count > limit:
            print("\nExit for fail")
            plt.ioff()
            radar.rdr_stop()
            break

except KeyboardInterrupt:
    print("\nAcquisition interrupted by the user.")
finally:
    plt.ioff()
    radar.rdr_stop()
