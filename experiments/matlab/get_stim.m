function obj = get_stim(parameters, learned_value, unlearned_value, exclude)
%GETSTIM returns a struct representing a stimulus object
%        with randomly selected values from the struct parameters.features.
%        learned_value is the object's value for the learned feature.
%        unlearned_value is the object's value for the unlearned feature.
%        The returned object will not equal any of the objects in exclude.
    obj = struct();
    obj.is_learned = isequal(learned_value, parameters.learned_value);
    obj.is_unlearned = isequal(unlearned_value, parameters.unlearned_value);
    fields = fieldnames(parameters.features);
    for n = 1:length(fields)
        fieldname = fields{n};
        values = parameters.features.(fieldname);
        obj.(fieldname) = randelement(values);
    end
    
    % Make sure the learned & unlearned features are set properly
    obj.(parameters.learned_feature) = learned_value;
    obj.(parameters.unlearned_feature) = unlearned_value;
    
    % exclude any of the objects in exclude
    while any(arrayfun(@(x) isequal(obj, x), exclude))
        obj = get_stim(parameters, learned_value, unlearned_value, exclude);
    end
end