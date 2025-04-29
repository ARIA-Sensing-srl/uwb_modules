#init for 2d

datastep = 6.4300411e-3;
ybase = min_range:0.05:max_range;

xmin = max_range * sind(-45);
xmax = max_range * sind(45);
xbase = xmin:0.05:xmax;

[X,Y] = ndgrid(xbase, ybase);

dist = sqrt(X.^2 + Y.^2);
distbin = round((dist - min_range)/datastep);

