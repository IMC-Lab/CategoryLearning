function objs = get_stimuli(parameters, count, p_learned, p_unlearned, exclude)
%GETSTIM  returns a list of object structs as given by GETOBJECT,
% with pLearned = percentage of stimuli in the learned category,
% and pUnlearned = percentage of stimuli in the unlearned category.
    if nargin < 5
        exclude = [];
    end
    
    learned_vals = parameters.features.(parameters.learned_feature);
    unlearned_vals = parameters.features.(parameters.unlearned_feature);
    
    % percentage of stimuli with each other value of the (un)learned feature
    p_not_learned = (1 - p_learned) /...
        (length(parameters.features.(parameters.learned_feature)) - 1);
    p_not_unlearned = (1 - p_unlearned) /...
        (length(parameters.features.(parameters.unlearned_feature)) - 1);
    
    
    % pre-allocate the struct array
    objs(count) = get_stim(parameters, nan(), nan(), exclude);
    remainder_objs = [];
        
    % the index of the object currently being added
    index = 1;
    for i = 1:length(parameters.features.(parameters.learned_feature))
        for j = 1:length(parameters.features.(parameters.unlearned_feature))
            is_learned = i == parameters.learned_value_idx;
            is_unlearned = j == parameters.unlearned_value_idx;
            % calculate the number of stimuli with these values
            if is_learned && is_unlearned
                N = p_learned * p_unlearned * count;
            elseif is_learned
                N = p_learned * p_not_unlearned * count;
            elseif is_unlearned
                N = p_not_learned * p_unlearned * count;
            else
                % In neither category
                N = p_not_learned * p_not_unlearned * count;
            end
            
            % Make N stimuli with these values, the rest being random
            for n = 1:(N + 1)
                obj = get_stim(parameters, learned_vals{i},...
                                unlearned_vals{j}, [objs, exclude]);
                if n < floor(N + 1)
                    objs(index) = obj;
                    index = index + 1;
                else
                    remainder_objs = [remainder_objs, obj];
                end
            end
        end
    end
    
    % Add any remainder items if there's room
    while index <= count
        i = randi(length(remainder_objs));
        objs(index) = remainder_objs(i);
        remainder_objs(i) = [];
        index = index + 1;
    end
    
    objs = Shuffle(objs);
end
