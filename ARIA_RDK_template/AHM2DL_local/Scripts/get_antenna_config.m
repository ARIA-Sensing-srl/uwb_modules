% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% this script gets the antenna topology to be used by the image calculation algorithm
% *************************************************

var_immediate_inquiry("get_ant_array");
[rxAnt, txAnt] = msgdec_ant_config(get_ant_array);
