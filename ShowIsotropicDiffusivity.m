addpath(genpath('../GLOceanKit/Matlab'));
file = '/Users/jearly/Dropbox/Documents/Projects/ForcedDissipativeQGTurbulence/Experiment_07/Experiment7Trajectories1400.mat';
load(file)
x = xpos;
y = ypos;

[x_com, y_com, q, r] = CenterOfMass( x, y );

[minD, maxD, theta] = SecondMomentMatrix( x, y, 'eigen' );

D2 = (minD+maxD)/2;
[p,S,mu]=polyfit(t,D2,1);
kappa_fit = 0.5*p(1)/mu(2);
fprintf('diffusive linear fit: kappa = %f\n', kappa_fit)

figure
plot(t/86400, D2)
xlabel('time (days)')
ylabel('mean square separation (m^2)')
title(sprintf('Isotropic Diffusivity of %.0f m^2/s',kappa_fit))