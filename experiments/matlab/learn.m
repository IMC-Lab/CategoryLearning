function [data, exit] = learn(window, stim, parameters)
%LEARN run the learning phase of the category learning paradigm
    
    % initialize the data array
    exit = 0;
    data = stim;
    
    for i = 1:length(data)
        disp(parameters.getFilename(data(i)))
       % Display the stimulus
       Screen('DrawTexture', window,...
              Screen('MakeTexture', window, imread(parameters.getFilename(data(i)))),...
              [], [], 0);
       start = Screen('Flip', window);
       WaitSecs(parameters.learningMinViewing);
       
       % Read keyboard input
       keyPressed = false;
       while ~keyPressed
           [~, ~, keyCode] = KbCheck;
           if keyCode(KbName('ESCAPE'))
               exit = 1;
               return
           elseif keyCode(KbName('y'))
               keyPressed = true;
               data(i).response = 'y';
           elseif keyCode(KbName('n'))
               keyPressed = true;
               data(i).response = 'n';
           end
       end
       
       % Log data for this trial
       data(i).rt = GetSecs() - start;
       if data(i).is_learned
           data(i).expected_response = 'y';
       else
           data(i).expected_response = 'n';
       end
       
       data(i).is_correct = strcmp(data(i).response, data(i).expected_response);
    end
end