function CategoryLearning(varargin)
% CATEGORYLEARNING  run the paradigm for testing the memory effects of
%                   category learning defined in "Tracking the emergence
%                   of memories: A category learning paradigm to explore
%                   schema-driven recognition" by De Brigard  et al (2017).
%
% BIAC :- run with fMRI scanner? Defaults to false.
% features :- a struct containing stimulus features associated with the
%             set of the feature's possible values.
% getFilename :- a function to generate a filename given a set of
%                feature values.
% escapeKey :- a key that can be pressed to abort the experiment. 
%              Defaults to the escape key.
%
%Parameters for the learning phase
% learningTrials :- the number of learning trials to complete
% learningPLearned :- the percentage of stimuli in the learned category
% learningPUnlearned :- the percentage of stimuli in the unlearned category
% learningITI  :- the intertrial interval for the learning phase.
%                 Defaults to 1 second.
% learningMinViewing :- how long to wait before getting a keypress
% learningTimeout :- the maximum viewing time for a stimulus
% learningYKey :- the key response for a stimulus in the learned category
% learningNKey :- the key response for a stimulus in the unlearned category
%
%Parameters for the study phase
% studyTrials :- the number of study trials to complete
% studyPLearned :- the percentage of stimuli in the learned category
% studyPUnlearned :- the percentage of stimuli in the unlearned category
% studyTime :- the amount of time to display stimuli in the study phase.
%              Defaults to 5 seconds.
% studyITI  :- the intertrial interval for the study phase.
%              Defaults to 1 second.
%
%Parameters for the test phase
% oldTrials :- the number of old items in the test list
% lureTrials :- the number of new items in the test list
% lurePLearned :- the percentage of lures in the learned category
% lurePUnlearned :- the percentage of lures in the unlearned category
% testITI :- the intertrial interval for the test phase. 
%            Defaults to 1 second.
% testMinViewing :- how long to wait before recording keypresses
% testTimeout :- the maximum viewing time for a stimulus
% testOldKey :- the key to press if a stimulus is old
% testNewKey :- the key to press if a stimulus is new
%
%
    % setup PsychToolbox
    HideCursor;
    close all;
    sca;
    PsychDefaultSetup(2);
    ListenChar(2);
    
    % dummy calls to make sure PTB is loaded
    KbCheck;
    WaitSecs(0.01);
    GetSecs();

    try
    % parse the input
    p = inputParser;
    p.addParameter('BIAC', false, @islogical);
    p.addParameter('features', struct(), ...
                   @(x) ~isempty(x) & ~any(structfun(@isempty, x)));
    p.addParameter('getFilename', @getFilenameDefault,...
                   @(x) isa(x, 'function_handle'));
    p.addParameter('escapeKey', 'ESCAPE', @ischar);
    p.addParameter('conditionFilename', 'conditions.mat', @ischar);
    p.addParameter('conditionNumberFilename', 'participantNumber.mat', @ischar);
    
    p.addParameter('learningTrials', 9, @(x) x > 0);
    p.addParameter('learningPLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('learningPUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('learningITI', 1.0, @(x) x > 0);
    p.addParameter('learningMinViewing', 0.25, @(x) x >= 0);
    p.addParameter('learningTimeout', 5.0, @(x) x > 0);
    p.addParameter('learningFeedbackTime', 1.0, @(x) x >= 0);
    p.addParameter('learningYKey', 'y', @ischar);
    p.addParameter('learningNKey', 'n', @ischar);
    p.addParameter('learningInstruc', '', @ischar);
    
    p.addParameter('studyTrials', 9, @(x) x > 0);
    p.addParameter('studyPLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('studyPUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('studyTime', 5.0, @(x) x > 0);
    p.addParameter('studyITI', 1.0, @(x) x > 0);
    p.addParameter('studyInstruc', '', @ischar);
    
    p.addParameter('oldTrials', 9, @(x) x >= 0);
    p.addParameter('lureTrials', 9, @(x) x > 0);
    p.addParameter('lurePLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('lurePUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('testITI', 1.0, @(x) x > 0);
    p.addParameter('testMinViewing', 0.25, @(x) x >= 0);
    p.addParameter('testTimeout', 5.0, @(x) x > 0);
    p.addParameter('testOldKey', 'y', @ischar);
    p.addParameter('testNewKey', 'n', @ischar);
    p.addParameter('testInstruc', '', @ischar);
    p.parse(varargin{:});
    parameters = p.Results;
    
    % Define the learned category
    conds = get_conditions(parameters.features,...
                           'filename', parameters.conditionFilename);
    parameters.participantNumber =...
        get_participant_number(parameters.conditionNumberFilename);
    parameters.conditionNum = mod(parameters.participantNumber-1, length(conds)) + 1;
    [parameters.learned_feature, parameters.learned_value] =...
        conds{parameters.conditionNum,:};
    
    % save their indices
    parameters.learned_feature_idx =...
        find(cellfun(@(x) isequal(x,parameters.learned_feature),...
                     fieldnames(parameters.features)));
    parameters.learned_value_idx =...
        find(cellfun(@(x) isequal(x,parameters.learned_value),...
                     parameters.features.(parameters.learned_feature)));
    
    % draw unlearned category randomly
    [parameters.unlearned_feature, parameters.unlearned_feature_idx] =...
        randelement(fieldnames(parameters.features));
    while parameters.unlearned_feature_idx == parameters.learned_feature_idx
        [parameters.unlearned_feature, parameters.unlearned_feature_idx] =...
            randelement(fieldnames(parameters.features));
    end
    [parameters.unlearned_value, parameters.unlearned_value_idx] =...
        randelement(parameters.features.(parameters.unlearned_feature));
    
    sprintf('Learned: %s = %s', parameters.learned_feature, string(parameters.learned_value))
    sprintf('Unlearned: %s = %s', parameters.unlearned_feature, string(parameters.unlearned_value))
        
    screen_number = max(Screen('Screens'));
    window = PsychImaging('OpenWindow', screen_number,...
                          WhiteIndex(screen_number), [0, 0, 750, 750]);
    Screen('Flip', window);
    KbQueueCreate();
    KbQueueStart();
    
    % Enable psychtoolbox for BIAC computers
    if parameters.BIAC
        addpath('\\Munin\Data\Programs\MATLAB\PsychToolbox\3.0.11');
        BIACSetupPsychtoolbox;
        WaitForScanner;
    end
    
    % save the parameter settings
    writetable(removevars(struct2table(parameters), {'features', 'getFilename'}),...
               strcat(sprintf('%03d', parameters.participantNumber),...
               '_parameters.csv'));

    disp(strcat('Participant Number: ', string(parameters.participantNumber)))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Learning phase
    disp('Learning Phase')
    disp(learningInstruc)
    learning_stim = get_stimuli(parameters, parameters.learningTrials,...
                                parameters.learningPLearned,...
                                parameters.learningPUnlearned);
    [learning_data, exit] = learn(window, learning_stim, parameters);
    save_data = learning_data;
    if exit
        error('Aborting experiment');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Study phase
    disp('Study Phase')
    disp(studyInstruc)
    study_stim = get_stimuli(parameters, parameters.studyTrials,...
                             parameters.studyPLearned,...
                             parameters.studyPUnlearned, learning_stim);
    [study_data, exit] = study(window, study_stim, parameters);
    save_data = [save_data, study_data];
    
    if exit
        error('Aborting experiment');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test phase
    disp('Test Phase')
    disp(testInstruc)
    old = Shuffle(study_stim);
    old = old(1:min(parameters.oldTrials, length(old)));
    lures = get_stimuli(parameters, parameters.lureTrials,...
                        parameters.lurePLearned, parameters.lurePUnlearned,...
                        [learning_stim, study_stim]);
    [test_data, exit] = test(window, old, lures, parameters);
    save_data = [save_data, test_data];
    if exit
        error('Aborting experiment');
    end
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Thank the participants
    [~, height] = Screen('WindowSize', window);
    Screen('TextSize', window, 84);
    DrawFormattedText(window, 'Thank you for \nyour participation!', 'center', height/3.0, 0);
    Screen('TextSize', window, 48);
    DrawFormattedText(window, 'Press any key to exit.', 'center', height*2/3.0, 0);
    Screen('Flip', window);
    KbStrokeWait();
    
    % save all of the data
    writetable(struct2table(save_data),...
               strcat(sprintf('%03d', parameters.participantNumber), '.csv'));
    
    catch EXCEPTION
    ListenChar(0);
    sca;
    
    % save all of the current data
    if exist('save_data')
        writetable(struct2table(save_data),...
                   strcat(sprintf('%03d', parameters.participantNumber), '.csv'));
    end
    rethrow(EXCEPTION);
    end
    ListenChar(0);
    sca;
end



