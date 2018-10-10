function [element, idx] = randelement(cellarray)
    idx = randi(length(cellarray));
    element = cellarray{idx};
end