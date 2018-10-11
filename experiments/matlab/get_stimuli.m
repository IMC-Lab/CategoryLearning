function objs = get_stimuli(parameters, count, p_learned, p_unlearned, exclude)
%GETSTIM  returns a list of object structs as given by GETOBJECT,
% with pLearned = percentage of stimuli in the learned category,
% and pUnlearned = percentage of stimuli in the unlearned category.
    if nargin < 5
        exclude = [];
    end
    
    learnedVals = parameters.features.(parameters.learned_feature);
    unlearnedVals = parameters.features.(parameters.unlearned_feature);
    
    % percentage of stimuli with each other value of the learned feature
    p_not_learned = (1 - p_learned) /...
        (length(parameters.features.(parameters.learned_feature)) - 1);
        
    % percentage of stimuli with each other value of the unlearned feature
    p_not_unlearned = (1 - p_unlearned) /...
        (length(parameters.features.(parameters.unlearned_feature)) - 1);
    
    
    % pre-allocate the struct array
    objs(count) = get_stim(parameters, nan(), nan(), exclude);
        
    % the index of the object currently being added
    index = 1;
    for i = 1:length(parameters.features.(parameters.learned_feature))
        for j = 1:length(parameters.features.(parameters.unlearned_feature))
            % calculate the number of stimuli with these values
            if i == parameters.learned_value_idx && j == parameters.unlearned_value_idx
                % In both categories
                N = p_learned * p_unlearned * count;
            elseif i == parameters.learned_value_idx
                % Only in learned category
                N = p_learned * p_not_unlearned * count;
            elseif j == parameters.unlearned_value_idx
                % Only in unlearned category
                N = p_not_learned * p_unlearned * count;
            else
                % In neither category
                N = p_not_learned * p_not_unlearned * count;
            end
            
            % Make N stimuli with these values, the rest being random
            for n = 1:N
                objs(index) = get_stim(parameters,...
                                       learnedVals{i},...
                                       unlearnedVals{j},...
                                       [objs, exclude]);
                index = index + 1;
            end
        end
    end
    
    objs = Shuffle(objs);
end
