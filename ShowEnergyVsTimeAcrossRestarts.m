addpath(genpath('/Users/jearly/Documents/jlab'))
addpath(genpath('../GLOceanKit/Matlab/'))
basename = '/Users/jearly/Desktop/Isotropy/TurbulenceIsotropic';

file = sprintf('%s@x1.nc',basename);

g = 9.81;
L_R = ncreadatt(file, '/', 'length_scale');

totalTime = [];
totalEnergy = [];
loop=1;
endTime = 0;
restartTimes = [];
while (exist(file,'file'))
	
	
	[x,y,t] = FieldsFromTurbulenceFile( file, 0, 'x', 'y', 't');
	restartTimes(end+1)=endTime+t(end);
	if (length(t) > 99)
		stride = 10;
	else
		stride = 1;
	end
	
	for timeIndex=1:stride:length(t)
		[sshFD, k, l, f0] = FieldsFromTurbulenceFile( file, timeIndex, 'ssh_fd', 'k', 'l', 'f0');
		[kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, L_R );
		totalEnergy(end+1) = trapz(kMag,energyMag);
		totalTime(end+1) = endTime + t(timeIndex);
	end

	file = sprintf('%s@x%d.nc',basename,2^loop);
	loop = loop+1;
	
	endTime = endTime+t(end);
end


figure
plot(totalTime/86400,totalEnergy)
hold on
vlines(restartTimes/86400)