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
## @deftypefn {} {@var{interface handler} =} openDevice (@var{interface}, @var{baudrate})
## open device and check if valid module is detectable
##
## @var{interface}: input for serial string, if empty function scan across available serial port
##
## @var{baudrate}: user provided baudrate, if empty default is used 921600
##
## @var{interface handler}: serial port handler, or empty if no available device are detected
## @seealso{}
## @end deftypefn

## Author: Aria Sensing srl
## Created: 2026-01-13

function board = openDevice (str, br)
  board=[];
  if (isempty(br))
    br = 921600;
  endif
  isValid = 0;
  if (isempty(str))
    #scan
    serialList=serialportlist();
    numSerials = length(serialList);
  else
    serialList={str};
    numSerials=1;
  end

  if (numSerials == 0)
    fprintf("No serial port available\n");
    return;
  endif
  for N = 1:numSerials
    try
      curSerialName = serialList{N};
      board = serial(curSerialName);
      set(board, 'baudrate', br);     % See List Below
      set(board, 'bytesize', 8);
      set(board, 'parity', 'n');
      set(board, 'stopbits', 1);
      set(board, 'timeout', 0.1);
      fopen(board);
      isValid = 1;
      catch
    end_try_catch
    if (isValid)
      srl_flush(board);
      pause(.1);
      srl_flush(board);
      rc=0;
      try
        [rc] = get_version_fw(board);
      catch
        rc=1;
      end_try_catch
      if (rc)
        fclose(board);
        isValid = 0;
      else
        break;
      endif
    end
  endfor
  if (isValid==0)
    board = [];
  endif

endfunction
