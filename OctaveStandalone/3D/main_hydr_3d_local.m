% *************************************************
% ARIA Sensing srl 2024
% Confidential-reserved
% The script configures the radar, and implements the beamforming algorithm locally,
% searches for the maximum amplitude and extracts two slicing planes YZ and XY crossing the point of maximum amplitude
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


config.algo="DMAS_SR";			#select the algorithm used for reconstruction DAS, DMAS, DAS_SR, DMAS_SR
config.RhoStep = 0.05;                 #Downrange resolution in meters
config.RhoRange = [1 5.0];             #Downrange span in meters
config.AzimStep = 5 * pi/180;         	#Angular reconstruction resolution in radiants
config.AzimRange = [-45 45] * pi/180; 	#Angular span in radiants
config.ZenithRange = [45 135] * pi/180;
config.ZenithStep = 5 * pi/180;

config.iterations = []; 	#number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1; #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0; #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0;
config.multistream=1; #number of acquisition for each data request
config.profile=0;
config.fps=20;



##END PARAMETERS####################################


Rhobase = config.RhoRange(1):config.RhoStep:config.RhoRange(2);
AzimBase = config.AzimRange(1):config.AzimStep:config.AzimRange(2);
ZenithBase = config.ZenithRange(1):config.ZenithStep:config.ZenithRange(2);

[rc, config] = configureDevice(board, config);


distbin = 1.5e8/config.fs;


[hradar, AmplCorrection] = setupLocalReconstruction(config);

if (isempty(hradar))
  fclose(board);
  fprintf("Error on local reconstruction setup");
  return;
end


#end radar intialization code############################
fprintf("\n\nInitialization complete\n");
fprintf("Focus the command window and press Esc to stop\n");

#Setup data for local algorithm reconstruction


figure;
failcnt = 0;
failcntlimit = 5;

while(kbhit(1)==27)
  pause(0.005);
end

isDMAS = 1;
if (isempty(strfind(config.algo, "DMAS")))
  isDMAS = 0;
endif


while ((failcnt < failcntlimit))
  pause(0.005);

  if (kbhit(1)==27)
				break;
  end;

  [data, etime, fmt] = read_raw_data_multiple(board);
  if (isempty(data))
    failcnt = failcnt+1;
    drawnow;
    continue,
  endif
  failcnt = 0;

  for N = 1:length(AmplCorrection)
    data(N,:) = data(N,:) * AmplCorrection(N);
  endfor

  output_volume = imageReconstruction_3D(hradar,data, AzimBase, ZenithBase, Rhobase ,config.algo);

  if (isDMAS)
    output_volume  = real(output_volume );
  else
    output_volume  = abs(output_volume);
  endif

  #plot
  #compound view


  #this section search the maximum amplitude inside the
  [maxR,maxRI] = max(output_volume);
  maxR = squeeze(maxR);
  maxRI = squeeze(maxRI);

  [maxR2, maxR2I] = max(maxR);
  maxR2 = squeeze(maxR2);
  maxR2I = squeeze(maxR2I);
  [maxR3, maxR3I] = max(maxR2);

  RI = maxRI(maxR2I(maxR3I), maxR3I);
  imgMax = squeeze(output_volume(RI, :,:));
  img2d = squeeze(output_volume(:,:, maxR3I));

  subplot(1,2,1);
  imagesc(ZenithBase*180/pi, AzimBase*180/pi,  abs(imgMax));
  title("YZ plane");
  ylabel("Azimuth");
  xlabel("Zenith");
  subplot(1,2,2);
  imagesc(AzimBase*180/pi,Rhobase, abs(img2d));
  title("XY plane");
  ylabel("Rho");
  xlabel("Azimuth");

  hold on;
  plot([AzimBase(1) AzimBase(end)]*180/pi, [Rhobase(RI) Rhobase(RI)], '-r', 'linewidth', 4);
  hold off;
  drawnow;
end
##stop = time-start

if (failcnt >= failcntlimit)
  fprintf("Exit for fail\n");
end
ret_code = stop_radar(board);
fclose(board);





