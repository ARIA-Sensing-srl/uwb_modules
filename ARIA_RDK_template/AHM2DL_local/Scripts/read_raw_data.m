% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% The script gets the data from the module and decode the serial stream into a 2D array
% *************************************************

var_immediate_inquiry("data_mult");
[output_data_final] = msgdec_raw_data_multiple(data_mult);
#Data are organized into a 2D array, every row is the output of a single rx/tx antenna pair (output follows the order set into scan_sequence)
#For local reconstruction the polarity of the antenna is corrected into this script
if (opt_proc_1 == 0)
	for N=1:length(AmplCorrection)
		output_data_final(N,:) = output_data_final(N,:) * AmplCorrection(N);
	end
end
