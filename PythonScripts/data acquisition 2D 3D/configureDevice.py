import time

def configureDevice (config, radar):

  """
    Configure the radar device parameters using the provided configuration.

    Parameters
    ----------
    config : types.SimpleNamespace
        Structure containing the parameters of the radar that needs to be configured.
    radar : AHMAPIpy.RadarHandler
        Radar handler instance from the AHMAPIpy module.

    Returns
    -------
    configOut : types.SimpleNamespace
        The complete radar information after configuration.

        hwcode (int): hardware model ID
        profile (profile): information about distance and resolution
        bandwidth (int): bandwidth in MHz
        staticObjectRemoval (int): enable/disable the execution of the static object removal algorithm
        staticObjectMapUpdateTime (float): time constant in seconds
        embeddedImageCalculatorAlgorithm (int): enabling state of the device for embedded image reconstraction algorithm
        fps (int): frame rate
        RhoRange (float): downrange span in meters
        offset (float): global offset
        iterations (int): number of integration to create a single frame
        rxMask/txMask (int): recive and transmit masks
        rxAntDesc/txAntDesc (ant): List of ant, each contains information of recive and transmit antennas
        fcarrier (int): center frequency of the pulses in MHz
        canvasData (canvas2d_param): contains reconstruction boundaries used in reconstraction algorithm
        elab (int): elaboration level at which the data will be returned (Raw or MTI)
        tx_power (int): transmit power of the antennas
        multistream (int): desired number of acquisitions per request, values range from 1 up to 10
        rxgain (int): recive gain level
        fmt (int): set the format encoding used for transmitting streams’ data
        fs (int): ADC frequency
  """


  configOut = config
  try:
    version_fw = radar.rdr_get_version_fw()
    print(f"HWCode: {version_fw.hwcode:04x}")
    configOut.hwcode = version_fw.hwcode


    FWVerStr  = radar.rdr_get_versExtended()
    print(f"FW version: {FWVerStr}")

    print("Configure system")
    radar.rdr_stop()

    radar.rdr_set_profile(config.profile)
    time.sleep(0.5)  # required for internal procedures


    if hasattr(config, "bandwidth"):
      bwmode = 0
      if config.bandwidth > 1300 :
        bwmode = 1
      curBwmode = radar.rdr_get_bwmode()
      if curBwmode != bwmode :
        radar.rdr_set_bwmode(bwmode)
    else:
      configOut.bandwidth = radar.rdr_get_pulse_bandwidth()
    time.sleep(0.5)  # required for internal procedures
    print(f"config.bandwidth {configOut.bandwidth}")

    radar.rdr_set_staticObjRemoval(config.staticObjectRemoval);
    print(f"config.staticObjectRemoval: {config.staticObjectRemoval}")

    radar.rdr_set_staticObjMapUpdateTime(config.staticObjectMapUpdateTime)
    print(f"config.staticObjectMapUpdateTime: {config.staticObjectMapUpdateTime}")

    radar.rdr_set_embeddedImgAlgo(config.embeddedImageCalculatorAlgorithm)
    print(f"config.embeddedImageCalculatorAlgorithm: {config.embeddedImageCalculatorAlgorithm}")

    radar.rdr_set_fps(config.fps)
    print(f"config.fps: {config.fps}")

    radar.rdr_set_range(config.RhoRange[0], config.RhoRange[1])
    print(f"config.RhoRange: [{config.RhoRange[0]}, {config.RhoRange[1]}]")

    if hasattr(config, "offset"):
      radar.rdr_set_offset(config.offset)
    else:
      configOut.offset = radar.rdr_get_offset()
    print(f"configOut.offset: {configOut.offset}")


    if hasattr(config, "iterations"):
      radar.rdr_set_iterations(config.iterations)
    else:
      configOut.iterations = radar.rdr_get_iterations()
    print(f"configOut.iterations: {configOut.iterations}")

    if hasattr(config, "rxMask") and hasattr(config, "txMask"):
      radar.rdr_set_sequence(config.rxMask, config.txMask, config.numS)
    else:
      configOut.txMask, configOut.rxMask, numSeq = radar.rdr_get_sequence()
    print(f"configOut.rxMask: {configOut.rxMask}")
    print(f"configOut.txMask: {configOut.txMask}")

    configOut.txAntDesc, configOut.rxAntDesc = radar.rdr_get_antConfig()
    print(f"configOut.rxAntDesc: {configOut.rxAntDesc}")
    print(f"configOut.txAntDesc: {configOut.txAntDesc}")

    if hasattr(config, "fcarrier"):
      radar.rdr_set_carrier_frequency(config.fcarrier)
    else:
      configOut.fcarrier = radar.rdr_get_carrier_frequency()*1e6
    print(f"configOut.fcarrier: {configOut.fcarrier/1e6} (MHz)")

    if configOut.hwcode == 0xa3d0:
      print("canvasData cannot be configured for 3D radar.")
    else:
      if hasattr(config, "canvasData"):
        radar.rdr_set_canvas_2d(config.canvasData)
      else:
        configOut.canvasData = radar.rdr_get_canvas_2d()
        print(f"configOut.canvasData: {configOut.canvasData}")

    if hasattr(config, "elab"):
      radar.rdr_set_elab(config.elab)
    else:
      configOut.elab = radar.rdr_get_elab()
    print(f"configOut.elab: {configOut.elab}")

    if hasattr(config, "tx_power"):
      radar.rdr_set_tx_power(config.tx_power)
    else:
      configOut.tx_power = radar.rdr_get_tx_power()
    print(f"configOut.tx_power: {configOut.tx_power}")

    radar.rdr_set_multistreammode(config.multistream)
    print(f"config.multistream: {config.multistream}")

    if hasattr(config, "rxgain"):
      radar.rdr_set_rxGain(config.rxgain)
    else:
      configOut.rxgain = radar.rdr_get_rxGain()
    print(f"configOut.rxgain: {configOut.rxgain}")

    if hasattr(config, "fmt"):
      radar.rdr_set_data_fmt(config.fmt)
    else:
      configOut.fmt = radar.rdr_get_data_fmt()
    print(f"configOut.fmt: {configOut.fmt}")

    fs = radar.rdr_get_adcfreq()*1e6
    configOut.fs = fs
    print(f"config.fs {fs} (Hz)")

    radar.rdr_start()

    return configOut

  except Exception as e:
    print(f"Configuration failed | {type(e).__name__}: {e}")
