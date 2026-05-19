% *************************************************
% ARIA Sensing srl 2025
% Confidential-reserved
% *************************************************

hradar = beamforming3d(hradar,output_data_final, AzimBase, ZenithBase, Rhobase ,algo);
output_volume = hradar.beamformed_image;


#output is a volume (spherical coordinates) stored into a 3D array organized as rho(downrange) x Azimuth x Zenith
