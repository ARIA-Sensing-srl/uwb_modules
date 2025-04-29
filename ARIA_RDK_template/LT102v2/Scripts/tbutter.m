## Copyright (C) 1999 Paul Kienzle <pkienzle@users.sf.net>
## Copyright (C) 2003 Doug Stewart <dastew@sympatico.ca>
## Copyright (C) 2011 Alexander Klein <alexander.klein@math.uni-giessen.de>
## Copyright (C) 2018 John W. Eaton
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING. If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {[@var{b}, @var{a}] =} butter (@var{n}, @var{wc})
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} butter (@var{n}, @var{wc}, @var{filter_type})
## @deftypefnx {Function File} {[@var{z}, @var{p}, @var{g}] =} butter (@dots{})
## @deftypefnx {Function File} {[@var{a}, @var{b}, @var{c}, @var{d}] =} butter (@dots{})
## @deftypefnx {Function File} {[@dots{}] =} butter (@dots{}, "s")
## Generate a Butterworth filter.
## Default is a discrete space (Z) filter.
##
## The cutoff frequency, @var{wc} should be specified in radians for
## analog filters.  For digital filters, it must be a value between zero
## and one.  For bandpass filters, @var{wc} is a two-element vector
## with @code{w(1) < w(2)}.
##
## The filter type must be one of @qcode{"low"}, @qcode{"high"},
## @qcode{"bandpass"}, or @qcode{"stop"}.  The default is @qcode{"low"}
## if @var{wc} is a scalar and @qcode{"bandpass"} if @var{wc} is a
## two-element vector.
##
## If the final input argument is @qcode{"s"} design an analog Laplace
## space filter.
##
## Low pass filter with cutoff @code{pi*Wc} radians:
##
## @example
## [b, a] = butter (n, Wc)
## @end example
##
## High pass filter with cutoff @code{pi*Wc} radians:
##
## @example
## [b, a] = butter (n, Wc, "high")
## @end example
##
## Band pass filter with edges @code{pi*Wl} and @code{pi*Wh} radians:
##
## @example
## [b, a] = butter (n, [Wl, Wh])
## @end example
##
## Band reject filter with edges @code{pi*Wl} and @code{pi*Wh} radians:
##
## @example
## [b, a] = butter (n, [Wl, Wh], "stop")
## @end example
##
## Return filter as zero-pole-gain rather than coefficients of the
## numerator and denominator polynomials:
##
## @example
## [z, p, g] = butter (@dots{})
## @end example
##
## Return a Laplace space filter, @var{Wc} can be larger than 1:
##
## @example
## [@dots{}] = butter (@dots{}, "s")
## @end example
##
## Return state-space matrices:
##
## @example
## [a, b, c, d] = butter (@dots{})
## @end example
##
## References:
##
## Proakis & Manolakis (1992). Digital Signal Processing. New York:
## Macmillan Publishing Company.
## @end deftypefn

function [a, b, c, d] = tbutter (n, wc, varargin)

cuicciioc
  a = 0;
  b= 0;
  c=0;
  d=0;
  if (nargin > 4 || nargin < 2 || nargout > 4)
    #print_usage ();
    return;
  endif
  c=1
endfunction

%!shared sf, sf2, off_db
%! off_db = 0.5;
%! ## Sampling frequency must be that high to make the low pass filters pass.
%! sf = 6000; sf2 = sf/2;
%! data=[sinetone(5,sf,10,1),sinetone(10,sf,10,1),sinetone(50,sf,10,1),sinetone(200,sf,10,1),sinetone(400,sf,10,1)];

%!test
%! ## Test low pass order 1 with 3dB @ 50Hz
%! data=[sinetone(5,sf,10,1),sinetone(10,sf,10,1),sinetone(50,sf,10,1),sinetone(200,sf,10,1),sinetone(400,sf,10,1)];
%! [b, a] = butter ( 1, 50 / sf2 );
%! filtered = filter ( b, a, data );
%! damp_db = 20 * log10 ( max ( filtered ( end - sf : end, : ) ) );
%! assert ( [ damp_db( 4 ) - damp_db( 5 ), damp_db( 1 : 3 ) ], [ 6 0 0 -3 ], off_db )

%!test
%! ## Test low pass order 4 with 3dB @ 50Hz
%! data=[sinetone(5,sf,10,1),sinetone(10,sf,10,1),sinetone(50,sf,10,1),sinetone(200,sf,10,1),sinetone(400,sf,10,1)];
%! [b, a] = butter ( 4, 50 / sf2 );
%! filtered = filter ( b, a, data );
%! damp_db = 20 * log10 ( max ( filtered ( end - sf : end, : ) ) );
%! assert ( [ damp_db( 4 ) - damp_db( 5 ), damp_db( 1 : 3 ) ], [ 24 0 0 -3 ], off_db )

%!test
%! ## Test high pass order 1 with 3dB @ 50Hz
%! data=[sinetone(5,sf,10,1),sinetone(10,sf,10,1),sinetone(50,sf,10,1),sinetone(200,sf,10,1),sinetone(400,sf,10,1)];
%! [b, a] = butter ( 1, 50 / sf2, "high" );
%! filtered = filter ( b, a, data );
%! damp_db = 20 * log10 ( max ( filtered ( end - sf : end, : ) ) );
%! assert ( [ damp_db( 2 ) - damp_db( 1 ), damp_db( 3 : end ) ], [ 6 -3 0 0 ], off_db )

%!test
%! ## Test high pass order 4 with 3dB @ 50Hz
%! data=[sinetone(5,sf,10,1),sinetone(10,sf,10,1),sinetone(50,sf,10,1),sinetone(200,sf,10,1),sinetone(400,sf,10,1)];
%! [b, a] = butter ( 4, 50 / sf2, "high" );
%! filtered = filter ( b, a, data );
%! damp_db = 20 * log10 ( max ( filtered ( end - sf : end, : ) ) );
%! assert ( [ damp_db( 2 ) - damp_db( 1 ), damp_db( 3 : end ) ], [ 24 -3 0 0 ], off_db )

%% Test input validation
%!error [a, b] = butter ()
%!error [a, b] = butter (1)
%!error [a, b] = butter (1, 2, 3, 4, 5)
%!error [a, b] = butter (.5, .2)
%!error [a, b] = butter (3, .2, "invalid")

%!error [a, b] = butter (9, .6, "stop")
%!error [a, b] = butter (9, .6, "bandpass")

%!error [a, b] = butter (9, .6, "s", "high")

%% Test output orientation
%!test
%! butter (9, .6);
%! assert (isrow (ans));
%!test
%! A = butter (9, .6);
%! assert (isrow (A));
%!test
%! [A, B] = butter (9, .6);
%! assert (isrow (A));
%! assert (isrow (B));
%!test
%! [z, p, g] = butter (9, .6);
%! assert (iscolumn (z));
%! assert (iscolumn (p));
%! assert (isscalar (g));
%!test
%! [a, b, c, d] = butter (9, .6);
%! assert (ismatrix (a));
%! assert (iscolumn (b));
%! assert (isrow (c));
%! assert (isscalar (d));

%!demo
%! sf = 800; sf2 = sf/2;
%! data=[[1;zeros(sf-1,1)],sinetone(25,sf,1,1),sinetone(50,sf,1,1),sinetone(100,sf,1,1)];
%! [b,a]=butter ( 1, 50 / sf2 );
%! filtered = filter(b,a,data);
%!
%! clf
%! subplot ( columns ( filtered ), 1, 1)
%! plot(filtered(:,1),";Impulse response;")
%! subplot ( columns ( filtered ), 1, 2 )
%! plot(filtered(:,2),";25Hz response;")
%! subplot ( columns ( filtered ), 1, 3 )
%! plot(filtered(:,3),";50Hz response;")
%! subplot ( columns ( filtered ), 1, 4 )
%! plot(filtered(:,4),";100Hz response;")

