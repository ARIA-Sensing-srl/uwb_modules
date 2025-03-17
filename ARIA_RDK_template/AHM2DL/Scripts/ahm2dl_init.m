% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% *************************************************

#pkg load aria_uwb_toolbox
addpath("func")
printf("...Radar Device Initalization\n");

#Stop radar 
var_immediate_command("stop");

#USER configuration

fcarrier = 8064;			#carrier frequency
var_immediate_update("fcarrier");
bandwidth = 1000;			#pulse bandwidth
var_immediate_update("bandwidth");
xmin = 1;				#minimum acquired distance
var_immediate_update("xmin");
xmax = 5;				#maximum acquired distance
var_immediate_update("xmax");
offset = single(-1);			#acquisition offset
var_immediate_update("offset");
elaboration = 1;			#elaboration type (0 raw, 1 MTI)
var_immediate_update("elaboration");
iterations = 4000;			#integrations level
var_immediate_update("iterations");
declutter = 100;			#declutter constant in number of frames
var_immediate_update("declutter");
txPwr = 7;				#transmitter power (0-7)
var_immediate_update("txPwr");
code = [1];				#codeword
var_immediate_update("code");
VGAIGain = 20;				#VGA gain (0-33) I channel
var_immediate_update("VGAIGain");
VGAQGain = 20;				#VGA gain (0-33) Q channel
var_immediate_update("VGAQGain");
scan_sequence = [...
	1 3;...
	3 2;...
	1 2;...
	1 1;...
	3 3;...
	2 2;...
	3 1;...
	2 3;...
	2 1; ...
	];	#antennas sequence [t r; t r; ...] zero based
fmt = 4; 				#data format (used for transfer) Q.7, Q.15, Q.32, F32, F16
var_immediate_update("fmt");
#preprocessing options
preproc_dcrem_en = 1;			#execute DC suppression on raw data
preproc_corr_en = 0;			#execute correlation with expected codeword
preproc_corr_matchfilt_en = 1;		#execute matched filter
appopt_det_algo = 0;			#enable detection algorithm
appopt_cplx_image = 0;			#enable complex image calculation (default is pixel intensity)
appopt_rec_algo_en = 0;			#enable embedded reconstruction algorithm


#Handle encoded parameters
#encode processing option before send to serial interface
opt_proc0=preproc_dcrem_en+2*preproc_corr_en+4*preproc_corr_matchfilt_en;
opt_proc1 = appopt_det_algo+2*appopt_cplx_image+4*appopt_rec_algo_en;
var_immediate_update("opt_proc_0");

%Encode scan sequence and send
rxmask = 2.^scan_sequence(:,2);
txmask = 2.^scan_sequence(:,1);
sequence = rxmask + 16*txmask;
var_immediate_update("sequence");
#Get sample frequency
var_immediate_inquiry("fs");

#start radar operations
var_immediate_command("start");

