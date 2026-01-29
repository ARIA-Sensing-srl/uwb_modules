## Copyright (C) 2026 Andrea Mario
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {} {@var{recHander}, @var{AmplitudeCorrection} =} setupLocalReconstruction (@var{config})
## This function initializes variables for local reconstruction algorithm
## @seealso{}
## @end deftypefn

## Author: Aria Sensing srl
## Created: 2026-01-13

function [hradar, AmplCorrection]= setupLocalReconstruction(config)

hradar = [];
AmplCorrection = [];
#Setup data for local algorithm reconstruction

AntennaTx = zeros(4,3);
AntennaRx = zeros(4,3);
AntennaDelayTx = zeros(1, 4);
AntennaDelayRx = zeros(1, 4);
AntennaAmplTx = zeros(1, 4);
AntennaAmplRx = zeros(1, 4);


for N = 1:4
  AntennaRx(config.rxAnt(N).ID+1,:) = [0 config.rxAnt(N).X config.rxAnt(N).Y];
  AntennaTx(config.txAnt(N).ID+1,:) = [0 config.txAnt(N).X config.txAnt(N).Y];
  AntennaDelayTx(N) = config.txAnt(N).delay;
  AntennaDelayRx(N) = config.rxAnt(N).delay;
  AntennaAmplTx(N) = config.txAnt(N).ampl;
  AntennaAmplRx(N) = config.rxAnt(N).ampl;
end

scan_sequence = log2([config.txMask' config.rxMask']);

numSeq = size(scan_sequence, 1);
hradar.TxRxCycle = zeros(2,4,numSeq);
for k = 1:numSeq
  hradar.TxRxCycle(1, scan_sequence(k,1)+1, k) = 1;
  hradar.TxRxCycle(2, scan_sequence(k,2)+1, k) = 1;
endfor

AmplCorrection = zeros(1,size(scan_sequence, 1));
for N = 1:length(AmplCorrection)
  AmplCorrection(N) = AntennaAmplTx(scan_sequence(N,1)+1) * AntennaAmplRx(scan_sequence(N,2)+1);
endfor


hradar.CoreFrequency = config.fs;
hradar.txCenterFrequency = config.fcarrier;
hradar.TxAntPosition = AntennaTx;
hradar.RxAntPosition = AntennaRx;
hradar.FixedTxToAntennaDelays = AntennaDelayTx;
hradar.FixedRxToAntennaDelays = AntennaDelayRx;
NumTx = size(AntennaTx, 1);
NumRx = size(AntennaRx, 1);

hradar.FixedTxToAntennaDelays = hradar.FixedTxToAntennaDelays - config.RhoRange(1)*2/3e8;

endfunction
