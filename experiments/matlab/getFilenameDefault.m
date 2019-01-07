function filename = getFilenameDefault(stim, varargin)
%GETFILENAMEDEFAULT obtain the filename of the given stimulus struct
% by concatenating the directory, file prefix, and the struct values
% separated by delim.
    p = inputParser;
    p.addParameter('dir', '.');
    p.addParameter('prefix', 'stim');
    p.addParameter('extension', '.png');
    p.addParameter('exclude', {'phase', 'is_learned', 'is_unlearned', 'is_old'});
    p.addParameter('delim', '_');
    p.parse(varargin{:});
    
    filename = strcat(p.Results.dir, '/', p.Results.prefix);
    fields = fieldnames(stim);
    
    % add values for all of the unexcluded fields
    for i = 1:length(fields)
        if ~any(cellfun(@(x) strcmp(x, fields{i}), p.Results.exclude))
            filename = strcat(filename, p.Results.delim, char(string(stim.(fields{i}))));
        end
    end
    
    filename = strcat(filename, p.Results.extension);
end