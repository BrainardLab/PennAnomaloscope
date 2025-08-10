clearvars;close all;clc % cleaning

%% plot all spectra
c = [1 0 0;0 0.7 0;0.7 0.7 0;0 0 1];

cnt = 0;
fig = figure;

% loop through anomaloscope 1 - 8 (6 is not working now)
for id = [1,2,3,4,5,7,8]
    cnt = cnt + 1;

    % load calibration file
    load(fullfile('data',['primary_arduino',num2str(id)]),'primary','primary_order','wls');
    
    % normalize by the max value
    primary = primary/max(primary(:));
    
    for ch = 1:size(primary,2)
        subplot(2,4,cnt)
        plot(primary(:,ch),'Color',c(ch,:));hold on;
    end

    title(['Arduino id',num2str(id)])

    ax = gca;
    
    xlim([0 82]);ylim([0 1])
    
    xticks([1,21,41,61,81])
    yticks([0,0.5,1])
    
    ax.XTickLabel = {'380','480','580','680','780'};
    ax.YTickLabel = {'0.0','0.5','1.0'};
    
    xlabel('wavelength [nm]','FontWeight', 'Bold');ylabel('Radiance','FontWeight', 'Bold');
    
    ax.FontName = 'Arial';
    ax.Color = [.97 .97 .97];
    ax.FontSize = 7;
    ax.XColor = 'k';ax.YColor = 'k';
    
    ax.LineWidth = 0.5;
    ax.Units = 'centimeters';
    axis square;
    grid on
    box off
end

exportgraphics(fig,fullfile('arduino_spectra.pdf'),'ContentType','vector')