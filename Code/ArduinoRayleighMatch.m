% ArduinoRayleighMatch
%
% Little program to do Rayleigh matches with our arduino device.
%
% The initial parameters here are close to a match with my device,
% Scotch tape as diffuser, and a Roscolux #23 orange filter
% to cut out short wavelengths.
%
% This version lets you adjust r/g mixture and yellow intensity, as in
% classic anomaloscope.  See ArduinoRayleighMatchRGY for a different set of
% controls.

% History
%   Written 2020 by David Brainard based on demo code provided by Liana Keesing.
%
%   2022-08-27  dhb  Autodect of port for compatibility with newer systesm.
%                    Thanks to John Mollon's group for identifying the
%                    basic problem and fix.
%   2025-03-02  dhb  Add support for BrainardLabToolbox GamePad interface.
%   2025-03-04  dhb  Better Windows support.

% Initialize
clear; close all;

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
        try 
            ListenChar(2);
            FlushEvents;
            fprintf('Using Psychtoolbox keyboard i/o.');
        catch
            interfaceMethod = 'MatlabInput';
            fprintf('Working PTB not detected, using Matlab''s input(); function.\n');
        end
end

% Yellow LED parameters
yellow = 66;                                    % Initial yellow value
yellowDeltas = [10 5 1];                        % Set of yellow deltas
yellowDeltaIndex = 1;                           % Delta index    
yellowDelta = yellowDeltas(yellowDeltaIndex);   % Current yellow delta

% Red/green mixture parameters.  These get traded off in the
% mixture by a parameter lambda.
redAnchor = 50;                                 % Red value for lambda = 1
greenAnchor = 350;                              % Green value for lambda = 0
lambda = 0.5;                                   % Initial lambda value
lambdaDeltas = [0.02 0.005 0.001];              % Set of lambda deltas
lambdaDeltaIndex = 1;                           % Delta index
lambdaDelta = lambdaDeltas(lambdaDeltaIndex);   % Current delta

% Booleans that control whether we just show red or just green
% LED in mixture.  This is mostly useful for debugging.
redOnly = false;
greenOnly = false;

% Loop and process characters to control yellow intensity and 
% red/green mixture
%
% 'q' - Exit program
%
% 'r' - Increase red in r/g mixture
% 'g' - Increase green in r/g mixture
% 'i' - Increase yellow intensity
% 'd' - Decrease yellow intensity
%
% '1' - Turn off green, only red in r/g mixture
% '2' - Turn off red, only green in r/g mixture
% '3' - Both red and green in r/g mixture
% 
% 'a' - Advance to next r/g delta (cyclic)
% ';' - Advance to next yellow delta (cyclic)
while true
    % Set red and green values based on current lambda
    red = round(lambda*redAnchor);
    if (red < 0)
        red = 0;
    end
    if (red > 255)
        red = 255;
    end
    green = round((1-lambda)*greenAnchor);
    if (green < 0)
        green = 0;
    end
    if (green > 255)
        green = 255;
    end
    
    % Handle special modes for red and green
    if (redOnly)
        green = 0;
    end
    if (greenOnly)
        red = 0;
    end
    
    % Tell user where we are
    fprintf('Lambda = %0.3f, Red = %d, Green = %d, Yellow = %d\n',lambda,red, green, yellow); 
    fprintf('\tLambda delta %0.3f; yellow delta %d\n',lambdaDelta,yellowDelta);
    
    % Write the current LED settings
    writeRGB(a,red,green,0);
    writeYellow(a,yellow);
    
    % Check for chars and process if one is pressed.  See comment above for
    % what each character does.
    switch (interfaceMethod)
        % GamePad interface.  What until something happens on the game pad,
        % translate to a character via GamePadToChar function, then proceed
        % as if we were using a character interface.
        case 'GamePad'
            % What until something happens on the game pad
            action = gamePad.read;
            while (action == gamePad.noChange)
                action = gamePad.read();
            end   

            % Map game pad responses to chars
            theChar = GamePadToChar(gamePad,action);

            % Wait for game pad button up
            while (action ~= gamePad.noChange)
                action = gamePad.read;
            end

        % Use the Matlab built-in input() function.  Klunky because you
        % have to hit return, but works on any computer.
        case 'MatlabInput'
            theString = input('Enter char followed by enter: ','s');
            theChar = theString(1);

        % Use Psychtoolbox-3 GetChar function.  Works if you have a
        % supported computer and version of Psychtoolbox-3.
        case 'PTB'
            theChar = GetChar;

    end

    % Do whatever the character we have says to do
    switch theChar
        case 'q'
            break;
            
        case 'r'
            lambda = lambda+lambdaDelta;
            if (lambda > 1)
                lambda = 1;
            end
            
        case 'g'
            lambda = lambda-lambdaDelta;
            if (lambda < 0)
                lambda = 0;
            end
            
        case 'i'
            yellow = round(yellow+yellowDelta);
            if (yellow > 255)
                yellow = 255;
            end
            
        case 'd'
            yellow = round(yellow-yellowDelta);
            if (yellow < 0)
                yellow = 0;
            end
            
        case '1'
            redOnly = true;
            greenOnly = false;
            
        case '2'
            redOnly = false;
            greenOnly = true;
            
        case '3'
            redOnly = false;
            greenOnly = false;
            
        case 'a'
            lambdaDeltaIndex = lambdaDeltaIndex+1;
            if (lambdaDeltaIndex > length(lambdaDeltas))
                lambdaDeltaIndex = 1;
            end
            lambdaDelta = lambdaDeltas(lambdaDeltaIndex);
            
        case ';'
            yellowDeltaIndex = yellowDeltaIndex+1;
            if (yellowDeltaIndex > length(yellowDeltas))
                yellowDeltaIndex = 1;
            end
            yellowDelta = yellowDeltas(yellowDeltaIndex);

        case 'z'
            % Do nothing for 'z' - returned by unassigned buttons of game
            % pad.
            
        otherwise
            
    end
    
end

% Turn off character capture.
if (strcmp(interfaceMethod,'PTB'))
    ListenChar(0);
end

% Turn off gamepad
if (strcmp(interfaceMethod,'GamePad'))
    gamePad.shutDown();
end
    
% Close arduino
clear a;


% Function to map game pad actions to characters
% Loop and process characters to control yellow intensity and 
% red/green mixture
%
% Back                -> 'q' - Exit program
%
% East                  -> 'r' - Increase red in r/g mixture
% West                  -> 'g' - Increase green in r/g mixture
% North                 -> 'i' - Increase yellow intensity
% South                 -> 'd' - Decrease yellow intensity
%
% B                     -> '1' - Turn off green, only red in r/g mixture
% A                     -> '2' - Turn off red, only green in r/g mixture
% Y                     -> '3' - Both red and green in r/g mixture
% 
% Left Upper Trigger     -> 'a' - Advance to next r/g delta (cyclic)
% Right Upper Trigger   -> ';' - Advance to next yellow delta (cyclic)

function theChar = GamePadToChar(gamePad,action)

theChar = 'z';
switch (action)
    case gamePad.noChange       % do nothing

    case gamePad.buttonChange   % see which button was pressed
        % Control buttons
        if (gamePad.buttonBack)
            % fprintf('Back button\n');
            theChar = 'q';
        elseif (gamePad.buttonStart)
            % fprintf('Start button\n');

        % Colored buttons (on the right)
        elseif (gamePad.buttonX)
            % fprintf('''X'' button\n');
        elseif (gamePad.buttonY)
            % fprintf('''Y'' button\n');
            theChar = '3';
        elseif (gamePad.buttonA)
            % fprintf('''A'' button\n');
            theChar = '2';
        elseif (gamePad.buttonB)
            % fprintf('''B'' button\n');
            theChar = '1';

        % Trigger buttons
        elseif (gamePad.buttonLeftUpperTrigger)
            % fprintf('Left Upper Trigger button\n');
            theChar = 'a';
        elseif (gamePad.buttonRightUpperTrigger)
            % fprintf('Right Upper Trigger button\n');
            theChar = ';';
        elseif (gamePad.buttonLeftLowerTrigger)
            % fprintf('Left Lower Trigger button\n');
        elseif (gamePad.buttonRightLowerTrigger)
            % fprintf('Right Lower Trigger button\n');
        end

    case gamePad.directionalButtonChange  % see which direction was selected
        switch (gamePad.directionChoice)
            case gamePad.directionEast
                % fprintf('East\n');
                theChar = 'r';
            case gamePad.directionWest
                % fprintf('West\n');
                theChar = 'g';
            case gamePad.directionNorth
                % fprintf('North\n');
                theChar = 'i';
            case gamePad.directionSouth
                % fprintf('South\n');
                theChar = 'd';
            case gamePad.directionNone
                % fprintf('No direction\n');
        end  % switch (gamePad.directionChoice)

    case gamePad.joystickChange % see which analog joystick was changed
        if (gamePad.leftJoyStickDeltaX ~= 0)
            % fprintf('Left Joystick delta-X: %d\n', gamePad.leftJoyStickDeltaX);
        elseif (gamePad.leftJoyStickDeltaY ~= 0)
            % fprintf('Left Joystick delta-Y: %d\n', gamePad.leftJoyStickDeltaY);
        elseif (gamePad.rightJoyStickDeltaX ~= 0)
            % fprintf('Right Joystick delta-X: %d\n', gamePad.rightJoyStickDeltaX);
        elseif (gamePad.rightJoyStickDeltaY ~= 0)
            % fprintf('Right Joystick delta-Y: %d\n', gamePad.rightJoyStickDeltaY);
        end
end

end
