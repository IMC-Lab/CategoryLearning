function [data, exit] = learn(window, stim, parameters)
%LEARN run the learning phase of the category learning paradigm
%   
    % initialize the data array
    exit = 0;
    data = stim;
    [data(:).phase] = deal('learn');
    [data(:).is_old] = deal(false);  % fill in absent values
    
    [~, height] = Screen('WindowSize', window);
    Screen('TextSize', window, 96);
    DrawFormattedText(window, 'Learning Phase', 'center', height/3.0, 0);
    Screen('TextSize', window, 48);
    DrawFormattedText(window, 'Press any key to continue.', 'center',...
                      height*2/3.0, 0);
    Screen('Flip', window);
    KbStrokeWait();
    
    %[~, height] = Screen('WindowSize', window);
    %Screen('TextSize', window, 96);
    %DrawFormattedText(window, parameters.learningInstruc, 'center', height/3.0, 0);
    %Screen('TextSize', window, 48);
    %DrawFormattedText(window, 'Press any key to continue.', 'center',...
    %                  height*2/3.0, 0);
    %Screen('Flip', window);
    %KbStrokeWait();
    
    for i = 1:parameters.learningTrials
       Screen('Flip', window);
       WaitSecs(exprnd(parameters.learningITI));
    
       % Display the stimulus
       Screen('DrawTexture', window,...
              Screen('MakeTexture', window,...
                     imread(parameters.getFilename(stim(i)))),...
                     [], [], 0);
       [~, start] = Screen('Flip', window);
       WaitSecs(parameters.learningMinViewing);
       
       % Read keyboard input
       keyPressed = false;
       while ~keyPressed
           [~, ~, keyCode] = KbCheck;
           if keyCode(KbName(parameters.escapeKey))
               exit = 1;
               return
           elseif keyCode(KbName(parameters.learningYKey))
               keyPressed = true;
               data(i).response = parameters.learningYKey;
           elseif keyCode(KbName(parameters.learningNKey))
               keyPressed = true;
               data(i).response = parameters.learningNKey;
           elseif GetSecs() > start + parameters.learningTimeout
               data(i).response = NaN;
               break
           end
       end
       
       % Log data for this trial
       data(i).reaction_time = GetSecs() - start;
       if data(i).is_learned
           data(i).expected_response = parameters.learningYKey;
       else
           data(i).expected_response = parameters.learningNKey;
       end
       data(i).is_correct = strcmp(data(i).response,...
                                   data(i).expected_response);
       
       % Display feedback
       Screen('TextSize', window, 72);
       if data(i).is_correct
           DrawFormattedText(window, 'Correct', 'center', 'center', [0, 1, 0]);
       else
           DrawFormattedText(window, 'Incorrect', 'center', 'center', [1, 0, 0]);
       end
       Screen('Flip', window);
       WaitSecs(parameters.learningFeedbackTime);
    end
        
    Screen('Flip', window);
    WaitSecs(exprnd(parameters.learningITI));
end