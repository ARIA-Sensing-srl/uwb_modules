% *************************************************
% ARIA Sensing srl 2018
% Confidential-reserved
% This script configures the device and get the image reconstructed by the module
% *************************************************

pkg load aria_uwb_toolbox
close all;          % close all figures
clear variables;    % clear all workspace variables
clc;                % clear the command line
fclose('all');      % close all open files
#setup_env

global DEFINE_OCTAVE % global variable to choose between Matlab/Octave
DEFINE_OCTAVE=1;

C0 = 3e8;
pkg load instrument-control
%init serial port
board = openDevice([],[]);

if (isempty(board))
  fprintf("No device found\n");
  return;
end



config.RhoStep = 0.05;                 #Downrange resolution in meters
config.RhoRange = [0 7.0];             #Downrange span in meters
config.AzimStep = 5 * pi/180;         	#Angular reconstruction resolution in radiants
config.AzimRange = [-45 45] * pi/180; 	#Angular span in radiants
config.iterations = []; 	#number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1; #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0; #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 1;
config.profile=0;
config.multistream=1; #number of acquisition for each data request
config.fps=20;

##END PARAMETERS####################################

#start radar intialization code###########################

#setup canvas
config.canvasData.algo = 1;
config.canvasData.rhoMin = config.RhoRange(1);
config.canvasData.rhoStep = config.RhoStep;
config.canvasData.rhoMax = config.RhoRange(2);
config.canvasData.phiMin = config.AzimRange(1)*180/pi;
config.canvasData.phiStep= config.AzimStep*180/pi;
config.canvasData.phiMax = config.AzimRange(2)*180/pi;

[rc, config] = configureDevice(board, config);

if (rc)
  fclose(board);
  return;
end

if ((config.hw_code ~= 0xa2d0) && (config.hw_code ~= 0xa2d5) & (config.hw_code ~= 0xa2d1))
    fprintf("HW model doesn't supprot embedded 2D algorithm\n");
    fclose(board);
    return
end

distbin = 1.5e8/config.fs;

#end radar intialization code############################
fprintf("\n\nInitialization complete\n");
fprintf("Focus the command window and press Esc to stop\n");


#end radar intialization code############################
fprintf("Done\n");

figure;
failcnt = 0;
failcntlimit = 5;


while(kbhit(1)==27)
  pause(0.005);
end


while ((failcnt < failcntlimit))
  pause(0.005);
##  iter -= 1;
  if (kbhit(1)==27)
				break;
  end;
  #request image
  [data, etime, fmt] = read_image(board);
  if (isempty(data))
    failcnt = failcnt+1;
    drawnow;
    continue,
  endif

  numRho = size(data, 1);
  numAzim = size(data, 2);
  rhoBase = linspace(config.canvasData.rhoMin, config.canvasData.rhoMax, numRho);
  azimBase = linspace(config.canvasData.phiMin, config.canvasData.phiMax, numAzim);

  failcnt = 0;
  imagesc(azimBase, rhoBase, abs(data));
  xlabel("Azimuth");
  ylabel("Rho");

  drawnow;
end
##stop = time-start

if (failcnt >= failcntlimit)
  fprintf("Exit for fail\n");
end
ret_code = stop_radar(board);
fclose(board);





