function filtered = removeShortLabels(labels, minDuration)
%REMOVESHORTLABELS Remove labels shorter than a minimum duration.
%
%   filtered = removeShortLabels(labels, minDuration)
%
%   This function filters out label segments whose duration is shorter
%   than the specified threshold. It is useful for eliminating spurious
%   or noise-induced detections in automatic segmentation pipelines.
%
%   Input arguments:
%       labels      - Struct array with at least:
%                       .StartTime (s)
%                       .EndTime   (s)
%       minDuration - Minimum allowed duration (in seconds)
%
%   Output:
%       filtered - Struct array containing only labels with duration
%                  greater than or equal to minDuration
%
%   Example:
%       cleaned = removeShortLabels(detectedLabels, 0.005);
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

durations = [labels.EndTime] - [labels.StartTime];
filtered = labels(durations >= minDuration);
end
