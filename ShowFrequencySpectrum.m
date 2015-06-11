file = '/Users/jearly/Dropbox/Documents/Projects/ForcedDissipativeQGTurbulence/Experiment_06/Experiment6Trajectories8700.mat';
% file = '/Users/jearly/Dropbox/Documents/Projects/ForcedDissipativeQGTurbulence/Experiment_07/Experiment7Trajectories1400.mat';

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
plot(f_year,spp(:,1:5)), ylog
hold on
plot(f_year2,vmedian(s,2),'k','LineWidth',2)
plot(-f_year,snn(:,1:5))
xlim([-52,52])
xlabel('cycles per year')

figure
plot(f_year2,s(:,1:5)),ylog
hold on
plot(f_year2,vmedian(s,2),'k','LineWidth',2)
xlim([-15,15])
xlabel('cycles per year')
vlines([0],'k')
title(sprintf('Isotropic Diffusivity of %.0f m^2/s',mean(spp(1,:))/4))

figure
plot(f_year2,s(:,1:5)),ylog
hold on
plot(f_year2,vmedian(s,2),'k','LineWidth',2)
xlim([-2,2])
xlabel('cycles per year')
vlines([0],'k')
title(sprintf('Isotropic Diffusivity of %.0f m^2/s',mean(spp(1,:))/4))

figure
plot(f_year,vmedian(spp,2)), xlog, ylog
hold on
plot(f_year,vmedian(snn,2))
plot(f_year,vmean(spp,2))
plot(f_year,vmean(snn,2))
ylim([1e-4 1e5])
xlabel('cycles per year')
ylabel('m^2/s')

% Frictional
% delta = 3.5;
% h2 = (10)^2;
delta = 2.5;
h2 = (6)^2;
A = mean(spp(1,:))*h2^delta;
S_energy = A ./ ( f_year.*f_year + h2 ).^delta;
hold on
plot(f_year,S_energy)

legend('median +', 'median -', 'mean +', 'mean -', 'Example Matern')
