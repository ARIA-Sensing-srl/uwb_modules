# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# This scripts configures the radar and requires acqusition periodically.
# Returned frames are plotted into a combined subplot graph (I/Q/abs)
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
        description="This scripts configures the radar and requires acqusition periodically. Returned frames are plotted into a combined subplot graph (I/Q/abs)"
    )
    parser.add_argument("-m", "--mode", required=False, type=str, default="UART", help="Type of communication (default UART)")
    parser.add_argument("-p", "--port", required=False, type=str, default=None, help="COM port")
    parser.add_argument("-b", "--baud", required=False, type=int, default=921600, help="Baud rate (default 921600)")
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

## USER PARAMETERS ###################################

config = types.SimpleNamespace()

config.RhoRange = [0.0, 5]
#config.iterations = 3000    #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1 #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0 #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0
config.profile=0
config.multistream=1 #number of acquisition for each data request
config.fps=20

## END PARAMETERS ####################################

# start radar initialization code ###########################

config = configureDevice(config,radar)
distbin = 1.5e8/config.fs
print("Configuration completed")

# end radar intialization code ############################

# First acquisition to find the dimensions of the matrix data
data = radar.rdr_rx_multichannel()
numR = data.shape[0]
numC = data.shape[1]

# Figure intialization

plt.ion()
fig, axes = plt.subplots(3, 1, figsize=(10, 8))
fs = radar.rdr_get_adcfreq() * 1e6
x = (np.arange(0, numC) * distbin) + config.RhoRange[0]

lines_sub = [[], [], []]

for i in range(3):
    ax = axes[i]
    for j in range(numR):
        line, = ax.plot(x, np.zeros(numC), label=f"Channel {j+1}")
        lines_sub[i].append(line)
    match i:
        case 0:
            ax.set_ylabel("Real")
        case 1:
            ax.set_ylabel("Imag")
        case 2:
            ax.set_ylabel("Envelope")
    ax.set_xlabel("Distance [m]")
    ax.grid(True, linestyle="--", alpha=0.6)
    ax.legend(loc="upper right")
plt.tight_layout()

limit = 5
count = 0
lastMax = 0
lastMaxUpdateCnt = 0

# Start continuous acquisition

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

            # Control of max
            curMax = np.max(np.abs(data))
            if curMax > lastMax:
                lastMax = curMax
                lastMaxUpdateCnt = 0
            elif np.abs(lastMax-curMax) < 0.1*lastMax:
                lastMaxUpdateCnt = 0
            else:
                lastMaxUpdateCnt += 1
                if lastMaxUpdateCnt > 10:
                    lastMax = lastMax/2
                    lastMaxUpdateCnt = 0
            if lastMax == 0:
                lastMax = 1.0

            # Update lines with new data
            for i in range(3):
                ax = axes[i]
                line = lines_sub[i]
                for j in range(numR):
                    match i:
                        case 0:
                            line[j].set_ydata(np.real(data[j, :]))
                        case 1:
                            line[j].set_ydata(np.imag(data[j, :]))
                        case 2:
                            line[j].set_ydata(np.abs(data[j, :]))

                ax.set_ylim(-lastMax, lastMax)

            # Redraw the plots
            fig.canvas.draw()
            fig.canvas.flush_events()
            time.sleep(0.005)
            count = 0
        except Exception:
            count += 1

        if count > limit:
            print("Exit for fail")
            radar.rdr_stop()
            break

except KeyboardInterrupt:
    print("\nAcquisition interrupted by the user.")
finally:
    plt.ioff()
    plt.show()
    radar.rdr_stop()
