% AnomalosopeBasic
%
% Illustrate basics of using the PennAnomaloscope, ideally with a GamePad
% attached.
%
% History:
%
%   2025-08-09  dhb  Wrote for ICVS summer school

% Initialize
clear; close all;

% Initialize the hardware interfaces to arduino and input device.
%
% The variable a addresses the arduino that controls the anomaloscope.
%
% The variable interfaceMethod indicates what the initialize routine was
% able to set up for input.  Tries for 'GamePad' and reverts to
% 'MatlabInput' if it can't find a game pad it can talk to.
[a,gamePad,interfaceMethod] = InitializeAnomaloscopeHardware;

% Loop and process characters
%
% With the game pad interface, game pad presses
% are converted to characters by the routine GamePadToChar and then
% processed as if they were key presses.
while (true)
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

        case 'MatlabInput'
            % Use the Matlab built-in input() function.  Klunky because you
            % have to hit return, but works on any computer.
            theString = input('Enter char followed by enter: ','s');
            theChar = theString(1);
    end

    % Do whatever the character we have says to do
    switch theChar
        case 'q'
            % Mode button on GamePad
            %
            % Exit
            break;

        case '1'
            % Red button on GamePad
            %
            % Turn red full on (255) and green and blue to 0
            % Argument order to writeRGB is the arduino handle
            % a, then red, green, blue.  Each of red, green, blue
            % should be an integer between 0 and 255.
            writeRGB(a,255,0,0);

            % Turn yellow off too.  Arguemnt order is first a, then yellow
            % which is also an integer between 0 and 255.
            writeYellow(a,0);

        case '2'
            % Green button on GamePad
            writeRGB(a,0,255,0);
            writeYellow(a,0);

        case '3'
            % Yellow button on GamePad
            writeRGB(a,0,0,0);
            writeYellow(a,255);

        case 'm'
            % Blue button on GamePad
            %
            % Note that for Rayleigh matches we have a filter
            % that cuts off short wavelength light over the two LEDs.
            % With the filter in,  you won't see much when the blue LED is on.
            writeRGB(a,0,0,255);
            writeYellow(a,0)
        otherwise
    end
end

% Turn off character capture.
if (strcmp(interfaceMethod,'GamePad'))
    gamePad.shutDown();
end

% Close arduino
clear a;

