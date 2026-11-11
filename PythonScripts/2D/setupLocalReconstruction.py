# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# *************************************************
import numpy as np
import types

def setupLocalReconstruction(config,radar):

  """
    Create radar configuration variables required for image reconstruction.

    Parameters
    ----------
    config : types.SimpleNamespace
        Structure containing the parameters of the radar that needs to be configured.
    radar : AHMAPIpy.RadarHandler
        Radar handler instance from the AHMAPIpy module.

    Returns
    -------
    hradar : types.SimpleNamespace
        Structure containing stream acquisition parameters:

        - CoreFrequency (float): ADC sampling rate.
        - txCenterFrequency (float): Carrier frequency.
        - FixedTxToAntennaDelays (array_like): Array with transmitter
          antenna delay compensation (s).
        - FixedRxToAntennaDelays (array_like): Array with receiver
          antenna delay compensation (s).
        - TxAntPosition (numpy.ndarray): Array with antenna positions
          of shape (N, 3) as [x, y, z].
        - RxAntPosition (numpy.ndarray): Array with antenna positions
          of shape (M, 3) as [x, y, z].
        - TxRxCycle (numpy.ndarray): Array containing the active antenna
          matrix for each acquisition cycle of shape (2, NumAntennas, NumCycles).
    AmplCorrection : numpy.ndarray
        Array containing amplitude for phase correction information.
    """

  hradar = types.SimpleNamespace()
  AmplCorrection = []

  #Setup data for local algorithm reconstruction
  AntennaTx = np.zeros((4, 3))
  AntennaRx = np.zeros((4, 3))
  AntennaDelayTx = np.zeros(4)
  AntennaDelayRx = np.zeros(4)
  AntennaAmplTx = np.zeros(4)
  AntennaAmplRx = np.zeros(4)


  for N in range(0, 4):
    AntennaRx[N, :] = [0, config.rxAntDesc.ant[N].x, config.rxAntDesc.ant[N].y]
    AntennaTx[N, :] = [0, config.txAntDesc.ant[N].x, config.txAntDesc.ant[N].y]
    AntennaDelayTx[N] = config.txAntDesc.ant[N].delay_s
    AntennaDelayRx[N] = config.rxAntDesc.ant[N].delay_s
    AntennaAmplTx[N] = config.txAntDesc.ant[N].ampl
    AntennaAmplRx[N] = config.rxAntDesc.ant[N].ampl


  scan_sequence = np.log2((config.txMask, config.rxMask)).T
  numSeq = scan_sequence.shape[0]
  scan_sequence = scan_sequence.astype(int)
  hradar.TxRxCycle = np.zeros((2, 4, numSeq))
  for k in range(numSeq):
    hradar.TxRxCycle[0, scan_sequence[k, 0], k] = 1
    hradar.TxRxCycle[1, scan_sequence[k, 1], k] = 1


  AmplCorrection = np.zeros(scan_sequence.shape[0])
  for N in range(0, len(AmplCorrection)):
    AmplCorrection[N] = AntennaAmplTx[scan_sequence[N,0]]*AntennaAmplRx[scan_sequence[N,1]]

  hradar.CoreFrequency = config.fs
  hradar.txCenterFrequency = config.fcarrier
  hradar.TxAntPosition = AntennaTx
  hradar.RxAntPosition = AntennaRx
  hradar.FixedTxToAntennaDelays = AntennaDelayTx
  hradar.FixedRxToAntennaDelays = AntennaDelayRx
  NumTx = AntennaTx.shape[0]
  NumRx = AntennaRx.shape[0]

  hradar.FixedTxToAntennaDelays = hradar.FixedTxToAntennaDelays - config.RhoRange[0]*2/3e8

  return hradar, AmplCorrection
