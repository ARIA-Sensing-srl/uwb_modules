#plot 2D

numData = length(data);
defaultAddr = numData+1; #all not mapped go to last

dataformap = [data 0];

distbinmask = (distbin > 0) .* (distbin < (numData+1));
distbinout = distbinmask.*distbin + (1-distbinmask)*(numData+1);

mapOut = abs(dataformap(distbinout))';

if (sum(sum(mapOut))==0)
  mapOut(1,1)=0.1;
end

%mapOut(min(mapOut)<1e-4)=1e-4;
%mapOut = log(abs(mapOut));
