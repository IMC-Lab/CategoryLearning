% categorization experiment
function thisT = categ_data_extraction(fileName,whichstage)
isOldData = -1;

%% read data
dataRootPath = 'data/';
T = readtable([dataRootPath, fileName]);

lrnT = T(strcmp(T.task,'learn'),:);
memT = T(strcmp(T.task,'study'),:);
retT = T(strcmp(T.task,'test'),:);

switch whichstage
    case 1
        thisT = lrnT;
    case 2
        thisT = memT;
    case 3
        thisT = retT;
end
