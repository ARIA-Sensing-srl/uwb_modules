# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# *************************************************
"""
This scripts configures the device, acquires data according to used-defined time and store into a json file
Without live plots, acquisition rate is faster and allow data collection at high frame rate settings
Actual frame rate could be affected by many parameters (number of streams, iterations, etc.)

OUTPUT JSON FILE STRUCTURE

This script generates a JSON file with radar configuration information and data.
Each file contains a metadata header and a list of sequential frames,
where each frame stores a matrix with timestamp, real part of data matrix and the imaginary.

Structure Example:
{
    "metadata": {
        "hwcode": 41681,
        "bandwidth": 1332,
        "offset": -0.44999998807907104,
        ...
    },
    "frames": [
        {
            "timestamp": "2026-11-05T11:10:15.160334",
            "real": [[0.1, 0.2], [0.3, 0.4] ...],
            "imag": [[-0.5, 0.6], [0.1, -0.2] ...]
        },
        {
            "timestamp": "2026-11-05T11:10:15.200334",
            "real": [[0.5, 0.6], [0.7, 0.8] ...],
            "imag": [[-0.1, 0.3], [0.4, -0.5] ...]
        }
    ]
}
"""

import AHMAPIpy as m
import serial.tools.list_ports
import argparse
import string
import sys
import platform
import matplotlib.pyplot as plt
import numpy as np
import time
from types import SimpleNamespace
import json
from configureDevice import configureDevice
import datetime as dt



if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="This scripts configures the device, acquires data according to used-defined time and store into a json file"
    )
    parser.add_argument("-m", "--mode", required=False, type=str, default="UART", help="Type of communication (default UART)")
    parser.add_argument("-p", "--port", required=False, type=str, default=None, help="COM port")
    parser.add_argument("-b", "--baud", required=False, type=int, default=921600, help="Baud rate (default 921600)")
    parser.add_argument("-t", "--time", required=False, type=float, default=10.0, help="Acquisition time in seconds (default 10 s)")
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
    sys.exit()

## USER PARAMETERS ###################################

config = SimpleNamespace()

config.RhoRange = [0.0, 5]
config.iterations = 3000              #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 0             #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0      #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0
config.profile=0
config.fps=50
config.multistream = 8     #packed mode: this parameter set the number of acquisition to pack for each data request, this option speeds up the acquisition rate
config.elab = 0           #collect data without any elaboration


# UNCOMMENT THIS SECTION IF USER-PROVIDED sequence is required
"""
scan_sequence = np.array([[1, 1],[1, 2]]) #every row set tx and rx antenna for each stream [tx_stream0 rx_stream0; tx_stream1 rx_stream1; etc...]
##                            #see AHMx datasheet for antenna to channel mapping
def antSequence2TxRxMap(scan_sequence):

    rxMask = np.array([], dtype=int)
    txMask = np.array([], dtype=int)

    scan_sequence = np.asarray(scan_sequence)

    if scan_sequence.shape[0] > 16:
        raise ValueError("Max supported sequence are 16")

    if scan_sequence.ndim != 2 or scan_sequence.shape[1] != 2:
        raise ValueError("Input array must have 2 columns")

    scan_sequence = np.round(scan_sequence).astype(int)

    if np.any(scan_sequence > 3) or np.any(scan_sequence < 0):
        raise ValueError("Invalid encoding")

    rxMask = 2**scan_sequence[:, 1].T
    txMask = 2**scan_sequence[:, 0].T
    print(rxMask)
    print(txMask)

    return int(txMask[0].item()), int(rxMask[0].item()), rxMask[0]
[config.rxMask, config.txMask, config.numS] = antSequence2TxRxMap(scan_sequence)
"""

## END PARAMETERS ####################################

#start radar initialization code###########################

acqTime = args.time

config = configureDevice(config,radar)
distbin = 1.5e8/config.fs
print("Configuration completed")

#end radar intialization code############################

limit = 5
count = 0
real_matrices = []
imag_matrices = []
dt_timestamps = []
elapsed = 0
last_updated_val = -1

# Continuous acquisition
print(f"Start acquisition for {acqTime} s. Press CTRL+C to stop early.")
dt_timestamps.append(dt.datetime.now()) # get current time and date
start_timestamp  = time.time() # get current time

try:
    while elapsed < acqTime:
        try:
            data = radar.rdr_rx_multichannel()
            dt_timestamps.append(dt.datetime.now())
            elapsed = time.time() - start_timestamp
            real_matrices.append(data.real)
            imag_matrices.append(data.imag)
            cur_per = round(10 * elapsed / acqTime)
            if cur_per < 100:
                if cur_per != last_updated_val:
                    last_updated_val = cur_per
                    print(f"{cur_per*10}%")
            else:
                print("100%")
        except Exception:
            count += 1

        if count > limit:
            print("Exit for fail")
            radar.rdr_stop()
            break

except KeyboardInterrupt:
    print("Acquisition interrupted by the user.")
finally:
    radar.rdr_stop()

tot_acquisitions = len(real_matrices)*config.multistream
equiv_frame_rate = tot_acquisitions/elapsed
print(f"Number of aquisition: {tot_acquisitions}")
print(f"Average frame rate {equiv_frame_rate}")

# Creation of a dictionary, required to save radar configure information and data

if tot_acquisitions > 0:

    metadata = vars(config).copy()
    metadata["tot_acquisitions"] = tot_acquisitions
    metadata["avg_frame_rate"] = equiv_frame_rate
    metadata["start_time_iso"] = dt_timestamps[0].isoformat()
    metadata["end_time_iso"] = dt_timestamps[-1].isoformat()

    json_structure = {
        "metadata": metadata,
        "frames": []
    }

    unpacked_real_matrix = []
    unpacked_real_matrix = []

    for ts, r_mat, i_mat in zip(dt_timestamps, real_matrices, imag_matrices):
        for i in range(config.multistream):
            correct_td_timeStamp = ts + dt.timedelta(seconds=i*config.multistream/config.fps)
            real_sf_matrix = r_mat[i:i+4, :]
            imag_sf_matrix = i_mat[i:i+4, :]
            matrix_to_save = {
                "timestamp": correct_td_timeStamp.isoformat(),
                "real": real_sf_matrix.tolist(),
                "imag": imag_sf_matrix.tolist()
            }
            json_structure["frames"].append(matrix_to_save)

    # Need it because some parameter in config are not serializable
    def json_fallback(obj):
        try:
            return str(obj)
        except Exception:
            return f"Non-serializable object ({obj.__class__.__name__})"

    file_name = input("Enter the file name: ")
    file_name = file_name.strip()

    if not file_name.endswith(".json"):
        file_name += ".json"

    with open(file_name, "w") as f:
        json.dump(json_structure, f, indent=4, default=json_fallback)

    print(f"File {file_name} created.")
else:
    print("Something went wrong. No data acquired.")
