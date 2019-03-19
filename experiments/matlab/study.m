function [data, exit] = study(window, stim, parameters)
    data = stim;
    exit = 0;
    
    % Display the instruction screen.
    [~, height] = Screen('WindowSize', window);
    Screen('TextSize', window, 96);
    DrawFormattedText(window, 'Study Phase', 'center', height/3.0, 0);
    Screen('TextSize', window, 48);
    DrawFormattedText(window, 'Press any key to continue.', 'center',...
                      height*2/3.0, 0);
    Screen('Flip', window);
    KbStrokeWait();
    parameters.studyInstruc(window);
    KbQueueFlush();
    KbEventFlush();
    
    for i=1:parameters.studyTrials
       Screen('Flip', window);
       WaitSecs(exprnd(parameters.studyITI));
    
       % Check for ESC
       [~, pressedVec] = KbQueueCheck();
       if pressedVec(KbName(parameters.escapeKey))
          exit = 1;
          return
       end
       
       % Display the stimulus
       Screen('DrawTexture', window,...
              Screen('MakeTexture', window,...
                     imread(parameters.getFilename(data(i)))),...
                     [], [], 0);
       Screen('Flip', window);
       WaitSecs(parameters.studyTime);
       
       % Check for ESC
       [~, pressedVec] = KbQueueCheck();
       if pressedVec(KbName(parameters.escapeKey))
          exit = 1;
          return
       end
    end
    
    % Blank screen
    Screen('Flip', window);
    WaitSecs(exprnd(parameters.studyITI));
    
    % Fill in the rest of the data columns
    [data(:).phase] = deal('study');
    [data(:).response] = deal('');
    [data(:).reaction_time] = deal(NaN);
    [data(:).expected_response] = deal('');
    [data(:).is_correct] = deal(NaN);
    [data(:).is_old] = deal(false);
end