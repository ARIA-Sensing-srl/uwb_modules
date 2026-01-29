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

[rc, sor] = sg_staticObjRemoval(board, config.staticObjectRemoval);
if (rc)
  fprintf("Error setting static object removal option\n");

  return;
end
fprintf("static object removal: %d\n", sor);
configOut.staticObjectRemoval = sor;

[rc, sorut] = sg_staticObjMapUpdateTime(board, config.staticObjectMapUpdateTime);
if (rc)
  fprintf("Error setting static object removal time option\n");

  return;
end
fprintf("static object removal time: %d\n", sorut);
configOut.staticObjectMapUpdateTime = sorut;

[rc, rxg] = sg_rxGain(board, []);
if (rc)
  fprintf("Error get rx gain\n");

  return;
end
fprintf("rx gain: %d\n", rxg);

[rc, eica] = sg_embeddedImgAlgo(board, config.embeddedImageCalculatorAlgorithm);
if (rc)
  fprintf("Error setting embedded algoritum option\n");

  return;
end
fprintf("embedded algorithm option: %d\n", eica);
configOut.embeddedImageCalculatorAlgorithm = eica;

[rc, fps] = set_fps(board,config.fps);
if (rc)
  fprintf("Set frame rate failed\n");

  return;
end
fprintf("Frame rate: %d\n", fps);
configOut.fps = fps;



[rc, fs] = get_adcfreq(board)
if (rc)
  fprintf("ADC frequency request failed\n");

  return;
endif
fs = double(fs)*1e6;
fprintf("ADC frequency %d MHz\n", fs/1e6);

configOut.fs = fs;



[rc, configOut.RhoRange(1), configOut.RhoRange(2)] = set_range(board,config.RhoRange(1), config.RhoRange(2));
if (rc)
  fprintf("Set range failed\n");

  return;
end
fprintf("Actual range: %f, %f\n",configOut.RhoRange(1), configOut.RhoRange(2));


[rc, it] = sg_iterations(board,config.iterations);
if (rc)
  fprintf("Set iterations failed\n");

  return;
end
fprintf("Iterations %d\n", it);
configOut.iterations = it;


[rc, configOut.rxMask, configOut.txMask] = set_scan_sequence(board,[], []);
if (rc)
  fprintf("Set code failed\n");

  return;
end

[rc, configOut.rxAnt, configOut.txAnt] = sg_antConfig(board, [],[]);
if (rc)
  fprintf("Error while retrieve antennas array\n");

  return;
endif

if (isfield(config, 'fcarrier') == 0)
  config.fcarrier=[];
end

[rc, fcarrier] = set_carrier_frequency(board,config.fcarrier);
if (rc)
  fprintf("Set frequency failed\n");
  return;
end
fcarrier = single(fcarrier)*1e6;
printf("Actual frequency %g (MHz)\n", fcarrier/1e6);
configOut.fcarrier = fcarrier ;


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


rc = start_radar(board);
if (rc)
  fprintf("Start radar failed\n");

  return;
end


endfunction
