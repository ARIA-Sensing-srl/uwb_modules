% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% this script call the reconstruction algorithm and compute the output image
% *************************************************

output_image = transpose(imageReconstruction(hradar,output_data_final, AzimBase, Rhobase ,algo));

#Output image is stored into a 2D array as Rho(downrange) x Azimuth

##OUTPUT TO PLOT img2plot
if(isempty(strfind(algo, "DMAS")))
	img2plot = abs(output_image);
else
	img2plot = real(output_image);
endif
