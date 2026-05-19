% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% This script is for visualization purpose. It searches the maximum amplitude of the reconstructed volume
% and create two images: one along the XY plane and one along 
% the YZ plane, both the planes cross the point where the max amplitude is detected
% *************************************************

#generate two 2D images by picking the maximum intensity and slice the volume along ortogonal planes


if(isempty(strfind(algo, "DMAS")))
	output_volume = abs(output_volume);
else
	output_volume= real(output_volume);
endif

[maxR,maxRI] = max(output_volume);
maxR = squeeze(maxR);
maxRI = squeeze(maxRI);

[maxR2, maxR2I] = max(maxR);
maxR2 = squeeze(maxR2);
maxR2I = squeeze(maxR2I);
[maxR3, maxR3I] = max(maxR2);

RI = maxRI(maxR2I(maxR3I), maxR3I);

##OUTPUTS TO PLOT
yzplane = abs(squeeze(output_volume(RI, :,:)));
xyplane = abs(squeeze(output_volume(:,:, maxR3I)));
