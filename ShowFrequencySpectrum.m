file = '/Users/jearly/Dropbox/Documents/Projects/ForcedDissipativeQGTurbulence/Experiment_06/Experiment6Trajectories.mat';
load(file)

dt = t(2)-t(1);
cv = (diff(xpos,1,1)+sqrt(-1)*diff(ypos,1,1))/dt;
% cv = cv(1:2000,:);
[psi,lambda]=sleptap(size(cv,1),4);
[f,spp,snn,spn]=mspec(dt,cv,psi);

f_day = f*86400/2/pi; % cycles per day
f_year = f_day*365.24;

f_year2 = cat(1,-flip(f_year),f_year);
s = cat(1,flip(snn,1),spp);

figure
plot(f_year2,s(:,1:5)),ylog
xlim([-15,15])
xlabel('cycles per year')
vlines([0],'k')
title(sprintf('Isotropic Diffusivity of %.0f m^2/s',mean(spp(1,:))/4))

% figure
% plot(f_year,spp(:,1:5)), ylog
% hold on
% plot(-f_year,snn(:,1:5))
% xlim([-52,52])
% xlabel('cycles per year')
