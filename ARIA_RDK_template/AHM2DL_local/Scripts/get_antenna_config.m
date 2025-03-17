% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% *************************************************

var_immediate_inquiry("get_ant_array");
[rxAnt, txAnt] = msgdec_ant_config(get_ant_array);
