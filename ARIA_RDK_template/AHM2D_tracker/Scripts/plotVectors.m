% *************************************************
% ARIA Sensing srl 2025
% this script generate data array from tracker info to be plotted
% *************************************************

tr_x =[];
tr_y =[];
tr_vx=[];
tr_vy=[];
polarity = 1;

if (isempty(detOut) == 0)
	numTargets = size(detOut,1);
	for N=1:numTargets 
		curSV = detFullState(N).StateVector;
		tr_x = [tr_x polarity*curSV(1)];
		tr_y = [tr_y curSV(3)];
		tr_vx = [tr_vx polarity*curSV(2)];
		tr_vy = [tr_vy curSV(4)];
	end
        tr_vx = tr_vx*2;
        tr_vy = tr_vy *2;
end
