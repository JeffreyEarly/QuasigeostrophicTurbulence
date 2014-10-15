day = 2001;

addpath('../GLOceanKit/Matlab/')
file = '/Users/jearly/Documents/Data/Anisotropic Run for Adam/QGBetaPlaneTurbulenceFloats_experiment_04.nc';
file = '/Users/jearly/Documents/Data/ForcedDissipativeQGTurbulence/QGFPlaneTurbulence_256_experiment_02.nc';
file = '/Volumes/Data/ForcedDissipativeQGTurbulence/QGFPlaneTurbulence_experiment_02.nc'
file = '/Users/jearly/Desktop/QGTurbulenceTest.nc';
output = '/Users/jearly/Dropbox/Documents/Projects/ForcedDissipativeQGTurbulence/Experiment_02_images/FourPanel.png'
% file = '/Users/jearly/Dropbox/Documents/Projects/AnisotropicDiffusivity/QGBetaPlaneTurbulence_256_large_forcing_restarted.nc';

x = ncread(file, 'x');
y = ncread(file, 'y');
t = ncread(file, 'time');

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

% k_r = 0;
% r = 0;

if (k_alpha > k_r)
	k_damp = k_alpha;
else
	k_damp = k_r;
end

g = 9.81;
f0 = 2 * 7.2921E-5 * sin( latitude*pi/180. );
R = 6.371e6;
beta = 2 * 7.2921E-5 * cos( latitude*pi/180. ) / R;

t = t/86400;

timeIndex = find( t <= day, 1, 'last');

[u, v, rv, ssh, sshFD, k, l] = FieldsFromTurbulenceFile( file, timeIndex, 'u', 'v', 'rv', 'ssh', 'ssh_fd', 'k', 'l');


figure('Position', [50 50 1000 1000])
set(gcf,'PaperPositionMode','auto')
set(gcf, 'Color', 'w');

%%%%%%%%%%%%%%%%%%%%%
%
% SSH Plot
%
%%%%%%%%%%%%%%%%%%%%%%

subplot(2,2,1)
pcolor(x, y, ssh(:,:)), axis equal tight, shading interp
title(sprintf('SSH'))
set( gca, 'xtick', [])
set( gca, 'ytick', [])

%%%%%%%%%%%%%%%%%%%%%
%
% RV Plot
%
%%%%%%%%%%%%%%%%%%%%%%

subplot(2,2,2)
pcolor(x, y, rv(:,:,end)), axis equal tight, shading interp
title(sprintf('Relative vorticity'))
set( gca, 'xtick', [])
set( gca, 'ytick', [])


%%%%%%%%%%%%%%%%%%%%%
%
% Speed Plot
%
%%%%%%%%%%%%%%%%%%%%%%


subplot(2,2,3)

speed = sqrt( u.*u + v.*v );

u = u./speed;
v = v./speed;

stride=20;

pcolor(x, y, speed), axis equal tight, shading interp
hold on
quiver(x(1:stride:end),y(1:stride:end),u(1:stride:end,1:stride:end),v(1:stride:end,1:stride:end), 'black')
title('Snapshot of the Eulerian Velocity Field')
set( gca, 'xtick', [])
set( gca, 'ytick', [])


%%%%%%%%%%%%%%%%%%%%%
%
% Energy Plot
%
%%%%%%%%%%%%%%%%%%%%%%

subplot(2,2,4)

[kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, length_scale );

enstrophyStartIndex = find( kMag > k_f + k_f_width/2, 1, 'first')+1;
enstrophyEndIndex = find( kMag < k_nu, 1, 'last')-1;

energyStartIndex = 2;
energyEndIndex = find( kMag < k_f - k_f_width/2, 1, 'last')-1;

% This coefficient will place a k^-3 line just above the enstrophy cascade region
enstrophyCoeff = 10^(log10( energyMag(enstrophyStartIndex) ) + 0.5 +3*log10( kMag(enstrophyStartIndex) ));


loglog(kMag, energyMag, 'blue', 'LineWidth', 1.5)
hold on
loglog(kMag(enstrophyStartIndex:enstrophyEndIndex),  enstrophyCoeff*(kMag(enstrophyStartIndex:enstrophyEndIndex)).^(-3), 'black', 'LineWidth', 1.0)
hold off

vlines(  k_f - k_f_width/2 );
vlines(  k_f + k_f_width/2 );
vlines(  k_nu );
vlines(  k_damp );

xlabel('k')
ylabel('E(k)')

xl = 10^( log10(kMag(enstrophyStartIndex)) + (log10(kMag(enstrophyEndIndex))-log10(kMag(enstrophyStartIndex)))/2);
yl = (10^0.5)*enstrophyCoeff*xl^(-3);
text(double(xl), double(yl), 'k^{-3}') 

(log10(energyMag(enstrophyEndIndex))-log10(energyMag(enstrophyStartIndex)))/(log10(kMag(enstrophyEndIndex))-log10(kMag(enstrophyStartIndex)))

% This coefficient will place a k^-5/3 line just above the energy cascade region
if (energyEndIndex > energyStartIndex)
	energyCoeff = 10^(log10( energyMag(energyEndIndex) ) + 0.5 + (5/3)*log10( kMag(energyEndIndex) ));
	hold on
	loglog(kMag(energyStartIndex:energyEndIndex),  energyCoeff*(kMag(energyStartIndex:energyEndIndex)).^(-5/3), 'black', 'LineWidth', 1.0)
	hold off
	xl = 10^( log10(kMag(energyStartIndex)) + (log10(kMag(energyEndIndex))-log10(kMag(energyStartIndex)))/2);
	yl = (10^0.5)*energyCoeff*xl^(-5/3);
	text(double(xl), double(yl), 'k^{-5/3}') 
end

title('Eulerian Energy Spectrum')
xlim([min(abs(k)) max(abs(k))])
ylim([energyMag(enstrophyEndIndex)/100 10*max(energyMag)])

set( gca, 'xtick', [])
set( gca, 'ytick', [])

packcols(2,2)

ScaleFactor = 4;
% print(sprintf('-r%d',72*ScaleFactor), '-dpng', output );