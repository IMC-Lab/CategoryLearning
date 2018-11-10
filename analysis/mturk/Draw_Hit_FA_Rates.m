% Draw hit and false alarm rates
dataFiles = {'cat_20181110_flower_E5.csv', 'cat_20181110_insect_E5.csv'};
needExperts = 1;

for index = 1:length(dataFiles)
    dataFile = dataFiles{index};
    versionIdx = 1;
    whichstage = 3; % retrieval
    rawData = categ_data_extraction(dataFile,whichstage);
    sortedStruct = SDT_cat_mem_prep(dataFile,rawData,versionIdx,needExperts);
end