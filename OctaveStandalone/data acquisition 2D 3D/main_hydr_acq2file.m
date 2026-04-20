% *************************************************
% ARIA Sensing srl 2024
% This scripts configures the device, acquires data according to used-defined time and store into file
% Without live plots, acquisition rate is faster and allow data collection at high frame rate settings
% Actual frame rate could be affected by many parameters (number of streams, iterations, etc.)
% Data are collected into dataOut variables and eventually stored into *.mat file
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
config.iterations = 3000; 	                  #number of integrations, if [], scripts automatically set according to the HW
config.staticObjectRemoval = 0;               #enable/disable static object removal algorithm
config.staticObjectMapUpdateTime = 15.0;      #time constant to update static object mapping
config.embeddedImageCalculatorAlgorithm = 0;
config.profile=0;
config.fps=50;
config.multistream = 8;     #packed mode: this parameter set the number of acquisition to pack for each data request, this option speeds up the acquisition rate
config.elab = 0;            #collect data without any elaboration


#UNCOMMENT THIS SECTION IF USER-PROVIDED sequence is required
##scan_sequence = [1 1; 1 2]; #every row set tx and rx antenna for each stream [tx_stream0 rx_stream0; tx_stream1 rx_stream1; etc...]
##                            #see AHMx datasheet for antenna to channel mapping
##[config.rxMask, config.txMask] = antSequence2TxRxMap(scan_sequence);
####################################################


##END PARAMETERS####################################

#start radar initialization code###########################

#Get acquisition time from user
acqTimeStr = inputdlg("Set time","Acquisition",1, {"10"});


if (numel(acqTimeStr) == 0)
  printf("Error: undefined acqusition time\n");
  fclose(board);
  return;
end


acqTimeStr = acqTimeStr{1};

if (isempty(acqTimeStr))
   printf("Error: undefined acqusition time\n");
   fclose(board);
   return;
end

if (isnumeric(acqTimeStr))
   printf("Error: not a number\n");
   fclose(board);
   return;
end

acqTime = str2num(acqTimeStr);


[rc, config] = configureDevice(board, config);

if (rc)
  fclose(board);
  return;
end
#end radar intialization code############################
fprintf("\n\nInitialization complete\n");
fprintf("Focus the command window and press Esc to early stop\n");


##figure;
failcnt = 0;
failcntlimit = 5;

while(kbhit(1)==27)
  pause(0.005);
end

start = time;

dataOut =[];
timestamp=[];

fprintf("Capture time %d seconds\n", acqTime);
perc = -1;

while ((failcnt < failcntlimit))
  if (kbhit(1)==27)
				break;
  end;
  [data, etime, fmt] = read_raw_data_multiple(board);
  elapsed = time-start;
  if (isempty(data))
    failcnt = failcnt+1;
    drawnow;
    continue,
  endif

  dataOut = [dataOut; data];
  timestamp=[timestamp elapsed];

  newPerc = round(10*elapsed/acqTime);
  if (newPerc  != perc)
    fprintf("%d%%...\n", newPerc*10);
    perc = newPerc;
    drawnow;
  endif

  if (elapsed > acqTime)
    break;
  endif
  drawnow;
end


ret_code = stop_radar(board);
fclose(board);

if (failcnt >= failcntlimit)
  fprintf("Exit for fail\n");
  return;
end
fprintf("Complete\n");

numScans = length(config.rxMask);
totAcquisitions = size(dataOut, 1)/numScans;
equivFrameRate = totAcquisitions/elapsed;

fprintf("Average frame rate %d\n", equivFrameRate);


filename = ["data_" strftime("%H%M%S_%d%m%Y", localtime(time())) ".mat"];

inputFileName = inputdlg("Set filename","Acquisition",1, {filename});

if (numel(inputFileName) != 0)
  inputFileName = inputFileName{1};
  if (isempty(inputFileName) == 0)
    filename = inputFileName;
  end
end
save("-binary", filename, "dataOut", "config", "equivFrameRate", "timestamp");
fprintf("Saved into \"%s\"\n", filename);






