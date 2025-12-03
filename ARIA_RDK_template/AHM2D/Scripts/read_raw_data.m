% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% The script gets the data from the module and decode the serial stream into a 2D array
% *************************************************

var_immediate_inquiry("data_mult");
[output_data_final] = msgdec_raw_data_multiple(data_mult);
#Data are organized into a 2D array, every row is the output of a single rx/tx antenna pair (output follows the order set into scan_sequence)
#NOTE: when embedded reconstruction is enabled, the polarity of each stream is adjusted and it could be not the same of the original signal.
