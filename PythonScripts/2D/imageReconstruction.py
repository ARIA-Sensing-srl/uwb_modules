# *************************************************
# ARIA Sensing srl 2026
# Created on: 6 nov 2026
# *************************************************
import numpy as np
from scipy.interpolate import interp1d

def imageReconstruction(hradar,inputData, azimBase, rhoBase , algorithm):

    """
    Create an output image from radar streams.

    Parameters
    ----------
    hradar : types.SimpleNamespace
        Structure containing stream acquisition parameters.
    inputData : numpy.ndarray
        Stream input where every row represents a single stream.
    azimBase : array_like
        Reconstruction azimuth base.
    rhoBase : array_like
        Reconstruction distance base.
    algorithm : str
        Selected reconstruction algorithm. Options are: "DMAS", "DAS",
        "DMAS_SR", "DAS_SR".

    Returns
    -------
    output_image : numpy.ndarray
        The reconstructed radar image. rows: azimuth, colomns: rho.
    """

    if algorithm is None:
        algorithm = 'DAS'

    if algorithm == 'DAS':
        DASSelected = 1
        SREnabled = 0
    elif algorithm == 'DMAS':
        DASSelected = 0
        SREnabled = 0
    elif algorithm == 'DMAS_SR':
        DASSelected = 0
        SREnabled = 1
    elif algorithm == 'DAS_SR':
        DASSelected = 1
        SREnabled = 1
    else:
        raise ValueError("Invalid algorithm type")

    # Apply fallback default configurations if input bases are missing or invalid.
    if azimBase is None or len(azimBase) == 0:
        azimBase = np.arange(-60, 60, 5) * np.pi / 180.0

    if rhoBase is None or len(rhoBase) == 0:
        rhoBase = np.arange(0, numSamples, 1) * (C0 / (2.0 * fadc))


    numStreams = inputData.shape[0]
    antennaSeq = hradar.TxRxCycle
    numCycles = antennaSeq.shape[2]
    if numStreams != numCycles:
        raise ValueError("Number of streams must match the antenna sequence description")

    # Definition of HW parameters and costants
    fadc = hradar.CoreFrequency
    fc = hradar.txCenterFrequency
    C0 = 299792458.0
    numSamples = inputData.shape[1]

    # Map creation
    Rr, Pp = np.meshgrid(rhoBase, azimBase, indexing='xy')
    YY = Rr * np.sin(Pp)
    ZZ = Rr * np.cos(Pp)
    XX = np.zeros_like(ZZ)

    # Final matrix
    outputImage = np.zeros_like(Rr, dtype=np.complex128)

    channelCombination = np.zeros((numCycles, 2))

    for N in range(numCycles):
        activeTx = np.sum(antennaSeq[0, :, N])
        activeRx = np.sum(antennaSeq[1, :, N])
        if (activeTx != 1) or (activeRx != 1):
            raise ValueError("Invalid Tx Rx scan combination")
        channelCombination[N, 0] = np.argmax(antennaSeq[0, :, N])
        channelCombination[N, 1] = np.argmax(antennaSeq[1, :, N])

    TxAntDelay = hradar.FixedTxToAntennaDelays
    RxAntDelay = hradar.FixedRxToAntennaDelays

    inputData_pad = np.hstack([inputData, np.zeros((numStreams, 1))]) #last index is used for out of bound condition

    #start cycling and reconstruction

    tbADC = np.arange(0, numSamples+1, 1)*1/fadc #base is numsamples
    maxTfly = max(tbADC)
    minTfly = min(tbADC)

    remapStorage = np.zeros((numCycles, YY.shape[0], YY.shape[1]), dtype=complex)

    for N in range(numCycles):
        # get antennas informations
        TxI = int(channelCombination[N, 0])
        RxI = int(channelCombination[N, 1])
        curTx = hradar.TxAntPosition[TxI, :]
        curRx = hradar.RxAntPosition[RxI, :]
        curStream = inputData_pad[N, :]

        # compute hw delay remapping
        curTxXX = XX - curTx[0]
        curTxYY = YY - curTx[1]
        curTxZZ = ZZ - curTx[2]

        curRxXX = XX - curRx[0]
        curRxYY = YY - curRx[1]
        curRxZZ = ZZ - curRx[2]

        # compute time of fly map
        tflyMap = (np.sqrt(curTxYY**2 + curTxZZ**2 + curTxXX**2) +
                np.sqrt(curRxYY**2 + curRxZZ**2 + curRxXX**2)) / C0

        # compensation of internal delaies
        tflyMap_comp = tflyMap + hradar.FixedTxToAntennaDelays[TxI] + hradar.FixedRxToAntennaDelays[RxI]
        # map for wave propagation
        loMap = np.exp(1j * 2 * np.pi * fc * tflyMap_comp)

        # elimination of out of bound value
        oob_map = tflyMap_comp > maxTfly
        oob_map = oob_map | (tflyMap_comp < minTfly)
        tflyMap_comp = np.where(oob_map, tbADC[-1], tflyMap_comp)


        interpolator = interp1d(tbADC, curStream, kind='linear', bounds_error=False, fill_value=0)
        proj = interpolator(tflyMap_comp) * loMap

        if DASSelected:
            outputImage += proj
        remapStorage[N, :, :] = proj

    if DASSelected == 0:
        #peform DMAS
        for a in range(numCycles - 1):
            curA = np.squeeze(remapStorage[a, :, :])
            for k in range(a + 1, numCycles):
                curB = np.squeeze(remapStorage[k, :, :])
                outputImage = outputImage + curA * np.conj(curB)
    else:
        outputImage = outputImage / numCycles # normalization

    if SREnabled == 1:
        # Coherence Factor
        with np.errstate(divide='ignore', invalid='ignore'):
            num = np.abs(np.sum(remapStorage, axis=0))**2
            den = numCycles * np.sum(np.abs(remapStorage)**2, axis=0)
            CF = np.where(den != 0, num / den, 0)
            CF = np.squeeze(CF)
        outputImage = outputImage * CF

    return outputImage

