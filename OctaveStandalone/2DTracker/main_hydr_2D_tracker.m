% *************************************************
% ARIA Sensing srl 2024
% The script configures and enables the tracker algorithm implemented for 2D series devices.
% Output is the position of the target and estimated speed
% Only 2D devices are supported (AHM2DL, AHM2DSC, AHM2D)
% NOTE: configuration has been tested for AHM2D device
% *************************************************

pkg load aria_uwb_toolbox
pkg load matgeom
close all;          % close all figures
clear variables;    % clear all workspace variables
clc;                % clear the command line
fclose('all');      % close all open files
#setup_env

global DEFINE_OCTAVE % global variable to choose between Matlab/Octave
DEFINE_OCTAVE=1;

pkg load instrument-control
%init serial port

board = openDevice([],[]);

if (isempty(board))
  fprintf("No device found\n");
  return;
end

##USER PARAMETERS###################################

config.RhoRange = [-0.5 7.0];	#acquisition downrange settings (meters)
config.iterations = 10000; 	#number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1; #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 40.0; #time constant to update static object mapping
config.profile=0;
config.multistream=1; #number of acquisition for each data request
config.fps=20;		#frame rate
config.rxgain=5;	
config.canvasData.algo = 1;		#image reconstruction algorithm (0: DAS, 1: DMAS)
config.canvasData.rhoMin = 0.2;		#reconstruction min downrange
config.canvasData.rhoStep = 0.15;	#reconstruction step downrange
config.canvasData.rhoMax = 7.0;		#reconstruction max downrange
config.canvasData.phiMin = -60;		#crossrange min angle
config.canvasData.phiStep = 5;		#crossrange step angle
config.canvasData.phiMax = 60;		#crossrange max angle

disable_ID = 0;             #display trace ID
plot_speed = 1;             #display speed arrow
axisLimit = [-1.5 1.5 0 6.5]; #axis limit for 2D plot (meters)

SNRs = [40 20 2.0 1.0];      #range thresholds (absolute values)
SNRRanges = [0.8 1.2 3.5]; #range distange for range profile (meters)

##END PARAMETERS####################################

#start radar intialization code###########################


[rc, config] = configureDevice_tracker(board, config);


if (rc)
  fclose(board);
  return;
end


#additional configuration
#set / get SNRs
SNRsOut = zeros(1,4);
for N = 1:4
  if (isempty(SNRs))
    curSNR = [];
  else
    curSNR = SNRs(N);
  endif
  [rc, SNRsOut(N)] = set_SNR(board, curSNR, N-1);
  if (rc)
    printf("Error on SNRs access\n");
    stop_radar(board);
    fclose(board);
    return;
  endif
  fprintf("SNR%d: %g (abs)\n", N-1, SNRsOut(N));
end

#get SNRsran ranges
[rc, SNRRangesOut] = set_SNR_ranges(board, SNRRanges, []);
if (rc)
  printf("Error on SNRs access\n");
  stop_radar(board);
  fclose(board);
  return;
endif
for N = 1:length(SNRRangesOut)
  fprintf("SNRRange%d: %g m\n",N-1, SNRRangesOut(N));
end


[rc,kalman] = set_kalman_2D(board, []);

kalman.gateInTicks = 10;
[rc,kalman] = set_kalman_2D(board, kalman);



distbin = 1.5e8/config.fs;


#end radar intialization code############################
fprintf("\n\nInitialization complete\n");
fprintf("Focus the command window and press Esc to stop\n");


figure;
failcnt = 0;
failcntlimit = 5;
lastMax = 0;
lastMaxUpdateCnt = 0;

while(kbhit(1)==27)
  pause(0.005);
end


H = [1 0 0 0; 0 0 1 0];

while ((failcnt < failcntlimit))
  pause(0.005);
##  iter -= 1;
  if (kbhit(1)==27)
				break;
  end;
  [data, etime, fmt] = read_raw_data_multiple(board);

  if (isempty(data))
    failcnt = failcnt+1;
    drawnow;
    continue,
  endif

  [ rc ,detOut, detFullState] = get_detection_2D(board, 4);
  if (rc)
    continue;
  endif

  if (isempty(detOut)==0)
    plot( detOut(:,1), detOut(:,2), '*r', 'linewidth', 10);
    hold on;
    if (isempty(detFullState) == 0)
      for N = 1:length(detFullState);
        curSV = detFullState(N).StateVector;
        curP = detFullState(N).P;
        S = inv(H *  curP * H');
        rot = 0.5*atan((S(1,2)+S(2,1))/(S(1,1)-S(2,2)));
        T = inv([cos(rot) sin(rot); -sin(rot) cos(rot)].^2);
        o = T * [S(1,1) S(2,2)]';
        Ra = sqrt(1/o(1));
        Rb = sqrt(1/o(2));
        drawEllipse(curSV(1), curSV(3), Rb, Ra, rot*180/pi, 'linewidth', 3);
        str = sprintf("%d", detOut(N,3));
        if (disable_ID ==0)
          text(detOut(N,1)+0.1, detOut(N,2), str,"fontsize", 30);
        end
        if (plot_speed == 1)

          quiver(curSV(1), curSV(3), curSV(2), curSV(4), 'linewidth', 3);
        endif
      endfor
    endif
    hold off;
  else
    hold off;
    plot(0,0);
  end
  axis(axisLimit)


  drawnow;
end
##stop = time-start

if (failcnt >= failcntlimit)
  fprintf("Exit for fail\n");
end
ret_code = stop_radar(board);
fclose(board);





