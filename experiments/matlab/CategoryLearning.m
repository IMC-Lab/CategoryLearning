function CategoryLearning(varargin)
% CATEGORYLEARNING  run the paradigm for testing the memory effects of
%                   category learning defined in "Tracking the emergence
%                   of memories: A category learning paradigm to explore
%                   schema-driven recognition" by De Brigard  et al (2017).
%
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
% oldPLearned :- the percentage of old stimuli in the learned category
% oldPUnlearned :- the percentage of old stimuli in the unlearned category
% lureTrials :- the number of new items in the test list
% lurePLearned :- the percentage of lures in the learned category
% lurePUnlearned :- the percentage of lures in the unlearned category
% testITI :- the intertrial interval for the test phase. 
%            Defaults to 1 second.
% testMinViewing :- how long to wait before recording keypresses
% testOldKey :- the key to press if a stimulus is old
% testNewKey :- the key to press if a stimulus is new
%
%
    % setup PsychToolbox
    close all;
    sca;
    PsychDefaultSetup(2);

    % parse the input
    p = inputParser;
    p.addParameter('features', struct(), ...
                   @(x) ~isempty(x) & ~all(structfun(@isempty, x)));
    p.addParameter('getFilename', @getFilenameDefault,...
                   @(x) isa(x, 'function_handle'));
    p.addParameter('escapeKey', 'ESCAPE', @ischar);
               
    p.addParameter('learningTrials', 9, @(x) x > 0);
    p.addParameter('learningPLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('learningPUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('learningITI', 1.0, @(x) x > 0);
    p.addParameter('learningMinViewing', 0.5, @(x) x >= 0);
    p.addParameter('learningYKey', 'y', @ischar);
    p.addParameter('learningNKey', 'n', @ischar);
    
    p.addParameter('studyTrials', 9, @(x) x > 0);
    p.addParameter('studyPLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('studyPUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('studyTime', 5.0, @(x) x > 0);
    p.addParameter('studyITI', 1.0, @(x) x > 0); 
    
    p.addParameter('oldTrials', 9, @(x) x > 0);
    p.addParameter('oldPLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('oldPUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('lureTrials', 9, @(x) x > 0);
    p.addParameter('lurePLearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('lurePUnlearned', 1.0/3.0, @(x) x > 0 && x < 1.0);
    p.addParameter('testITI', 1.0, @(x) x > 0);
    p.addParameter('testMinViewing', 0.5, @(x) x >= 0);
    p.addParameter('testOldKey', 'y', @ischar);
    p.addParameter('testNewKey', 'n', @ischar);
    p.parse(varargin{:});
    parameters = p.Results;  
    
    % Select the feature values that define
    % the learned and unlearned categories
    [parameters.learned_feature, parameters.learned_feature_idx] =...
        randelement(fieldnames(parameters.features));
    [parameters.learned_value, parameters.learned_value_idx] =...
        randelement(parameters.features.(parameters.learned_feature));
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Learning phase
    learning_stim = get_stimuli(parameters, parameters.learningTrials,...
                                parameters.learningPLearned,...
                                parameters.learningPUnlearned);
    [learning_data, exit] = learn(window, learning_stim, parameters);
    writetable(struct2table(learning_data), 'learning_data.csv');
    if exit
        sca;
        return
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Study phase
    study_stim = get_stimuli(parameters, parameters.studyTrials,...
                             parameters.studyPLearned,...
                             parameters.studyPUnlearned, learning_stim);
    [study_data, exit] = study(window, study_stim, parameters);
    writetable(struct2table(study_data), 'study_data.csv');
    if exit
        sca;
        return
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test phase
    old = Shuffle(study_stim);
    old = old(1:parameters.oldTrials);
    lures = get_stimuli(parameters, parameters.lureTrials,...
                        parameters.lurePLearned, parameters.lurePUnlearned,...
                        [learning_stim, study_stim]);
    [test_data, exit] = test(window, old, lures, parameters);
    writetable(struct2table(test_data), 'test_data.csv');
    if exit
        sca;
        return
    end
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Thank the participants (TODO)
    sca;
end



