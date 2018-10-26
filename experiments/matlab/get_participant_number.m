function num = get_participant_number(filename)
% GET_PARTICIPNT_NUMBER returns the value of participantNumber stored in 
%                       the file of the given name, and increment the value.
%                       filename defaults to participantNumber.mat
    if nargin < 1
        filename = 'participantNumber.mat';
    end
    
    % load the conditionNumber from a file
    if exist(filename, 'file')
        load(filename, 'participantNumber');
    else
        participantNumber = 1;
    end
    
    num = participantNumber;
    participantNumber = max(participantNumber + 1, 1); % reset if overflow
    save(filename, 'participantNumber');
end