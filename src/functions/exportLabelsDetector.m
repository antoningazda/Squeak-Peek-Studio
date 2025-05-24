function exportLabelsDetector(labels, filePath)
%EXPORTLABELSDETECTOR Export detected labels in simplified format.
%
%   exportLabelsDetector(labels, filePath)
%
%   This function writes automatically detected labels to a text file in
%   a simplified format suitable for evaluation and review. Each label is
%   saved using two lines:
%
%       StartTime   EndTime     d
%       \           0.000000    0.000000
%
%   The label type is fixed as 'd' (detected), and the frequency bounds are
%   zeroed, as they are not relevant in this export context.
%
%   Input arguments:
%       labels   - Struct array with fields:
%                   .StartTime, .EndTime
%       filePath - Path to the output file (e.g., "detected_labels.txt")
%
%   Example:
%       exportLabelsDetector(detectedLabels, "output.txt")
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025
fid = fopen(filePath, 'w');
for i = 1:length(labels)
    fprintf(fid, '%.6f\t%.6f\td\n', labels(i).StartTime, labels(i).EndTime);
    fprintf(fid, '\\\t0.000000\t0.000000\n');
end
fclose(fid);
end