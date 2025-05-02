function filtered = removeShortLabels(labels, minDuration)
    durations = [labels.EndTime] - [labels.StartTime];
    filtered = labels(durations >= minDuration);
end
