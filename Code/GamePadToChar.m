function theChar = GamePadToChar(gamePad,action)
% Map game pad code to a character.  The mapping
% is given below.
% 
% Note that some programs might call this and assign different actions to
% the keys than the actions listed here.
%
% Not all game pad actions are currently assigned. If an unassiged game pad
% action is passed, this routine returns 'z'.
%
% Back                  -> 'q' -  Exit program
% X                     -> 'm' -  Accept match and randomize
% Start                 -> 's' -  Save data
%
% East                  -> 'r' - Increase red in r/g mixture
% West                  -> 'g' - Increase green in r/g mixture
% North                 -> 'i' - Increase yellow intensity
% South                 -> 'd' - Decrease yellow intensity
%
% B                     -> '1' - Turn off green/yellow, only red in r/g mixture
% A                     -> '2' - Turn off red/yellow, only green in r/g mixture
% Y                     -> '3' - Both red and green off, only yellow i
% 
% Left Joystick Left    -> 'a' - Advance to smaller r/g delta (cyclic)
% Left Joystick Right   -> 'A' - Advance to bigger r/g delta (cyclic)
% Left Joystick Down    -> 'b' - Advance to smaller yellow delta (cyclic)
% Left Joystick Up      -> 'B' - Advance to smaller yellow delta (cyclic)
%
% Lower Right Trigger   -> 't' - Toggle yellow on and off
% Lower Left Trigger    -> '4' - Leave calibration mode
% Upper Right Trigger   -> ';' - Turn on blue LED and all the others off
%                                Not implemented in all caller versions.
% Upper Left Trigger    -> ':' - Nothing

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
            theChar = 's';

        % Colored buttons (on the right)
        elseif (gamePad.buttonX)
            % fprintf('''X'' button\n');
            theChar = 'm';
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
            theChar = ':';
        elseif (gamePad.buttonRightUpperTrigger)
            % fprintf('Right Upper Trigger button\n');
            theChar = ';';
        elseif (gamePad.buttonLeftLowerTrigger)
            % fprintf('Left Lower Trigger button\n');
            theChar = '4';
        elseif (gamePad.buttonRightLowerTrigger)
            % fprintf('Right Lower Trigger button\n');
            theChar = 't';
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
        end 

    case gamePad.joystickChange % see which analog joystick was changed
        if (gamePad.leftJoyStickDeltaX ~= 0)
            % fprintf('Left Joystick delta-X: %d\n', gamePad.leftJoyStickDeltaX);
            if (gamePad.leftJoyStickDeltaX < 0)
                theChar = 'a';
            else
                theChar = 'A';
            end
        elseif (gamePad.leftJoyStickDeltaY ~= 0)
            % fprintf('Left Joystick delta-Y: %d\n', gamePad.leftJoyStickDeltaY);
            if (gamePad.leftJoyStickDeltaY < 0)
                theChar = 'B';
            else
                theChar = 'b';
            end
        elseif (gamePad.rightJoyStickDeltaX ~= 0)
            % fprintf('Right Joystick delta-X: %d\n', gamePad.rightJoyStickDeltaX);
        elseif (gamePad.rightJoyStickDeltaY ~= 0)
            % fprintf('Right Joystick delta-Y: %d\n', gamePad.rightJoyStickDeltaY);
        end
end

end