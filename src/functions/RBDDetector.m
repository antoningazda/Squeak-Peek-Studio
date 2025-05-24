function detectedLabels = RBDDetector(audioData, fs, varargin)
%RBDDETECTOR Detect ultrasonic vocalizations using the RBD method.
%
%   detectedLabels = RBDDetector(audioData, fs, 'Name', Value, ...)
%
%   This function detects ultrasonic vocalization (USV) events in an
%   audio signal using the Relative Bayesian Difference (RBD) method.
%   It applies a recursive model-based change detection algorithm to
%   extract regions of interest based on statistical transitions in
%   local signal characteristics.
%
%   Input arguments:
%       audioData - Input waveform (vector)
%       fs        - Sampling rate in Hz
%
%   Name-Value Pair Arguments (optional):
%       'fcutMin'               : Minimum frequency for bandpass filter [40000]
%       'fcutMax'               : Maximum frequency for bandpass filter [120000]
%       'wlen'                  : RBD window length in seconds [0.04]
%       'AR_order_left'         : Left autoregressive model order [4]
%       'AR_order_right'        : Right autoregressive model order [4]
%       'Bayesian_Evidence_order': Order of the Bayesian model [4]
%       'dynamicScaling'        : Scaling factor for dynamic threshold [0.3]
%       'smoothingWindowRBD'    : RBD output smoothing window (sec) [0.02]
%       'smoothingWindowThr'    : Threshold smoothing window (sec) [0.02]
%       'amplitudeThreshold'    : Minimum amplitude for acceptance [0.02]
%
%   Output:
%       detectedLabels - Struct array with fields:
%           .StartTime       (s)
%           .EndTime         (s)
%           .Label           (default: "d")
%           .StartFrequency  (0 by default)
%           .EndFrequency    (0 by default)
%           .StartIndex      (in samples)
%           .StopIndex       (in samples)
%
%   Example:
%       labels = RBDDetector(x, 250000, 'wlen', 0.05, 'AR_order_left', 3);
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

% === Defaults ===
p = inputParser;
addParameter(p, 'fcutMin', 40000);
addParameter(p, 'fcutMax', 120000);
addParameter(p, 'wlen', 0.04);
addParameter(p, 'AR_order_left', 4);
addParameter(p, 'AR_order_right', 4);
addParameter(p, 'Bayesian_Evidence_order', 4);
addParameter(p, 'dynamicScaling', 0.3);
addParameter(p, 'smoothingWindowRBD', 0.02);
addParameter(p, 'smoothingWindowThr', 0.02);
addParameter(p, 'amplitudeThreshold', 0.02);

parse(p, varargin{:});
opts = p.Results;

% === Normalize ===
audioData = audioData - mean(audioData);
audioData = audioData / max(abs(audioData));

% === RBD Calculation ===
fprintf("Calculating RBD...\n");
rbdOut = RBD(audioData, round(opts.wlen * fs), opts.AR_order_left, opts.AR_order_right, opts.Bayesian_Evidence_order);
rbdOut = rbdOut / max(abs(rbdOut));

% === Smoothing & Thresholding ===
smoothRbdOut = movmean(rbdOut, round(opts.smoothingWindowRBD * fs));
dynamicThreshold = movmean(smoothRbdOut, round(opts.smoothingWindowThr * fs)) * opts.dynamicScaling;

binary = smoothRbdOut > dynamicThreshold & smoothRbdOut > opts.amplitudeThreshold;
edges = diff([0 binary 0]);
starts = find(edges == 1);
ends = find(edges == -1) - 1;
n = length(starts);

% === Output Format ===
detectedLabels = struct( ...
    'StartTime', num2cell(zeros(1,n)), ...
    'EndTime', num2cell(zeros(1,n)), ...
    'Label', repmat("d", 1, n), ...
    'StartFrequency', num2cell(zeros(1,n)), ...
    'EndFrequency', num2cell(zeros(1,n)), ...
    'StartIndex', num2cell(zeros(1,n)), ...
    'StopIndex', num2cell(zeros(1,n)) ...
);

for i = 1:n
    detectedLabels(i).StartIndex = starts(i);
    detectedLabels(i).StopIndex  = ends(i);
    detectedLabels(i).StartTime  = starts(i) / fs;
    detectedLabels(i).EndTime    = ends(i) / fs;
end

end