function merged = mergeCloseLabels(labels, maxGap)
    if isempty(labels), merged = labels; return; end
    merged = labels(1);
    for i = 2:length(labels)
        gap = labels(i).StartTime - merged(end).EndTime;
        if gap < maxGap
            merged(end).EndTime = labels(i).EndTime;
        else
            merged(end+1) = labels(i); %#ok<AGROW>
        end
    end
end