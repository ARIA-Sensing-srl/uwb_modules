% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% *************************************************

output_image = imageReconstruction(hradar,output_data_final, AzimBase, Rhobase ,algo);
if(isempty(strfind(algo, "DMAS")))
	img2plot = abs(output_image);
else
	img2plot = real(output_image);
endif
