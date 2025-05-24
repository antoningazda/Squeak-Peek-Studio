function merged = mergeCloseLabels(labels, maxGap)
%MERGECLOSELABELS Merge adjacent labels separated by short gaps.
%
%   merged = mergeCloseLabels(labels, maxGap)
%
%   This function takes a struct array of labels (typically sorted by
%   time) and merges any consecutive labels that are separated by a time
%   gap smaller than `maxGap`. It is useful for cleaning up label outputs
%   that contain small temporal interruptions between events that likely
%   belong to the same underlying signal.
%
%   Input arguments:
%       labels - Struct array of label events with at least:
%                  .StartTime (in seconds)
%                  .EndTime   (in seconds)
%       maxGap - Maximum allowed time gap between events to merge (seconds)
%
%   Output:
%       merged - Struct array with merged events
%
%   Example:
%       merged = mergeCloseLabels(detectedLabels, 0.002);
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

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