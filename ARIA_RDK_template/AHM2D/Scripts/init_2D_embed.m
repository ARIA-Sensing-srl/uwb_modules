% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% this script configures the device and enable the embedded reconstruction algorithm
% *************************************************

#verify existence of mandatory variables
if (exist('scan_sequence')==0)
	printf('Error: scan sequence not defined\n')
	return;
end

#Stop module before configure
var_immediate_command("stop");

#Enable onboard reconstruction algorithm
preproc_dcrem_en = 1;
preproc_corr_en = 0;
preproc_corr_matchfilt_en = 1;
appopt_det_algo = 0;
appopt_cplx_image = 0;
appopt_rec_algo_en = 1;

#END OF PARAMETERS
#encode options into command's format
opt_proc_0=preproc_dcrem_en+2*preproc_corr_en+4*preproc_corr_matchfilt_en;
opt_proc_1 = appopt_det_algo+2*appopt_cplx_image+4*appopt_rec_algo_en;
var_immediate_update("opt_proc_0");

#start operations
var_immediate_command("start");

printf("Embed reconstruction init complete\n");


