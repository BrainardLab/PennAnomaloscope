% PlotArduinoCalibration
%
% Read in the calibration data for one of the ICVS 2025 numbered
% anomaloscopes and plot the spectrum of the primaries.  For most
% anomalocopes, these are the red and green primaries from one side
% and the yellow primary from the other, at their maximum intensities.

% Initialize
clear; close all;

% Get the calibration data
%
% Primaries are in columns of matrix theCalData.primary, order is red,
% green, yellow and if available blue.
%
% Variable theCalData.primary_order is a cell array with strings naming the
% primaries in the order of the columns.
% 
% The wavelengths corresponding to each row of theCalData.primary are in theCalData.wls.
whichAnomaloscope = input('Enter anomaloscope number: ');
theCalData = load(fullfile(['primary_arduino',num2str(whichAnomaloscope)]),'primary','primary_order','wls');

%% Plot primary
fig = figure; clf; hold on;
c = [1 0 0;0 0.7 0;0.7 0.7 0;0 0 1];
for ch = 1:size(theCalData.primary,2)
    plot(theCalData.wls,theCalData.primary(:,ch),'Color',c(ch,:));
end
title(['Anomaloscope number ',num2str(whichAnomaloscope)])
xlabel('wavelength [nm]','FontWeight', 'Bold');ylabel('Radiance','FontWeight', 'Bold');
legend(theCalData.primary_order,'Location','NorthEastOutside');

% Fuss with the plot a little
ax = gca;
ax.FontName = 'Arial';
ax.Color = [.97 .97 .97];
ax.FontSize = 14;
ax.XColor = 'k';ax.YColor = 'k';

ax.LineWidth = 0.5;
ax.Units = 'centimeters';
axis square;
grid on
box off

