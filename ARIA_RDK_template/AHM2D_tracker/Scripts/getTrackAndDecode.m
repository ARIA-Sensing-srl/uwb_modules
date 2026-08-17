% *************************************************
% ARIA Sensing srl 2025
% This script get detection/tracker info from the device
% *************************************************


det2DFSOld = det2DFS;
ret = var_immediate_inquiry_pipe("det2DFS");

bytesPerPoint = 20*4+2;
type = 4;
detOut=[];
ret_code=0;

if (isempty(det2DFS))
  return;
end
#this routine checks if any changes has occurred fot det2DFS, if so, scripts execution continues.
if (isempty(det2DFSOld)==0)
  if(length(det2DFSOld)==length(det2DFS))
    cmpOut = sum(det2DFSOld==det2DFS) == length(det2DFS);
  else
    cmpOut = 0;
  end
  if(cmpOut)
    equlaTNew = time;
    if(equlaTNew - equlaT > 2)
      return;
    end
  else
    equlaT=time;
  end
end

det2DFS = [0 det2DFS];

if (isempty(det2DFS)==0)
    if (det2DFS(1)==0)
        if (length(det2DFS)>1)
          det2DFS = det2DFS(2:end);
          if (mod(length(det2DFS),bytesPerPoint) ~= 0)
            ret_code = 1; #malformed
            detOut=[];
            return;
          endif
          Nblobs = length(det2DFS)/bytesPerPoint;

          if (type == 0)
            detOut = zeros(Nblobs, 2);
            index = 1;
            for N = 1:Nblobs
              [index, detOut(N,1)] = get_float(det2DFS, index);
              [index, detOut(N,2)] = get_float(det2DFS, index);
            endfor
          elseif (type == 1 || type==2)
            #position of the track
            detOut = zeros(Nblobs, 3);
            index = 1;
            for N = 1:Nblobs
              [index, detOut(N,1)] = get_float(det2DFS, index);
              [index, detOut(N,2)] = get_float(det2DFS, index);
              [index, detOut(N,3)] = get_int16(det2DFS, index);
            endfor
          else
            #position + sv + P + ID
            detOut = zeros(Nblobs, 3);
            index = 1;
            for N=1:Nblobs
              curSV = zeros(4,1);
              for t = 1:4
                [index, curSV(t)] = get_float(det2DFS, index);
              endfor
              curP = zeros(1,4);
              for t = 1:16
                [index, curP(t)] = get_float(det2DFS, index);
              endfor
              curP = reshape(curP, 4, 4)';
              [index, curID] = get_int16(det2DFS, index);

              detFullState(N).StateVector = curSV;
              detFullState(N).P = curP;
              detFullState(N).ID = curID;

              #populate detection out
              detOut(N, 1:2) = curSV([1 3])';
              detOut(N, 3) = curID;
            endfor
          endif
        endif
    else
        ret_code = 1;
        detOut=[];
        return;
    end;
else
    ret_code=1;
    detOut=[];
	return;
end
