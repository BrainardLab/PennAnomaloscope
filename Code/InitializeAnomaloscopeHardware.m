function [a,gamePad,interfaceMethod] = InitializeHardware()

% Put the arduino toolbox some place on you system. This
% the adds it dynamically. The Matlab add on manager doesn't
% play well with ToolboxToolbox, which is why it's done this
% way here.  Also OK to get the arduino toolbox on your path
% in some other manner.
%
% This adds the Arduino toolbox to the path if it isn't there.
% Does it's best to guess where it is in a version and user independnet
% manner.  Will probably fail on Windows and Linux
if (~exist('arduinosetup.m','file'))
    if (~strcmp(computer,'MACI64') & ~strcmp(computer,'MACA64'))
        supportPackageDir = matlabshared.supportpkg.getSupportPackageRoot;
        addpath(genpath(supportPackageDir));
    else
        a = ver('MATLAB');
        rel = a.Release(2:end-1);
        sysInfo = GetComputerInfo;
        user = sysInfo.userShortName;
        addpath(genpath(fullfile('/Users',user,'Documents','MATLAB','SupportPackages',rel)));
    end
end

% Initialize arduino
%
% In newer versions of OS/Matlab, the arduino call without an argument
% fails because the port naming convention it assumes fails.
%
% We look for possible ports.  If none, we try a straight call to arduino
% because it might work.  Otherwise we try each port in turn, hoping we
% can open the arduino on one of them.
clear a;
devRootStr = '/dev/cu.usbmodem';
arduinoType = 'leonardo';
possiblePorts = dir([devRootStr '*']);
openedOK = false;
if (isempty(possiblePorts))
    try
        a = arduino;
        openedOK = true;
        fprintf('Opened arduino using arduino function''s autodetect of port and type\n');
    catch e
        fprintf('Could not detect the arduino port or otherwise open it.\n');
        fprintf('Rethrowing the underlying error message.\n');
        rethrow(e);
    end
else
    for pp = 1:length(possiblePorts)
        thePort = fullfile(possiblePorts.folder,possiblePorts.name);
        try
            a = arduino(thePort,arduinoType);
            openedOK = true;
        catch e
        end
    end
    if (~openedOK)
        fprintf('Despite our best cleverness, unable to open arduino. Exiting with an error\n');
        error('');
    else
        fprintf('Opened arduino on detected port %s\n',thePort);
    end
end

% Check for game pad, and initialize if present
%   'GamePad'     - (Default). Use BrainardLabToolbox GamePad interface.
%   'MatlabInput' - Use Matlab's input() function.
%   'PTB'         - Use Psychtoolbox GetChar() function.
interfaceMethod = 'GamePad';
switch (interfaceMethod)
    case 'GamePad'
        try
            gamePad = GamePad;
            fprintf('Game pad detected. Using game pad.\n');
        catch
            gamePad = [];
            interfaceMethod = 'MatlabInput';
            fprintf('No game pad detected, using Matlab''s input(); function.\n');
        end
    case 'MatlabInput'
        fprintf('Using Matlab''s input() function.\n');
    case 'PTB'
        % There is only a small chance this will work these days.
        try
            ListenChar(2);
            FlushEvents;
            fprintf('Using Psychtoolbox keyboard i/o.');
        catch
            interfaceMethod = 'MatlabInput';
            fprintf('Working PTB not detected, using Matlab''s input(); function.\n');
        end
end
end