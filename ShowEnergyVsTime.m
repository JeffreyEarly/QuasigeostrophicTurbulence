addpath('/Users/jearly/Dropbox/Documents/Matlab/jlab')
addpath('../GLOceanKit/Matlab/')
file = '/Volumes/Data/Isotropy/TurbulenceIsotropic@x1.nc';

g = 9.81;
L_R = ncreadatt(file, '/', 'length_scale');

[x,y,t] = FieldsFromTurbulenceFile( file, 0, 'x', 'y', 't');

totalEnergy = zeros(size(t));
for timeIndex=1:10:length(t)
    [sshFD, k, l, f0] = FieldsFromTurbulenceFile( file, timeIndex, 'ssh_fd', 'k', 'l', 'f0');
    [kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, L_R );
    totalEnergy(timeIndex) = trapz(kMag,energyMag);
end

figure
plot(t/86400,totalEnergy)