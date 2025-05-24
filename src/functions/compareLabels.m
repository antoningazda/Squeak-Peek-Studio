function stats_midpoint = compareLabels(providedLabelPath, detectedLabelPath, fs)
%COMPARELABELS Evaluate label detection accuracy using midpoint matching.
%
%   stats = compareLabels(providedLabelPath, detectedLabelPath, fs)
%
%   This function compares detected event labels to ground truth labels
%   using the midpoint criterion: a detected label is counted as a true
%   positive if it fully overlaps the midpoint of a ground truth label.
%
%   Input arguments:
%       providedLabelPath - Path to manually annotated label file
%       detectedLabelPath - Path to detected label file (e.g., from a detector)
%       fs                - Sampling frequency in Hz
%
%   Output:
%       stats_midpoint    - Struct containing detection accuracy metrics:
%           - TotalProvidedLabels
%           - TotalDetectedLabels
%           - TruePositives
%           - FalsePositives
%           - FalseNegatives
%           - Precision
%           - Recall
%           - F1Score
%
%   Notes:
%       - Matching is performed using label midpoints only.
%       - One-to-one matching is enforced: each detected label can match
%         only one provided label and vice versa.
%
%   Example:
%       stats = compareLabels("ref.txt", "detected.txt", 250000);
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

    % Load labels
    providedLabels = importLabels(providedLabelPath, fs);
    detectedLabels = importLabels(detectedLabelPath, fs);

    % Initialize
    totalProvided = numel(providedLabels);
    totalDetected = numel(detectedLabels);
    matchedDetected = false(1, totalDetected);
    truePositives = 0;
    falseNegatives = 0;

    % Match using midpoint criterion
    for i = 1:totalProvided
        midpoint = (providedLabels(i).StartTime + providedLabels(i).EndTime) / 2;
        matched = false;
        for j = 1:totalDetected
            if ~matchedDetected(j)
                dStart = detectedLabels(j).StartTime;
                dEnd = detectedLabels(j).EndTime;
                if midpoint >= dStart && midpoint <= dEnd
                    matchedDetected(j) = true;
                    matched = true;
                    break;
                end
            end
        end
        if matched
            truePositives = truePositives + 1;
        else
            falseNegatives = falseNegatives + 1;
        end
    end

    falsePositives = sum(~matchedDetected);

    % Compute metrics
    precision = truePositives / max(truePositives + falsePositives, 1);
    recall    = truePositives / max(truePositives + falseNegatives, 1);
    f1        = 2 * (precision * recall) / max(precision + recall, eps);

    % Output struct
    stats_midpoint = struct( ...
        'TotalProvidedLabels', totalProvided, ...
        'TotalDetectedLabels', totalDetected, ...
        'TruePositives', truePositives, ...
        'FalsePositives', falsePositives, ...
        'FalseNegatives', falseNegatives, ...
        'Precision', precision, ...
        'Recall', recall, ...
        'F1Score', f1 ...
    );    
end