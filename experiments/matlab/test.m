function [data, exit] = test(window, old_stim, lure_stim, parameters)
%TEST run the testing phase of the category learning experiment
    % set up data variables
    exit = 0;
    [old_stim(:).is_old] = deal(true);
    [lure_stim(:).is_old] = deal(false);
    stim = Shuffle([old_stim, lure_stim]);
    [stim(:).phase] = deal('test');
    data = stim;
    
    % Display the instruction screen
    [~, height] = Screen('WindowSize', window);
    Screen('TextSize', window, 96);
    DrawFormattedText(window, 'Test Phase', 'center', height/3.0);
    Screen('TextSize', window, 48);
    DrawFormattedText(window, 'Press any key to continue.', 'center',...
                      height*2/3.0);
    Screen('Flip', window);
    KbStrokeWait();
    
    for i = 1:length(stim)
       Screen('Flip', window);
       WaitSecs(exprnd(parameters.testITI));
    
       % Display the stimulus
       Screen('DrawTexture', window,...
              Screen('MakeTexture', window,...
                     imread(parameters.getFilename(stim(i)))),...
              [], [], 0);
       [~, start] = Screen('Flip', window);
       WaitSecs(parameters.testMinViewing);
       
       % Read keyboard input
       keyPressed = false;
       while ~keyPressed
           [~, ~, keyCode] = KbCheck;
           if keyCode(KbName(parameters.escapeKey))
               exit = 1;
               return
           elseif keyCode(KbName(parameters.testOldKey))
               keyPressed = true;
               data(i).response = parameters.testOldKey;
           elseif keyCode(KbName(parameters.testNewKey))
               keyPressed = true;
               data(i).response = parameters.testNewKey;
           elseif GetSecs() > start + parameters.testTimeout
               data(i).response = '';
               break
           end
       end
       
       % Log data for this trial
       data(i).reaction_time = GetSecs() - start;
       if data(i).is_old
           data(i).expected_response = parameters.testOldKey;
       else
           data(i).expected_response = parameters.testNewKey;
       end
       data(i).is_correct = strcmp(data(i).response,...
                                   data(i).expected_response);
    end
    
    Screen('Flip', window);
    WaitSecs(exprnd(parameters.testITI));
end