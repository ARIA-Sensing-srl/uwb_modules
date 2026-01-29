% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% this script configures the device and enable the embedded reconstruction algorithm
% *************************************************

#verify existence of mandatory variables


#Stop module before configure
var_immediate_command("stop");

embeddedImageAlgo=1; #enable internal imaging algorithm
var_immediate_update("embeddedImageAlgo");
cnvs_algo=1;
cnvs_rhoMin = RhoRange(1);
cnvs_rhoMax = RhoRange(2); 
cnvs_rhoStep = RhoStep;
cnvs_azimStep = AzimStep*180/pi;
cnvs_azimMin = AzimRange(1)*180/pi;
cnvs_azimMax = AzimRange(2)*180/pi;
var_immediate_update("cnvs_algo");
#var_immediate_inquiry("cnvs_algo");


#start operations
var_immediate_command("start");

printf("Embed reconstruction init complete\n");


