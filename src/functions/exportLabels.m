function exportLabels(labels, filePath)
%EXPORTLABELS Export a label struct array to a formatted text file.
%
%   exportLabels(labels, filePath)
%
%   This function writes a label array (as produced by a detector or
%   manually annotated) into a tab-delimited text file with the following format:
%
%       StartTime   EndTime     Label
%       \           StartFreq   EndFreq
%
%   Each label is saved in two lines: one with time and classification,
%   and one with frequency bounds. This format is compatible with the
%   importLabels function used in this application.
%
%   Input arguments:
%       labels   - Struct array with fields:
%                     .StartTime, .EndTime, .Label,
%                     .StartFrequency, .EndFrequency
%       filePath - Destination path for the exported .txt file
%
%   Example:
%       exportLabels(detectedLabels, "myOutput.txt")
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

fid = fopen(filePath, 'w');
if fid == -1
    error("Could not open file %s for writing.", filePath);
end

for i = 1:length(labels)
    % Write time and label line
    fprintf(fid, '%.6f\t%.6f\t%s\n', ...
        labels(i).StartTime, labels(i).EndTime, labels(i).Label);

    % Write frequency line
    fprintf(fid, '\\\t%.6f\t%.6f\n', ...
        labels(i).StartFrequency, labels(i).EndFrequency);
end
fclose(fid);
end