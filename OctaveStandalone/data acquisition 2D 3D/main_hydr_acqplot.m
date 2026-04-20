% *************************************************
% ARIA Sensing srl 2024
% This scripts configures the radar and requires acqusition periodically.
% Returned frames are plotted into a combined subplot graph (I/Q/abs)
% *************************************************

pkg load aria_uwb_toolbox
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

config.RhoRange = [0.0 5];
config.iterations = []; 	#number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 1; #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0; #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0;
config.profile=0;
config.multistream=1; #number of acquisition for each data request
config.fps=20;


##END PARAMETERS####################################

#start radar intialization code###########################


[rc, config] = configureDevice(board, config);

if (rc)
  fclose(board);
  return;
end

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

  numStreams = size(data, 1);
  numSamples = size(data, 2);
  x = ((1:1:numSamples)-1)*distbin + config.RhoRange(1);

  curMax = max(max(abs(data)));
  if (curMax > lastMax)
    lastMax = curMax;
    lastMaxUpdateCnt = 0;
  elseif (abs((lastMax-curMax)) < 0.1*lastMax)
    lastMaxUpdateCnt=0;
  else
    lastMaxUpdateCnt++;
    if (lastMaxUpdateCnt > 10)
      lastMax = lastMax/2;
      lastMaxUpdateCnt = 0;
    endif
  endif

  if (lastMax == 0)
    lastMax = 1.0; #override if zero
  endif


  subplot(3,1,1);
  plot(x, real(data));
  xlabel("Distance (m)");
  ylabel("Amplitude (a.u.)");
  title("Real data");
  ylim([-lastMax lastMax])


  subplot(3,1,2);
  plot(x, imag(data));
  xlabel("Distance (m)");
  ylabel("Amplitude (a.u.)");
  title("Imag data");
  ylim([-lastMax lastMax])

  subplot(3,1,3);
  plot(x, abs(data));
  xlabel("Distance (m)");
  ylabel("Amplitude (a.u.)");
  title("Envelpe data");
  ylim([-lastMax lastMax])


  drawnow;
end
##stop = time-start

if (failcnt >= failcntlimit)
  fprintf("Exit for fail\n");
end
ret_code = stop_radar(board);
fclose(board);





