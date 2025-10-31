% *************************************************
% ARIA Sensing srl 2024
% Confidential-reserved
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
board = serial('/dev/ttyUSB1');
set(board, 'baudrate', 921600);     % See List Below
set(board, 'bytesize', 8);        % 5, 6, 7 or 8
set(board, 'parity', 'n');        % 'n' or 'y'
set(board, 'stopbits', 1);        % 1 or 2
set(board, 'timeout', 0.1);     % 12.3 Seconds as an example here



fprintf('Opening board.......');
drawnow;
fopen(board);
srl_flush(board);
pause(.1);
srl_flush(board);
fprintf('\t\t done \n');
drawnow;

xrange = [0 6];
offset = -1;
VGAIGain = 20;
VGAQGain = 20;
code = [1];
txpower  = 7;


#t / r (zero based)
scan_sequence = [];

fmt = 4; #0:Q7, 1:Q15, 2:Q31, 3:F32, 4:F16
elabtype = 1; #0 raw, 1 mti
iterations = []; #autoselect
bw = 1000;
declutter = 100;
fc = 8064e6;
bwmode = 0;

#internal processing option
preproc_dcrem_en = 1; #DC is removed before transferred to main processor
preproc_corr_en = 0;  #pulse correlator enable before transferred to main processor
preproc_corr_matchfilt_en = 1;
appopt_det_algo = 0;
appopt_cplx_image = 0;
appopt_rec_algo_en = 0;
algo="DMAS_SR";


RhoStep = 0.05;                  #Rho resoluton
RhoRange = [0 5.0];              #Rho range

AzimStep = 5 * pi/180;         #Theta resolution
AzimRange = [-45 45] * pi/180; #Theta range

##END PARAMETERS####################################

[ rc, ~, hw_code,  ~,~,~] = get_version_fw(board);
if (rc)
  fprintf("Get FW version failed\n");
  fclose(board);
  return;
end
fprintf("HWCode: %04x\n", hw_code)

if (isempty(scan_sequence))
  #set scan sequence according to model
  fprintf("Set scan_sequence automatically\n");
  if (hw_code == 0xa3d5)
    scan_sequence = [0 1; ...
                 0 2; ...
                 2 2; ...
                 2 1];
  elseif (hw_code == 0xa2d1)
    scan_sequence = [ ...
                 1 3; ...
                 1 1; ...
                 3 1; ...
                 2 3; ...
                 3 3; ...
                 3 2; ...
                 1 2; ...
                 2 2; ...
                 2 1; ...
                 ];
  else
    scan_sequence = [1 1; ...
                 2 1; ...
                 2 2; ...
                 1 2];
  endif
endif

if (isempty(iterations))
  if (hw_code == 0xa2d1)
    iterations = 4000;
  else
    iterations = 10000;
  endif
end

#create bitmask for scan
if (size(scan_sequence,2) ~= 2)
  printf("Invalid scan_sequenc array\n");
  fclose(board);
  return;
endif

numScans = size(scan_sequence, 1);

#create scan code for radar
scan.tx = zeros(1, numScans);
scan.rx = zeros(1, numScans);
for N = 1:numScans
  scanline = squeeze(scan_sequence(N,:));
  if (sum(scanline > 3))
    printf("Invalid scan_sequenc array, antenna index out of range\n");
    fclose(board);
    return;
  endif
  scan.tx(N) = 2^scanline(1);
  scan.rx(N) = 2^scanline(2);
endfor




#TODO, change by using rxTx
numSeq = size(scan_sequence, 1);
hradar.TxRxCycle = zeros(2,4,numSeq);
for k = 1:numSeq
  hradar.TxRxCycle(1, scan_sequence(k,1)+1, k) = 1;
  hradar.TxRxCycle(2, scan_sequence(k,2)+1, k) = 1;
endfor


Rhobase = RhoRange(1):RhoStep:RhoRange(2);
AzimBase = AzimRange(1):AzimStep:AzimRange(2);




fprintf("Configure system\n");
ret_code = stop_radar(board);
if (ret_code)
  fprintf("Stop radar failed\n");
  fclose(board);
  return;
end

ret_code = set_bwmode(board,bwmode);
if (ret_code)
  fprintf("BWmode radar failed\n");
  fclose(board);
  return;
end
pause(0.5);

[ret_code, fc] = set_carrier_frequency(board,fc/1e6);
if (ret_code)
  fprintf("Set frequency failed\n");
  fclose(board);
  return;
end
fc = single(fc)*1e6;
printf("Actual frequency %g (MHz)\n", fc/1e6);


ret_code = set_pulse_bandwidth(board, bw);
if (ret_code)
  fprintf("Set  failed\n");
  fclose(board);
  return;
end


ret_code = set_opt_processing(board, preproc_dcrem_en, preproc_corr_en, preproc_corr_matchfilt_en,...
            appopt_det_algo, appopt_cplx_image, appopt_rec_algo_en);
if (ret_code)
  fprintf("Set preprocessing option failed\n");
  fclose(board);
  return;
endif

[ret_code,offset] = set_offset(board, offset);
if (ret_code)
  fprintf("Set offset failed\n");
  fclose(board);
  return;
end
printf("Offset %g\n", offset);

[ret_code, xrange(1), xrange(2)] = set_range(board,xrange(1), xrange(2));
if (ret_code)
  fprintf("Set range failed\n");
  fclose(board);
  return;
end
fprintf("Actual range: %f, %f\n",xrange(1), xrange(2));
pause(1);

[ret_code] = set_vgas_gain(board,VGAIGain,VGAQGain);
if (ret_code)
  fprintf("Set VGA failed\n");
  fclose(board);
  return;
end

[ret_code] = set_declutter_length(board,declutter);
if (ret_code)
  fprintf("Set declutter failed\n");
  fclose(board);
  return;
end

[ret_code] = set_code(board,code);
if (ret_code)
  fprintf("Set code failed\n");
  fclose(board);
  return;
end

[ret_code] = set_tx_power(board, txpower);
if (ret_code)
  fprintf("Set txpower failed\n");
  fclose(board);
  return;
end

[ret_code] = set_slow_time_gain(board,iterations);
if (ret_code)
  fprintf("Set iterations failed\n");
  fclose(board);
  return;
end

[ret_code] = set_scan_sequence(board,scan.rx, scan.tx);
if (ret_code)
  fprintf("Set sequence failed\n");
  fclose(board);
  return;
end

[ret_code] = set_elab(board,elabtype);
if (ret_code)
  fprintf("Set elaboration failed\n");
  fclose(board);
  return;
end

[ret_code] = set_data_fmt(board,fmt);
if (ret_code)
  fprintf("Set data format failed\n");
  fclose(board);
  return;
end

[rc, rxAnt, txAnt] = sg_antConfig(board, [],[]);
if (rc)
  fprintf("Error while retrieve antennas array\n");
  fclose(board);
  return;
endif

[ret_code, fs] = get_adcfreq(board)
if (ret_code)
  fprintf("ADC frequency request failed\n");
  fclose(board);
  return;
endif
fs = double(fs)*1e6;
fprintf("ADC frequency %d MHz\n", fs/1e6);



pause(0.5);
ret_code = start_radar(board);
if (ret_code)
  fprintf("Start radar failed\n");
  fclose(board);
  return;
end


fprintf("Done\n");

AntennaTx = zeros(4,3);
AntennaRx = zeros(4,3);
AntennaDelayTx = zeros(1, 4);
AntennaDelayRx = zeros(1, 4);
AntennaAmplTx = zeros(1, 4);
AntennaAmplRx = zeros(1, 4);


for N = 1:4
  AntennaRx(rxAnt(N).ID+1,:) = [0 rxAnt(N).X rxAnt(N).Y];
  AntennaTx(txAnt(N).ID+1,:) = [0 txAnt(N).X txAnt(N).Y];
  AntennaDelayTx(N) = txAnt(N).delay;
  AntennaDelayRx(N) = rxAnt(N).delay;
  AntennaAmplTx(N) = txAnt(N).ampl;
  AntennaAmplRx(N) = rxAnt(N).ampl;
end


AmplCorrection = zeros(1,size(scan_sequence, 1));
for N = 1:length(AmplCorrection)
  AmplCorrection(N) = AntennaAmplTx(scan_sequence(N,1)+1) * AntennaAmplRx(scan_sequence(N,2)+1);
endfor


hradar.CoreFrequency = fs;
hradar.txCenterFrequency = fc;
hradar.TxAntPosition = AntennaTx;
hradar.RxAntPosition = AntennaRx;
hradar.FixedTxToAntennaDelays = AntennaDelayTx;
hradar.FixedRxToAntennaDelays = AntennaDelayRx;
NumTx = size(AntennaTx, 1);
NumRx = size(AntennaRx, 1);

hradar.FixedTxToAntennaDelays = hradar.FixedTxToAntennaDelays - xrange(1)*2/3e8;

figure;
failcnt = 0;
failcntlimit = 5;

isDMAS = 1;
if(isempty(strfind(algo, "DMAS")))
  isDMAS = 0;
endif


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
  failcnt = 0;

  for N = 1:length(AmplCorrection)
    data(N,:) = data(N,:) * AmplCorrection(N);
  endfor

  output_image = imageReconstruction(hradar,data, AzimBase, Rhobase ,algo);

  if (isDMAS)
    output_image  = real(output_image );
  else
    output_image  = abs(output_image );
  endif

  imagesc(AzimBase, Rhobase, abs(output_image)');
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





