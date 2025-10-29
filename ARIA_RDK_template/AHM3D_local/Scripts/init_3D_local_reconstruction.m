% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% *************************************************

#verify existence of mandatory variables
if (exist('scan_sequence')==0)
	printf('Error: scan sequence not defined\n')
	return;
end

#setup local variables
algo="DMAS_SR";
RhoStep = 0.07;                  	#Downrange resoluton
RhoRange = [0.5 5.0];              	#Downrange range
ZenithStep = 5 * pi/180;         	#Zenithal angle resolution
ZenithRange = [45 135] * pi/180; 	#Zenithal angle range
AzimStep = 5 * pi/180;         		#Aximuth angle resolution
AzimRange = [-45 45] * pi/180; 		#Azimuth angle range




#Local initialization

#get antennas configurations from radar
get_antenna_config

if (isempty(rxAnt) || isempty(txAnt))
  printf("antennas definition missing\n");
  return;
end


numSeq = size(scan_sequence, 1);
hradar.TxRxCycle = zeros(2,4,numSeq);
for k = 1:numSeq
  hradar.TxRxCycle(1, scan_sequence(k,1)+1, k) = 1;
  hradar.TxRxCycle(2, scan_sequence(k,2)+1, k) = 1;
endfor

Rhobase = RhoRange(1):RhoStep:RhoRange(2);
ZenithBase = ZenithRange(1):ZenithStep:ZenithRange(2);
AzimBase = AzimRange(1):AzimStep:AzimRange(2);

AntennaTx = zeros(4,3);
AntennaRx = zeros(4,3);
AntennaDelayTx = zeros(1, 4);
AntennaDelayRx = zeros(1, 4);
AntennaAmplTx = zeros(1, 4);
AntennaAmplRx = zeros(1, 4);


for N = 1:4
  AntennaRx(rxAnt(N).ID+1,:) = [0 rxAnt(N).X rxAnt(N).Y];
  AntennaTx(txAnt(N).ID+1,:) = [0 txAnt(N).X txAnt(N).Y];
  AntennaDelayTx(N) = txAnt(N).delay;
  AntennaDelayRx(N) = rxAnt(N).delay;
  AntennaAmplTx(N) = txAnt(N).ampl;
  AntennaAmplRx(N) = rxAnt(N).ampl;
end


AmplCorrection = zeros(1,size(scan_sequence, 1));
for N = 1:length(AmplCorrection)
  AmplCorrection(N) = AntennaAmplTx(scan_sequence(N,1)+1) * AntennaAmplRx(scan_sequence(N,2)+1);
endfor


hradar.CoreFrequency = single(fs)*1e6;
hradar.txCenterFrequency = single(fcarrier)*1e6;
hradar.TxAntPosition = AntennaTx;
hradar.RxAntPosition = AntennaRx;
hradar.FixedTxToAntennaDelays = AntennaDelayTx;
hradar.FixedRxToAntennaDelays = AntennaDelayRx;
NumTx = size(AntennaTx, 1);
NumRx = size(AntennaRx, 1);

hradar.FixedTxToAntennaDelays = hradar.FixedTxToAntennaDelays - xmin*2/3e8;
printf("Local reconstruction init complete\n");


