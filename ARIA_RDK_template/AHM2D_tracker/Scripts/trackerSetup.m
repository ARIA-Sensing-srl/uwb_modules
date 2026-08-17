% *************************************************
% ARIA Sensing srl 2025
% Initialization of 2D reconstruction and tracking algorithm. 
% *************************************************
pkg("load", "aria_uwb_toolbox");

var_immediate_command_pipe("stop");
xrange = [-0.5 6];			#downrange acquisition bound (meters)

profiles = 0;
var_immediate_update_pipe("profiles");


fps=20;
var_immediate_update_pipe("fps");

opt_proc_0 = 1; #internal frame processing configuration (enable DC removal)
opt_proc_1 = 5; #internal algorithm configuration (enable reconstruction algorithm and tracker
var_immediate_update_pipe("opt_proc_0");

#transfer downrange options
xmin = xrange(1);				
var_immediate_update_pipe("xmin");
xmax = xrange(2);
var_immediate_update_pipe("xmax");

#transfer receiver gain option
VGAIGain = 16;
VGAQGain = 16;
var_immediate_update_pipe("VGAQGain");


staticObjMapUpdateRate = 40.0;			#clutter-map update time constant (sec)
var_immediate_update_pipe("staticObjMapUpdateRate");

staticObjRem=1;					#enable static object removal (de-clutter)
var_immediate_update_pipe("staticObjRem");

iterations=8000;				#number of integration per acquisition
var_immediate_update_pipe("iterations");

#kalman (used by tracker algorithm, tailored for walking human targer
kalman_meas_unc = 0.3;
kalman_speed_unc = 0.2;
kalman_pos_unc = 0.4;
kalman_acc_unc = 0.25;
kalman_gateInTicks = 15;
kalman_gateOutTicks = 10;
kalman_parRunTicks = 10;
var_immediate_update_pipe("kalman_meas_unc");

#blob filter (segmentation algorithm)
blob_phiSpan = 15*pi/180;
blob_amplDecay = 10;
blob_topDetWndSize = 3;
blob_top2SideThr = 0.9;
blob_sideGuard = 0;
var_immediate_update_pipe("blob_phiSpan");

#signal to noise ratio profile configuration, values are absolute (not dB) and relative to noise floor
SNR0 = 60;
SNR1 = 40;
SNR2 = 3.0;
SNR3 = 3.0;
var_immediate_update_pipe("SNR0");
var_immediate_update_pipe("SNR1");
var_immediate_update_pipe("SNR2");
var_immediate_update_pipe("SNR3");

SNRRange0 = 0.8;
SNRRange1 = 1.2;
SNRRange2 = 2;
var_immediate_update_pipe("SNRRange0");

#this variale is for internal visualization purposes, do not edit
H = [1 0 0 0; 0 0 1 0];


#image calculation parameter
cnvs_algo=1;		#algorithm (0:DAS, 1:DMAS)
cnvs_rhoMin = 0.2;	#downrange min distance (must be greater then xmin) in meters
cnvs_rhoMax = 3; 	#downrange max distance (must be smaller then xmax) in meters
cnvs_rhoStep = 0.15;	#downrange stride in meters
cnvs_azimStep = 5;	#crossrange angular stride (deg)
cnvs_azimMin = -60;	#crossrange angular min bound (deg)
cnvs_azimMax = 60;	#crossrange angular max bound (deg)
var_immediate_update_pipe("cnvs_algo");


var_immediate_command_pipe("start");

#internal variables declaration, do not edit
det2DFS=[];
equlaT = time;
