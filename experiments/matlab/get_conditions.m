function conditions = get_conditions(features, varargin)
%CONDITIONS return a table permuting all of the conditions for a category.
%           shuffle- if true, the conditions are randomly sorted.
%                    Defaults to true.
%           filename- the filename to write conditions to.
%                     Defaults to 'conditions.mat'
%           
    p = inputParser;
    p.addParameter('shuffle', true, @islogical);
    p.addParameter('filename', 'conditions.mat', @ischar);
    p.parse(varargin{:});
    
    % if the conditions have been saved already, just load them.
    if exist(p.Results.filename, 'file')
        load(p.Results.filename, 'conditions');
        return
    end

    feature_names = fieldnames(features);
    index = 1;
    for i = 1:length(feature_names)
        % all possible values for the feature
        values = features.(feature_names{i});
        for j = 1:length(values)
            feature_name{index} = feature_names{i};
            value = values{j};
            if isscalar(value)
                feature_value{index} = value(1);
            else
                feature_value{index} = value;
            end
            
            index = index + 1;
        end
    end
    
    conditions = horzcat(feature_name', feature_value');
    if p.Results.shuffle
        conditions = conditions(randperm(length(conditions)), :);
    end
    save(p.Results.filename, 'conditions');
end

