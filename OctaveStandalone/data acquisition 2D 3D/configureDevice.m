## Copyright (C) 2026 Andrea Mario
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {} {@var{fail/success}, @var{configOut} =} configureDevice (@var{board}, @var{config})
## This function configure the radar and start radar operations
## @seealso{}
## @end deftypefn

## Author: Aria Sensing srl
## Created: 2026-01-13

function [rc, configOut] = configureDevice (board, config)

rc=0;
configOut = config;


[ rc, ~, hw_code,  ~,~,~] = get_version_fw(board);
if (rc)
  fprintf("Get FW version failed\n");
  return;
end
fprintf("HWCode: %04x\n", hw_code);
configOut.hw_code = hw_code;


[rc, FWVerStr] = get_versExtended(board,0);
if (rc)
  printf("Error on version request\n")
else
  printf("FW version: %s\n", FWVerStr);
endif


fprintf("Configure system\n");
rc = stop_radar(board);
if (rc)
  fprintf("Stop radar failed\n");

  return;
end

rc = set_profile(board, config.profile);
if (rc)
  fprintf("Error setting profile\n");

  return;
end
pause(0.5); #required for internal procedures


if (isfield(config, 'bandwidth') == 0)
  config.bandwidth = [];
else
  #configure bandwidth and bw mode accordinly
  if (isempty(config.bandwidth) == 0)
    bwmode = 0;
    if (config.bandwidth > 1300)
      bwmode = 1;
    endif
    [rc, curBwmode] = set_bwmode(board, []);
    if (rc)
      printf("Error on bwmode setting\n");
    endif
    if (curBwmode != bwmode)
      [rc, outBwmode] = set_bwmode(board, bwmode);
      if (rc)
        printf("Error on bwmode setting\n");
      endif
      if (outBwmode != bwmode)
        printf("Error on bwmode setting\n");
      endif
      pause(0.5);
    end
  end
end

[rc, configOut.bandwidth] = set_pulse_bandwidth(board, config.bandwidth );
if (rc)
  printf("Inquiry bandwidth failed\n");
  return
endif
printf("config.bandwidth %d\n", configOut.bandwidth);


[rc, sor] = sg_staticObjRemoval(board, config.staticObjectRemoval);
if (rc)
  fprintf("Error setting static object removal option\n");

  return;
end
fprintf("config.staticObjectRemoval: %d\n", sor);
configOut.staticObjectRemoval = sor;

[rc, sorut] = sg_staticObjMapUpdateTime(board, config.staticObjectMapUpdateTime);
if (rc)
  fprintf("Error setting static object removal time option\n");

  return;
end
fprintf("config.staticObjectMapUpdateTime: %d\n", sorut);
configOut.staticObjectMapUpdateTime = sorut;



[rc, eica] = sg_embeddedImgAlgo(board, config.embeddedImageCalculatorAlgorithm);
if (rc)
  fprintf("Error setting embedded algoritum option\n");

  return;
end
fprintf("config.embeddedImageCalculatorAlgorithm: %d\n", eica);
configOut.embeddedImageCalculatorAlgorithm = eica;

[rc, fps] = set_fps(board,config.fps);
if (rc)
  fprintf("Set frame rate failed\n");

  return;
end
fprintf("config.fps: %d\n", fps);
configOut.fps = fps;



if (isfield(config, 'offset') == 0)
  config.offset = [];
end
[rc, configOut.offset] = set_offset(board, config.offset);
if (rc)
  fprintf("Error get offset \n");

  return;
end
fprintf("config.offset: %d\n", configOut.offset);


[rc, configOut.RhoRange(1), configOut.RhoRange(2)] = set_range(board,config.RhoRange(1), config.RhoRange(2));
if (rc)
  fprintf("Set range failed\n");

  return;
end
#actual range is requested  after configuration


[rc, it] = sg_iterations(board,config.iterations);
if (rc)
  fprintf("Set iterations failed\n");

  return;
end
fprintf("config.iterations: %d\n", it);
configOut.iterations = it;


if ((isfield(config, 'rxMask') == 0) || (isfield(config, 'txMask') == 0))
  config.rxMask = [];
  config.txMask = [];
end

[rc, configOut.rxMask, configOut.txMask] = set_scan_sequence(board,config.rxMask, config.txMask);
if (rc)
  fprintf("Set code failed\n");

  return;
end

[rc, configOut.rxAnt, configOut.txAnt] = sg_antConfig(board, [],[]);
if (rc)
  fprintf("Error while retrieve antennas array\n");

  return;
endif
#optional parameters
if (isfield(config, 'fcarrier') == 0)
  config.fcarrier=[];
end

[rc, fcarrier] = set_carrier_frequency(board,config.fcarrier);
if (rc)
  fprintf("Set frequency failed\n");
  return;
end
#actual carrier frequency is checked at the end of the configuration file


if (isfield(config, 'canvasData') == 0)
  config.canvasData=[];
  configOut.canvasData=[];
end
#in 3D device this command is not implemented not data are returned
[rc, configOut.canvasData] = sg_canvas(board, config.canvasData);
if (rc)
  printf("No canvas data available\n");
  rc=0;
endif

#elab
if (isfield(config, 'elab') == 0)
  config.elab = [];
  if (configOut.staticObjectRemoval)
    config.elab = 1;
  endif
end

[rc, configOut.elab] = set_elab(board, config.elab );
if (rc)
  printf("Inquiry elaboration level failed\n");
  return
endif
printf("config.elab: %d\n", configOut.elab);

#transmitter power
if (isfield(config, 'tx_power') == 0)
  config.tx_power = [];
end
[rc, configOut.tx_power] = set_tx_power(board, config.tx_power );
if (rc)
  printf("Inquiry tx power failed\n");
  return
endif
printf("config.tx_power: %d\n", configOut.tx_power);


if (isfield(config, 'multistream') == 0)
  config.multistream = [];
end
[rc, configOut.multistream] = set_multistreammode(board, config.multistream);
if (rc)
  printf("Inquiry multistream mode failed\n");
  return
endif
printf("config.multistream %d\n", configOut.multistream);


if (isfield(config, 'rxgain') == 0)
  config.rxgain = [];
end
[rc, configOut.rxgain] = sg_rxGain(board, config.rxgain);
if (rc)
  fprintf("Error get rx gain\n");

  return;
end
fprintf("config.rxgain: %d\n", configOut.rxgain);


if (isfield(config, 'fmt') == 0)
  config.fmt = [];
end
[rc, configOut.fmt] = set_data_fmt(board, config.fmt);
if (rc)
  fprintf("Error get rx gain\n");
  return;
end
fprintf("config.fmt: %d\n", configOut.fmt);



[rc, fs] = get_adcfreq(board);
if (rc)
  fprintf("ADC frequency request failed\n");

  return;
endif
fs = double(fs)*1e6;
configOut.fs = fs;
fprintf("config.fs %g (Hz)\n", fs);


#get carrier after configuration process
[rc, fcarrier] = set_carrier_frequency(board,[]);
if (rc)
  fprintf("Set frequency failed\n");
  return;
end
fcarrier = single(fcarrier)*1e6;
printf("config.fcarrier %d (MHz)\n", fcarrier/1e6);
configOut.fcarrier = fcarrier ;


[rc, configOut.RhoRange(1), configOut.RhoRange(2)] = set_range(board, [], []);
if (rc)
  fprintf("Set range failed\n");

  return;
end
fprintf("config.RhoRange: [%f %f]\n",configOut.RhoRange(1), configOut.RhoRange(2));


rc = start_radar(board);
if (rc)
  fprintf("Start radar failed\n");
  return;
end


endfunction
