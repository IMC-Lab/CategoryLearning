features = struct('segment_count', {{1, 2, 3}},...
                  'segment_shape', {{'circle', 'triangle', 'rectangle'}},...
                  'antennae_count', {{1, 2, 4}},...
                  'antennae_color', {{'purple', 'orange', 'lightblue'}},...
                  'wing_color', {{'blue', 'yellow', 'green'}});
DIR = strcat(pwd, '/../../stimuli/insects/images');

learningTrials = 54;
studyTrials = 24; % 8 stimuli for each value of the learned feature
conditionFilename = 'insect-conditions.mat';

CategoryLearning('features', features,...
                 'learningTrials', 3,...
                 'studyTrials', 3,...
                 'oldTrials', 0,...
                 'lureTrials', 3,...
                 'conditionFilename', conditionFilename,...
                 'getFilename', @(x) getFilenameDefault(x, 'dir', DIR,...
                                                        'prefix', 'insect'))