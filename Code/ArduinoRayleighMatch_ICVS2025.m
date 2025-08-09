% ArduinoRayleighMatch
%
% Little program to do Rayleigh matches with our arduino device.
%
% The initial parameters here are close to a match with my device,
% Scotch tape as diffuser, and a Roscolux #23 orange filter
% to cut out short wavelengths.
%
% This version lets you adjust r/g mixture and yellow intensity, as in
% classic anomaloscope.  
%
% History:
%   Written 2020 by David Brainard based on demo code provided by Liana Keesing.
%
%   2022-08-27  dhb  Autodetect of port for compatibility with newer systesm.
%                    Thanks to John Mollon's group for identifying the
%                    basic problem and fix.
%   2025-03-02  dhb  Add support for BrainardLabToolbox GamePad interface.
%   2025-03-04  dhb  Better Windows support.
%   2025-03-18  dhb  Match accept, data save
%   2025-03-23  dhb  Update with ideas from class on 3/18.  Renaming to
%                    avoid version confusion.
%   2025-03-27  dhb  Window sizes smaller, fix reset of step sizes, print
%                    out left and right tube identities.
%               dhb  Can only accept match when basic sanity checks pass.
%   2025-08-09  dhb  ICVS version
%
% Version 3.02

% Initialize
clear; close all;

% Set name of anomaloscope default
%
% This can be changed when the program runs
% in the dialog box that pops up.
% 
% We enforce that the name be recognized by this program
% and also so that we don't later get a data filename we can't parse.
%
% Note that our compar
defaultAnomaloscope = '1';
anomaloscopeNames =              {'1', '2', '3', '4'  '5' '6' '7', '8', '9'};

% Play sounds?
% 
% This is a bit slow and also not good for a crowded room
playSounds = false;

% Use status window
statusWindow = true;

% Print out current settings to command window
printCurrentSettings = false;

% Randomize match start?
% When this is false, matches always
% start at the same place
randStart = false;
if (randStart)
    yellow = round(255*rand);
    lambda = rand;
else
    yellow = 200;
    lambda = 0;
end
blue = 0;

% Initialize the hardware interfaces to arduino and input device
[a,gamePad,interfaceMethod] = InitializeAnomaloscopeHardware;

% Initialize directory into which to write data.
% This will be a directory called 'Local' in the
% same folder as this program.
myDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(myDir,'Local');
if (~exist(dataDir,'dir'))
    mkdir(dataDir);
end

% Time and date we ran the program.  String.  Useful for
% forming output filename.
strForDateTime = datestr(now,'yyyy-mm-dd_HH-MM-SS');

% Get anomaloscope and subject number and combine with date/time
% to create output filename
haveValidAnomaloscope = false;
while (~haveValidAnomaloscope)
    prompt = {'Enter anomaloscope name:','Enter subject number:'};
    dlgtitle = 'Input';
    fieldsize = [1 45; 1 45];
    definput = {defaultAnomaloscope,'999'};
    answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
    whosAnomaloscope = answer{1};
    subjectNumber = str2num(answer{2});

    for aa = 1:length(anomaloscopeNames)
        if (strcmp(lower(whosAnomaloscope),lower(anomaloscopeNames{aa})))
            haveValidAnomaloscope = true;
            break;
        end
    end
end

% Set output filename
outputFilename = fullfile(dataDir,[num2str(subjectNumber) '_' whosAnomaloscope '_' strForDateTime]);

% Yellow LED parameters
yellowDeltas = [20 7 1];                        % Set of yellow deltas
yellowDeltaIndex = 1;                           % Delta index    
yellowDelta = yellowDeltas(yellowDeltaIndex);   % Current yellow delta

% Red/green mixture parameters.  These get traded off in the
% mixture by a parameter lambda.
redAnchor = 50;                                 % Red value for lambda = 1
greenAnchor = 255;                              % Green value for lambda = 0
lambdaDeltas = [0.1 0.02 0.0025];               % Set of lambda deltas
lambdaDeltaIndex = 1;                           % Delta index
lambdaDelta = lambdaDeltas(lambdaDeltaIndex);   % Current delta

% Requirements for accepting a match
minRGMatchSteps = 8;
minYellowMatchSteps = 8;
minMatchElapsedTime = 10;

% Labels for deltas
deltaLabels = {'Big' 'Medium' 'Small'};

% Randomize values of yellow and lambda
if (randStart)
    yellow = round(255*rand);
    lambda = rand;
else
    yellow = round(190+20*rand);
    lambda = 0.2*rand;
end

% Booleans that control whether we just show red or just green
% LED in mixture, or just show yellow. This is mostly useful for debugging and calibration.
redOnly = false;
greenOnly = false;
yellowOnly = false;
yellowOff = false;
yellowSave = yellow;
blueOnly = false;

% Set up variables to store data for each match
numberOfMatches = 0;
redAtMatch = [ ];
greenAtMatch = [ ];
yellowAtMatch = [ ];
lambdaDeltaAtMatch = [ ];
yellowDeltaAtMatch = [ ];

% Initialize some tracking variables
matchStarted = false;

% Some info for placing figures
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);
topOffset = 200;
leftOffset = 50;
textLeftPosition = 0.02;
statusFontSize = 24;

% If we're using a status window, initialize
if (statusWindow)
    statusFigure = figure; clf; hold on;
    statusWidth = 500;
    statusHeight = 600;
    set(gca,'FontName','Helvetica');
    set(gcf,'Position',[leftOffset  screenHeight-statusHeight-topOffset statusWidth statusHeight]);
    set(gca,'XTick',[]); set(gca,'YTick',[]);
    title('Status Window','FontSize',32);
    hRGDelta = text(textLeftPosition,0.4,sprintf('RG balance step size: %s',deltaLabels{lambdaDeltaIndex}),'FontSize',statusFontSize);
    hYellowDelta = text(textLeftPosition,0.3,sprintf('Yellowish brightness step size: %s',deltaLabels{yellowDeltaIndex}),'FontSize',statusFontSize);
    hAnomaloscope = text(textLeftPosition,0.9,sprintf('Anomaloscope: %s',whosAnomaloscope),'FontSize',statusFontSize);
    hSubject = text(textLeftPosition,0.6,sprintf('Subject: %d',subjectNumber),'FontSize',statusFontSize);
    hMatchesCompleted = text(textLeftPosition,0.1,sprintf('Matches completed and saved: %d',numberOfMatches),'FontSize',statusFontSize);

    % Pop up instructions figure
    guideTopOffset = topOffset-100;
    uiopen(fullfile(myDir,'GamePadCommandGuide.fig'),1);
    guideFigure = gcf;
    guidePosition = get(gcf,'Position');
    set(guideFigure,'Position',[leftOffset+statusWidth+60, screenHeight-guidePosition(4)-guideTopOffset, round(0.75*guidePosition(3)), round(0.75*guidePosition(4))]);
    figure(statusFigure); figure(guideFigure);
end

% Loop and process characters to control yellow intensity and 
% red/green mixture.  With the game pad interface, game pad presses
% are converted to characters by the routine GamePadToChar and then
% processed as if they were key presses.
%
% 'q' - Exit program
% 'm' - Accept match and save all current matches.  Start new match.
%
% 'r' - Increase red in r/g mixture
% 'g' - Increase green in r/g mixture
% 'i' - Increase yellow intensity
% 'd' - Decrease yellow intensity
%
% '1' - Turn off green/yellow, only red in r/g mixture
% '2' - Turn off red/yellow, only green in r/g mixture
% '3' - Turn off red and green, yellow on
% ';' - Toggle blueOnly  When true turn off red, green and yellow and turn blue on full.
% '4' - Exit any of the above modes and go back to normal operation.
%
% 't' - Toggle yellow off mode.  In yellow off mode, not surprisingly, the
%       yellow LED is turned off.   This is useful if you want to do unique
%       yellow settings without bias from the appearance of the yellow LED.
% 
% 'a' - Advance to smaller r/g delta (stops at smallest)
% 'A' - Go back to larger r/g delta (stops at largest)
% 'b' - Advance to smaller yellow delta (stops at smallest)
% 'B' - Go back to larger yellow delta (stops at smallest)
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

   % If yellow is set to be off, make sure it is off.
   if (yellowOff)
       yellow = 0;
   end
    
    % Handle special modes
    if (redOnly)
        green = 0;
        yellow = 0;
        blue = 0;
        red = 255;
    end
    if (greenOnly)
        red = 0;
        yellow = 0;
        blue = 0;
        green  = 255;
    end
    if (yellowOnly)
        red = 0;
        green = 0;
        blue = 0;
        yellow = 255;
    end
    if (blueOnly)
        red = 0;
        green = 0;
        blue = 255;
        yellow = 0;
    end
    
    % Tell user where we are
    if (printCurrentSettings)
        fprintf('R/G lambda = %0.3f, Red = %d, Green = %d, Yellow = %d\n',lambda,red, green, yellow);
        fprintf('\tYellow delta %0.3f; yellow delta %d\n',lambdaDelta,yellowDelta);
        fprintf('\tR/G = %0.3g\n',red/green);
        fprintf('\n');
    end
    
    % Write the current LED settings
    writeRGB(a,red,green,blue);
    writeYellow(a,yellow);

    % Update status
    if (statusWindow)
        if (~yellowOff)
            hYellowDelta.String = sprintf('Yellowish step size: %s',deltaLabels{yellowDeltaIndex});
        else
            hYellowDelta.String = sprintf('Yellowish light is off');
        end
        hRGDelta.String = sprintf('RG balance step size: %s',deltaLabels{lambdaDeltaIndex});
        hMatchesCompleted.String = sprintf('Matches completed and saved: %d',numberOfMatches);
    end

    % Start a match if we are not in the middle of one
    if (~matchStarted)
        % Reset deltas
        lambdaDeltaIndex = 1;
        lambdaDelta = lambdaDeltas(lambdaDeltaIndex);
        yellowDeltalIndex = 1;
        yellowDelta = yellowDeltas(yellowDeltaIndex);

        % Get match start time and initialize number of steps
        startTime = tic;
        nRGMatchSteps = 0;
        nYellowMatchSteps = 0;

        % Start information
        lambdaStart = lambda;
        redStart = red;
        greenStart = green;
        yellowStart = yellow;

        % Indicate match started
        matchStarted  = true;
    end

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
        % supported computer and version of Psychtoolbox-3, and if the PTB 
        % char interface is working on  your computer.  Recently this does
        % not seem very likely to be the case.  This code has not been
        % tested recently for that reason.
        case 'PTB'
            theChar = GetChar;
    end

    % Do whatever the character we have says to do
    switch theChar
        case 'q'
            % Exit program
            if (playSounds)
                Speak('So long for now');
            end

            % Close all the windows
            close all;
            
            break;

        case 'm'
            % Make sure the match satisfies some sanity checks.
            % Step sizes should not be at max
            % Match process should have taken some minimum amount of time.
            % Match process should have taken some minimum number of steps
            matchElapsedTime = toc(startTime);

            % Check whether it is reasonable to accept match/setting
            if (~yellowOff)
                checkOKCondition = nRGMatchSteps >= minRGMatchSteps & ...
                    nYellowMatchSteps >= minYellowMatchSteps &...
                    yellowDelta ~= yellowDeltas(1) & ...
                    lambdaDelta ~= lambdaDeltas(1) & ...
                    matchElapsedTime >= minMatchElapsedTime;
            else
                 checkOKCondition = nRGMatchSteps >= minRGMatchSteps & ...
                    lambdaDelta ~= lambdaDeltas(1) & ...
                    matchElapsedTime >= minMatchElapsedTime;
            end

            % Accept match if OK to do so
            if (checkOKCondition)  
                % Store information about this match
                numberOfMatches = numberOfMatches + 1;
                redAtMatch(numberOfMatches) = red;
                greenAtMatch(numberOfMatches) = green;
                yellowAtMatch(numberOfMatches) = yellow;
                lambdaDeltaAtMatch(numberOfMatches) = lambdaDelta;
                yellowDeltaAtMatch(numberOfMatches) = yellowDelta;
                matchElapsedTimeAtMatch(numberOfMatches) = matchElapsedTime;
                nRGMatchStepsAtMatch(numberOfMatches) = nRGMatchSteps;
                nYellowMatchStepsAtMatch(numberOfMatches) = nRGMatchSteps;
                redStarts(numberOfMatches) = redStart;
                greenStarts(numberOfMatches) = greenStart;
                yellowStarts(numberOfMatches) = yellowStart;
                lambdaStarts(numberOfMatches) = lambdaStart;

                % Save into a .mat file
                save(outputFilename,'numberOfMatches','redAtMatch','greenAtMatch','yellowAtMatch','lambdaDeltaAtMatch','yellowDeltaAtMatch', ...
                    'matchElapsedTime','nRGMatchStepsAtMatch','nYellowMatchStepsAtMatch','redStarts','greenStarts','yellowStarts','lambdaStarts');

                % Randomize values of yellow and lambda
                if (randStart)
                    yellow = round(255*rand);
                    lambda = rand;
                else
                    yellow = 200;
                    lambda = 0;
                end
                yellowSave = yellow;

                % Reset deltas
                lambdaDeltaIndex = 1;
                lambdaDelta = lambdaDeltas(lambdaDeltaIndex);
                yellowDeltaIndex = 1;
                yellowDelta = yellowDeltas(yellowDeltaIndex);

                % Indicate next match not started
                matchStarted = false;

                % Accept match.
                if (playSounds)
                    Speak('Match accepted and saved');
                end

                % User indicates a match.
                fprintf('\n*** Match %d accepted and saved! ***\n', numberOfMatches);
                if (printCurrentSettings)
                    fprintf('R/G lambda = %0.3f, Red = %d, Green = %d, Yellow = %d\n',lambda,red, green, yellow);
                    fprintf('\tYellow delta %0.3f; yellow delta %d\n',lambdaDelta,yellowDelta);
                    fprintf('\tR/G = %0.3g\n',red/green);
                    fprintf('\n');
                end

                % Update status
                if (statusWindow)
                    if (~yellowOff)
                        hYellowDelta.String = sprintf('Yellowish step size: %s',deltaLabels{yellowDeltaIndex});
                    else
                        hYellowDelta.String = sprintf('Yellowish light is off');
                    end                    
                    hRGDelta.String = sprintf('RG balance step size: %s',deltaLabels{lambdaDeltaIndex});

                    % Let user know
                    hMatchesCompleted.String = sprintf('MATCH SAVED!');
                    pause(1);
                    hMatchesCompleted.String = '';
                    pause(1);
                    hMatchesCompleted.String = sprintf('Matches completed and saved: %d',numberOfMatches);
                end
            else
                % It is not reasonable to accept this match. Tell user why.
                if (nRGMatchSteps < minRGMatchSteps)
                    questdlg('Too few RG steps taken. Take some more time and try to improve match.','Match Not Accepted!','OK','OK');
                elseif (nYellowMatchSteps < minYellowMatchSteps)
                    questdlg('Too few yellow steps taken. Take some more time and try to improve match.','Match Not Accepted!','OK','OK');
                elseif (lambdaDelta == lambdaDeltas(1) | yellowDelta == yellowDeltas(1))
                    questdlg('At least one step size too big. Reduce step sizes and try to improve match.','Match Not Accepted!','OK','OK');
                elseif (matchElapsedTime < minMatchElapsedTime)
                    questdlg('Match made too quickly. Take some more time and try to improve match.','Match Not Accepted!','OK','OK');
                else
                    questdlg('Match not accepted for unknown reason. This is a bug in the program.','Match Not Accepted!','OK','OK');
                end

                % Get rid of 'm' char. (Probably not necessary.)
                theChar = 'z';
            end

        case 'r'
            lambda = lambda+lambdaDelta;
            if (lambda > 1)
                lambda = 1;
            end
            nRGMatchSteps = nRGMatchSteps + 1;

        case 'g'
            lambda = lambda-lambdaDelta;
            if (lambda < 0)
                lambda = 0;
            end
            nRGMatchSteps = nRGMatchSteps + 1;
            
        case 'i'
            yellow = round(yellow+yellowDelta);
            if (yellow > 255)
                yellow = 255;
            end
            yellowSave = yellow;
            nYellowMatchSteps = nYellowMatchSteps + 1;
            
        case 'd'
            yellow = round(yellow-yellowDelta);
            if (yellow < 0)
                yellow = 0;
            end
            yellowSave = yellow;
            nYellowMatchSteps = nYellowMatchSteps + 1;
            
        case '1'
            redOnly = true;
            greenOnly = false;
            yellowOnly = false;
            blueOnly = false;
            hYellowDelta.String = sprintf('Red only for calibration');
            
        case '2'
            redOnly = false;
            greenOnly = true;
            yellowOnly = false;
            blueOnly = false;
            hYellowDelta.String = sprintf('Green only for calibration');
                     
        case '3'
            redOnly = false;
            greenOnly = false;
            yellowOnly = true;
            blueOnly = false;
            hYellowDelta.String = sprintf('Yellow only for calibration');

        case ';'
            redOnly = false;
            greenOnly = false;
            yellowOnly = false;
            blueOnly = true;
            blue = 255;
            hYellowDelta.String = sprintf('Blue only for calibration');

        case '4'
            redOnly = false;
            greenOnly = false;
            yellowOnly = false;
            yellow = yellowSave;
            blueOnly = false;
            blue = 0;
            hYellowDelta.String = sprintf('Yellowish step size: %s',deltaLabels{yellowDeltaIndex});
        
        case 't'
            if (yellowOff)
                yellowOff = false;
                yellow = yellowSave;
                hYellowDelta.String = sprintf('Yellowish step size: %s',deltaLabels{yellowDeltaIndex});
            else
                yellowOff = true;
                yellowSave = yellow;
                hYellowDelta.String = sprintf('Yellowish light is off');
            end
                     
        case 'a'
            % Decrease RG lambda
            lambdaDeltaIndex = lambdaDeltaIndex+1;
            if (lambdaDeltaIndex > length(lambdaDeltas))
                lambdaDeltaIndex = length(lambdaDeltas);
            end
            lambdaDelta = lambdaDeltas(lambdaDeltaIndex);
            
            % Speak if we're doing that
            if (playSounds)
                switch (lambdaDeltaIndex)
                    case 1
                        Speak('lambda big');
                    case 2
                        Speak('lambda medium');
                    case 3
                        Speak('lambda small');
                end
            end

            % Update status
            if (statusWindow)
                hRGDelta.String = sprintf('RG balance step size: %s',deltaLabels{lambdaDeltaIndex});
            end

        case 'A'
            % Increase RG lambda
            lambdaDeltaIndex = lambdaDeltaIndex-1;
            if (lambdaDeltaIndex < 1)
                lambdaDeltaIndex = 1;
            end
            lambdaDelta = lambdaDeltas(lambdaDeltaIndex);
            
            % Speak if we're doing that
            if (playSounds)
                switch (lambdaDeltaIndex)
                    case 1
                        Speak('lambda big');
                    case 2
                        Speak('lambda medium');
                    case 3
                        Speak('lambda small');
                end
            end

            % Update status
            if (statusWindow)
                    hRGDelta.String = sprintf('RG balance step size: %s',deltaLabels{lambdaDeltaIndex});
            end

        case 'b'
            % Decrease yellow delta
            yellowDeltaIndex = yellowDeltaIndex+1;
            if (yellowDeltaIndex > length(yellowDeltas))
                yellowDeltaIndex = length(yellowDeltas);
            end
            yellowDelta = yellowDeltas(yellowDeltaIndex);

            if (playSounds)
                switch (yellowDeltaIndex)
                    case 1
                        Speak('yellow big');
                    case 2
                        Speak('yellow medium');
                    case 3
                        Speak('yellow small');
                end
            end

            % Update status window
             if (~yellowOff)
                hYellowDelta.String = sprintf('Yellowish step size: %s',deltaLabels{yellowDeltaIndex});
            else
                hYellowDelta.String = sprintf('Yellowish light is off');
            end

        case 'B'
            % Increase yellow delta
            yellowDeltaIndex = yellowDeltaIndex-1;
            if (yellowDeltaIndex < 1)
                yellowDeltaIndex = 1;
            end
            yellowDelta = yellowDeltas(yellowDeltaIndex);

            if (playSounds)
                switch (yellowDeltaIndex)
                    case 1
                        Speak('yellow big');
                    case 2
                        Speak('yellow medium');
                    case 3
                        Speak('yellow small');
                end
            end

            % Update status window
             if (~yellowOff)
                hYellowDelta.String = sprintf('Yellowish step size: %s',deltaLabels{yellowDeltaIndex});
            else
                hYellowDelta.String = sprintf('Yellowish light is off');
            end
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



