%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	Make a movie from the forced-dissipative QG turbulence
%	in GLNumericalModelingKit.
%
%	2012 October 2 -- Jeffrey J. Early
%


addpath('/Users/jearly/Dropbox/Documents/Matlab/jlab')
addpath('../GLOceanKit/Matlab/')
file = '/Volumes/OceanTransfer/AnisotropicExperiments/AnisotropicTurbulenceSpinUpModerateForcing.nc';
FramesFolder = '/Volumes/OceanTransfer/AnisotropicExperiments/AnisotropicTurbulenceSpinUpModerateForcingFrames';
startIndex = 1000;
day = 2000;
ScaleFactor = 5;

shouldShowEnergy = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	Make the frames folder
%
if exist(FramesFolder, 'dir') == 0
	mkdir(FramesFolder);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	Read in the problem dimensions
%
[x,y,t,f0] = FieldsFromTurbulenceFile( file, 0, 'x', 'y', 't','f0');

height_scale = ncreadatt(file, '/', 'height_scale');
time_scale = ncreadatt(file, '/', 'time_scale');
length_scale = ncreadatt(file, '/', 'length_scale');
vorticity_scale = ncreadatt(file, '/', 'vorticity_scale');
k_f = ncreadatt(file, '/', 'forcing_wavenumber');
k_f_width = ncreadatt(file, '/', 'forcing_width');
k_nu = ncreadatt(file, '/', 'viscous_wavenumber');
k_alpha = ncreadatt(file, '/', 'thermal_damping_wavenumber');
k_r = ncreadatt(file, '/', 'frictional_damping_wavenumber');
f_zeta = ncreadatt(file, '/', 'f_zeta');
latitude = ncreadatt(file, '/', 'latitude');
k_max = ncreadatt(file, '/', 'max_resolved_wavenumber');
r = ncreadatt(file, '/', 'r');

g = 9.81;
f0 = 2 * 7.2921E-5 * sin( latitude*pi/180. );
R = 6.371e6;
beta0 = 2 * 7.2921E-5 * cos( latitude*pi/180. ) / R;

if (k_alpha > k_r)
	k_damp = k_alpha;
else
	k_damp = k_r;
end

t = t/86400;
x = x/1000;
y = y/1000;

maxTimeIndex = find( t <= day, 1, 'last');

[ssh, sshFD, rv, k, l, u, v] = FieldsFromTurbulenceFile( file, maxTimeIndex, 'ssh', 'ssh_fd', 'rv', 'k', 'l', 'u', 'v');
maxSSH = max(max(ssh));
minSSH = min(min(ssh));
maxRV = max(max(rv/f0));
minRV = min(min(rv/f0));
u_rms = sqrt(mean(mean(u.*u+v.*v)));

epsilon = (r/time_scale)*u_rms*u_rms;
k_rhines = sqrt( beta0 / (2*u_rms) )/(2*pi); % convert to cycles (using factor of 2 in Sukoriansky, et al. 2007)
k_beta = 0.5*((beta0^3)/(epsilon))^(1/5)/(2*pi); % convert to cycles (using factor of 0.5 in Sukoriansky, et al. 2007)
R_beta = k_beta/k_rhines;
k_r_actual = ((3*6)^(3/2))*((r/time_scale)^3/epsilon)^(1/2)/(2*pi); % From Sukoriansky, et al. 2007

k_damp = k_r_actual;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	Setup wavenumber computation
%

[kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, length_scale );

% Based on the forcing, we know where the inertial ranges are.
energyStartIndex = find( kMag > k_damp, 1, 'first')+1;
energyEndIndex = find( kMag < k_f - k_f_width/2, 1, 'last')-1;

enstrophyStartIndex = find( kMag > k_f + k_f_width/2, 1, 'first')+1;
enstrophyEndIndex = find( kMag < k_nu, 1, 'last')-1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	The stride indicates how many floats we will skip
%

% stride=1, size=3 works well for 512x128
stride = 8;
floatSize = 3.5;

x_float = double(ncread(file, 'x-float'));
y_float = double(ncread(file, 'y-float'));

% Read in the initial position of the floats.
% We will use this information to maintain a constant color on each float.
xposInitial = double(ncread(file, 'x-position', [ceil(stride/2) ceil(stride/2) 1], [length(y_float)/stride length(x_float)/stride 1], [stride stride 1])/1000);
xposInitial = reshape(xposInitial, length(y_float)*length(x_float)/(stride*stride), 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	Setup the figure
%

if (shouldShowEnergy == 1)
	totalPlots = 3;
else
	totalPlots = 2;
end

figure('Position', [50 50 1150 450])
set(gcf,'PaperPositionMode','auto')
set(gcf, 'Color', 'w');

for iTime=startIndex:maxTimeIndex
% for iTime=300:300
    clf
    
	currentPlot = 1;
	[ssh, sshFD, rv] = FieldsFromTurbulenceFile( file, iTime, 'ssh', 'ssh_fd', 'rv');

 	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	% 	Panel 1: relative vorticity
	%
	
	
	rv = double(rv/f0);
	
	rvPlot = subplot(1,totalPlots,currentPlot); currentPlot=currentPlot+1;
    
    theRV = pcolor(x, y, rv);
    theRV.EdgeColor = 'none';
    axis(rvPlot, 'equal', 'tight');
    title(sprintf('Relative vorticity'), 'fontsize', 16)
    rvPlot.XTick = [];
    rvPlot.YTick = [];
    colormap(rvPlot,gray(1024))

  	cb = colorbar( 'location', 'SouthOutside' );
	set(get(cb,'xlabel'),'String', 'Rossby number', 'FontSize', 12.0);
	set( gca, 'clim', [minRV maxRV] );
	
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	% 	Panel 2: Lagrangian particles setup
	%
	
	% read in the position of the floats for the given time
	xpos = double(ncread(file, 'x-position', [ceil(stride/2) ceil(stride/2) iTime], [length(y_float)/stride length(x_float)/stride 1], [stride stride 1])/1000);
	ypos = double(ncread(file, 'y-position', [ceil(stride/2) ceil(stride/2) iTime], [length(y_float)/stride length(x_float)/stride 1], [stride stride 1])/1000);
	
	% make everything a column vector
	xpos = reshape(xpos, length(y_float)*length(x_float)/(stride*stride), 1);
	ypos = reshape(ypos, length(y_float)*length(x_float)/(stride*stride), 1);
	
	% the x direction is periodic, but the floats don't know they wrapped around. 
	xpos = mod( xpos-min(x), max(x)-min(x)+x(2)-x(1) ) + min(x);
	ypos = mod( ypos-min(y), max(y)-min(y)+y(2)-y(1) ) + min(y);

	% default color map is only 128 shades---we need more!
	colormap(parula(1024))
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	% 	Panel 2: Lagrangian particles drawing
	%
	
	particlePlot = subplot(1,totalPlots,currentPlot); currentPlot=currentPlot+1;
	
	% now plot the floats, colored by initial position
	%scatter(xpos, ypos, floatSize*floatSize, xposInitial, 'filled')	
	mesh([xpos';xpos'],[ypos';ypos'],[xposInitial';xposInitial'],'mesh','column','marker','.','MarkerSize',floatSize*floatSize), view(2)
	grid off
	
	% make the axes look better
	set( gca, 'TickDir', 'out');
	set( gca, 'Linewidth', 1.0);
	axis equal tight
	
	% get rid of the xticks because we're going to put a colorbar below with the same info.
	set( gca, 'xtick', [])
	set( gca, 'ytick', [])
	
	xlim([min(x) max(x)])
	ylim([min(y) max(y)])
	
	% label everything
	title( sprintf('Lagrangian floats, day %d @ %02d:00', floor(t(iTime)), round(mod(t(iTime)*24,24))), 'fontsize', 16 );
	%ylabel( 'distance (meters)', 'FontSize', 12.0);
	
	% add a color bar
	cb = colorbar( 'location', 'SouthOutside' );
	set(get(cb,'xlabel'),'String', 'original x-position (km)', 'FontSize', 12.0);
	set( gca, 'clim', [min(x_float)/1000 max(x_float)/1000] );
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	% 	Panel 3: Energy spectrum
	%
	
	if (shouldShowEnergy == 1)
        
        energyPlot = subplot(1,totalPlots,currentPlot); currentPlot=currentPlot+1;

        [kMag, TE, KE, PE, KEx, KEy] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, length_scale );
	
		% This coefficient will place a k^-3 line just above the enstrophy cascade region
		enstrophyCoeff = 10^(log10( energyMag(enstrophyStartIndex) ) + 0.5 +3*log10( kMag(enstrophyStartIndex) ));
	
		subplot(1,3,3)
		loglog(kMag, PE, 'LineWidth', 1.5, 'Color', 0.4*[1 1 1])
		hold on
        loglog(kMag, KEx, 'LineWidth', 3.5, 'Color', 0.0*[1 1 1])
        loglog(kMag, KEy, 'LineWidth', 3.5, 'Color', 0.4*[1 1 1])
		loglog(kMag(enstrophyStartIndex:enstrophyEndIndex),  enstrophyCoeff*(kMag(enstrophyStartIndex:enstrophyEndIndex)).^(-3), 'black', 'LineWidth', 1.0)
		hold off
		xlim([kMag(2) k_nu*1.2])
		ylim( [1e-1 3e5] )
		vlines(  k_f - k_f_width/2 );
		vlines(  k_f + k_f_width/2 );
        vlines(  k_nu );
        vlines(  k_damp );
        
        vlines(  k_beta, 'b' );
        vlines(  k_rhines, 'r' );
        
		xlabel('k')
		set(gca, 'PlotBoxAspectRatio',[1 1 1])
		title(sprintf('E(k), m^3/s^2'), 'fontsize', 16)
	
		xl = 10^( log10(kMag(enstrophyStartIndex)) + (log10(kMag(enstrophyEndIndex))-log10(kMag(enstrophyStartIndex)))/2);
		yl = (10^0.5)*enstrophyCoeff*xl^(-3);
	
		%if ( xl > kMag(2) && xl < (2/3)*kMag(end) && yl > 1e-12 && yl < 1e-2)
			text(double(xl), double(yl), 'k^{-3}')
	% 		disp(sprintf('Drawing k^-3'))
		%end
	
		% This coefficient will place a k^-5/3 line just above the energy cascade region
		if (energyEndIndex > energyStartIndex)
			%if ( xl > kMag(2) && xl < (2/3)*kMag(end) && yl > 1e-12 && yl < 1e-2)
				energyCoeff = 10^(log10( energyMag(energyEndIndex) ) + 0.5 + (5/3)*log10( kMag(energyEndIndex) ));
				hold on
				loglog(kMag(energyStartIndex:energyEndIndex),  energyCoeff*(kMag(energyStartIndex:energyEndIndex)).^(-5/3), 'black', 'LineWidth', 1.0)
				hold off
				xl = 10^( log10(kMag(energyStartIndex)) + (log10(kMag(energyEndIndex))-log10(kMag(energyStartIndex)))/2);
				yl = (10^0.5)*energyCoeff*xl^(-5/3);
				text(double(xl), double(yl), 'k^{-5/3}') 
	% 			disp(sprintf('Drawing k^-5/3'))
			%end
		end
    end
    
    rvPlot.Position = [0.0 0.13 0.33 0.8];
    particlePlot.Position = [0.33 0.13 0.33 0.8];
    energyPlot.Position = [0.67 0.13 0.33 0.8];
    
	%packcols(1,totalPlots)
	
	% write everything out
	output = sprintf('%s/t_%03d', FramesFolder,iTime-1);
	print(sprintf('-r%d',72*ScaleFactor), '-dpng', output );
% 	print('-depsc2', output)
end