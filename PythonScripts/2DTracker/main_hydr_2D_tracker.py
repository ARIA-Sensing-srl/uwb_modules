# *************************************************
# ARIA Sensing srl 2024
# The script configures and enables the tracker algorithm implemented for 2D series devices.
# Output is the position of the target and estimated speed
# Only 2D devices are supported (AHM2DL, AHM2DSC, AHM2D)
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
from configureDevice_tracker import configureDevice_tracker
from matplotlib.patches import Ellipse
import math

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script that adds 3 numbers from CMD"
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

##USER PARAMETERS###################################

config = SimpleNamespace()
config.canvasData = m.canvas2d_param() # Instantiate CanvasData from module AHMAPIpy before configuring its properties

xmax = 4  #max detection range
config.RhoRange = [-0.5, xmax] #acquisition downrange settings (meters)
config.iterations = 8000  #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1  #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 40.0 #time constant to update static object mapping
config.profile=0
config.multistream=1  #number of acquisition for each data request
config.fps=20 #frame rate
config.rxgain=5
config.canvasData.algo = 1  #image reconstruction algorithm (0: DAS, 1: DMAS)
config.canvasData.rhoMin = 0.2  #reconstruction min downrange
config.canvasData.rhoStep = 0.15  #reconstruction step downrange
config.canvasData.rhoMax = xmax #reconstruction max downrange
config.canvasData.phiMin = -60  #crossrange min angle
config.canvasData.phiStep = 5 #crossrange step angle
config.canvasData.phiMax = 60 #crossrange max angle

disable_ID = 0             #display trace ID
plot_speed = 1             #display speed arrow
axisLimit = [-1.5, 1.5, 0, 6.5] #axis limit for 2D plot (meters)

SNRs = [60, 40, 3.0, 3.0]      #range thresholds (absolute values)
SNRRanges = [0.8, 1.2, 3.5] #range distange for range profile (meters)

##END PARAMETERS####################################

#start radar intialization code###########################


config = configureDevice_tracker(config, radar)

#additional configuration
#set SNRs
if SNRs is None or len(SNRs) == 0:
  print("Error: you need to set SRNs. See USER PARAMETERS.")
  sys.exit()
else:
  radar.rdr_set_SNRs(SNRs)
  radar.rdr_get_SNRs()
  print(f"SNRs: {SNRs}")

#set SNRsran ranges
if SNRRanges is None or len(SNRRanges) == 0:
  print("Error: you need to set SNRRanges. See USER PARAMETERS.")
  sys.exit()
else:
  radar.rdr_set_SNRranges(SNRRanges)
  radar.rdr_get_SNRranges()
  print(f"SNRRanges: {SNRRanges}")


#get/set kalman parameters
kalman_par = radar.rdr_get_kalman2D()
kalman_par.gateInTicks = 10
kalman_par.acc_unc = 0.25
kalman_par = radar.rdr_set_kalman2D(kalman_par)

#end radar intialization code############################

# Continuous acquisition

count = 0
limit = 5
H = np.array([[1, 0, 0, 0], [0, 0, 1, 0]], dtype=np.float32)


fig, ax = plt.subplots()
ax.set_xlim(axisLimit[0], axisLimit[1])
ax.set_ylim(axisLimit[2], axisLimit[3])

print("Continuous acquisition begun. Press CTRL+C or close the plot window to interrupt.")
try:
    while True:
        if not plt.fignum_exists(fig.number):
            radar.rdr_stop()
            print("\nPlot window closed by user.")
            break
        try:
            # New acquisition
            detOut, detFullState = radar.rdr_get_detection2D_pos_full(False)
            ax.clear()
            ax.plot(detOut[:, 0], detOut[:, 1], '.r', markersize=10)

            for n in range(len(detFullState)):
              curSV = detFullState[n].sv
              curP = detFullState[n].P
              S = np.linalg.inv(H @ curP @ H.T)
              rot = 0.5 * math.atan2((S[0][1] + S[1][0]), (S[0][0] - S[1][1]))
              T = np.linalg.inv(np.array([[np.cos(rot), np.sin(rot)],[-np.sin(rot), np.cos(rot)]])**2)
              o = T @ np.array([S[0, 0], S[1, 1]])
              Ra = np.sqrt(1/o[0])
              Rb = np.sqrt(1/o[1])
              ellipse = Ellipse(
                  xy=(curSV[0], curSV[2]),
                  width=2 * Rb,
                  height=2 * Ra,
                  angle=rot * 180 / math.pi,
                  edgecolor='blue',
                  facecolor='none',
                  linewidth=3
              )
              ax.add_patch(ellipse)
              out_string = f"{int(detOut[n, 2])}"
              if disable_ID == 0:
                ax.text(detOut[n, 0] + 0.1, detOut[n, 1], out_string, fontsize=15)

              if plot_speed == 1:
                ax.quiver(curSV[0], curSV[2], curSV[1], curSV[3], angles='xy', scale_units='xy', scale=1, linewidth=1, width=0.004, headwidth=3, headlength=4)

            ax.set_xlim(axisLimit[0], axisLimit[1])
            ax.set_ylim(axisLimit[2], axisLimit[3])

            plt.draw()
            plt.pause(0.005)

            count = 0
        except Exception as e:
            print(f"Error: {e}")
            count += 1

        if count > limit:
            print("Exit for fail");
            radar.rdr_stop()
            break

except KeyboardInterrupt:
    print("\nAcquisition interrupted by the user.")
finally:
    radar.rdr_stop()





