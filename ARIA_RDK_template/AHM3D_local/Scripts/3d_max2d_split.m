% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
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
yzplane = abs(squeeze(output_volume(RI, :,:)));
xyplane = abs(squeeze(output_volume(:,:, maxR3I)));
