% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% this script get the computed image
% *************************************************

var_immediate_inquiry("get_image");
output_image = msgdec_image( get_image );
#output image, reconstructed in spherical coordinates, is stored into a 2D array as Rho(downrange) x Azimuth
