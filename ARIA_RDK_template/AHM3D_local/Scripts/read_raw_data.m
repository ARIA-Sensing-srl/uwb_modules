% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% *************************************************

var_immediate_inquiry("data_mult");
[output_data_final] = msgdec_raw_data_multiple(data_mult);
if (opt_proc1 == 0)
	for N=1:length(AmplCorrection)
		output_data_final(N,:) = output_data_final(N,:) * AmplCorrection(N);
	end
end

