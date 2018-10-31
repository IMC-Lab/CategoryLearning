% Connect to the Daq device in the scanner and wait for a pulse.
% 
% Code extracted from:
% https://wiki.duke.edu/pages/viewpage.action?pageId=131172907

try
    daq = DaqDeviceIndex();
catch
    error('Daq device not found');
end


curcount = DaqCIn(daq);
while 1
    if DaqCIn(daq) > curcount
        % start your task
        break
    else
        pause(.05)
        % do short sleep here just so you’re not executing
        % the counter check a billion times
    end
end