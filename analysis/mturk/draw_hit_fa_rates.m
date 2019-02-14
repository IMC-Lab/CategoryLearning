function draw_hit_fa_rates(dataFiles)
versionIdx = 1;
whichstage = 3; % retrieval
needExperts = 0;
hitData = table('Size', [0, 5],...
             'VariableNames', {'subject', 'Category', 'Rate', 'ExperimentNumber', 'StimuliType'},...
             'VariableTypes', {'double', 'string', 'double', 'double', 'double'});
faData = table('Size', [0, 5],...
             'VariableNames', {'subject', 'Category', 'Rate', 'ExperimentNumber', 'StimuliType'},...
             'VariableTypes', {'double', 'string', 'double', 'double', 'double'});

if isstring(dataFiles)
    dataFiles = {dataFiles};
end

for index = 1:length(dataFiles)
    dataFile = dataFiles{index};
    
    rawData = categ_data_extraction(dataFile,whichstage);
    memRates = SDT_cat_mem_prep(dataFile,rawData,versionIdx,needExperts, 1)
    
    fields = fieldnames(memRates);
    for i = 1:length(fields)
        field = fields{i};
        memRates.(field) = mean(memRates.(field));
    end
    memRates
    
    %memRates = struct2table(memRates);
    %numSubjects = max(rawData.subject);
    %for subject = 1:numSubjects
    %    experimentNumber = rawData(rawData.subject == subject,:).experimentNumber(1);
    %    stimuliType = index;
    %    subjHits = {subject, 'Learned', memRates.learnedHitRate(subject), experimentNumber, stimuliType;...
    %                subject, 'Unlearned', memRates.unlearnedHitRate(subject), experimentNumber, stimuliType;...
    %                subject, 'Both', memRates.bothHitRate(subject), experimentNumber, stimuliType;...
    %                subject, 'Neither', memRates.neitherHitRate(subject), experimentNumber, stimuliType};
    %    subjFAs = {subject, 'Learned', memRates.learnedHitRate(subject), experimentNumber, stimuliType;...
    %               subject, 'Unlearned', memRates.unlearnedHitRate(subject), experimentNumber, stimuliType;...
    %               subject, 'Both', memRates.bothHitRate(subject), experimentNumber, stimuliType;...
    %               subject, 'Neither', memRates.neitherHitRate(subject), experimentNumber, stimuliType};
    %    hitData = [hitData; subjHits];
    %    faData = [faData; subjFAs];
    %end
end

