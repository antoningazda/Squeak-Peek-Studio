function stats_midpoint = compareLabels(providedLabelPath, detectedLabelPath, fs)
%COMPARELABELS Compare detected and reference labels using midpoint criterion.
%
% Inputs:
%   providedLabelPath - path to ground truth label file
%   detectedLabelPath - path to detected label file
%   fs                - sampling rate
%
% Output:
%   stats_midpoint    - struct with detection accuracy metrics

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