function detectedLabels = PSDDetector(x, fs, varargin)
%PSDDETECTOR Detect ultrasonic vocalizations using a PSD-based method.
%
%   detectedLabels = PSDDetector(x, fs, 'Name', Value, ...)
%
%   This function applies a power spectral density (PSD)-based segmentation
%   method to detect ultrasonic vocalization (USV) events in high-frequency
%   audio signals. It performs bandpass filtering, spectrogram computation,
%   noise-adaptive thresholding, and optional ROI cropping to extract
%   meaningful vocalization segments.
%
%   Input arguments:
%       x  - Input audio signal (vector)
%       fs - Sampling frequency of the signal (Hz)
%
%   Optional Name-Value Pair Arguments:
%       'fcutMin'        : Minimum frequency for bandpass filter [40000]
%       'fcutMax'        : Maximum frequency for bandpass filter [120000]
%       'ROIstart'       : Start time of Region of Interest (s) [60]
%       'ROIlength'      : Duration of Region of Interest (s) [10]
%       'runWholeSignal' : If true, ignores ROI and uses full signal [true]
%       'segmentLength'  : STFT window length (samples) [8192]
%       'overlapFactor'  : Fractional overlap between windows [0.59]
%       'maWindow'       : Smoothing window for power envelope [3]
%       'noiseWindow'    : Window size for noise floor estimation [240]
%       'localWindow'    : Window for local mean/std in adaptive threshold [194]
%       'k'              : Scaling factor in adaptive threshold [0.023]
%       'w'              : SNR weighting factor in adaptive threshold [0.994]
%       'minEffectivePower' : Minimum mean envelope power to accept label [8.5e-5]
%
%   Output:
%       detectedLabels - Struct array with fields:
%           .StartTime       (s)
%           .EndTime         (s)
%           .Label           (default: "d")
%           .StartFrequency  (0 by default)
%           .EndFrequency    (0 by default)
%           .StartIndex      (in STFT frames)
%           .StopIndex       (in STFT frames)
%
%   Example:
%       labels = PSDDetector(audio, 250000, ...
%                 'ROIstart', 50, 'ROIlength', 10, ...
%                 'segmentLength', 8192, 'k', 0.02);
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

% Parse inputs
p = inputParser;
addRequired(p, 'x', @isnumeric);
addRequired(p, 'fs', @isnumeric);
addParameter(p, 'fcutMin', 40000, @isnumeric);
addParameter(p, 'fcutMax', 120000, @isnumeric);
addParameter(p, 'ROIstart', 60, @isnumeric);
addParameter(p, 'ROIlength', 10, @isnumeric);
addParameter(p, 'runWholeSignal', true, @islogical);
addParameter(p, 'segmentLength', 8192, @isnumeric);
addParameter(p, 'overlapFactor', 0.59, @isnumeric);
addParameter(p, 'maWindow', 3, @isnumeric);
addParameter(p, 'noiseWindow', 240, @isnumeric);
addParameter(p, 'localWindow', 194, @isnumeric);
addParameter(p, 'k', 0.023, @isnumeric);
addParameter(p, 'w', 0.994, @isnumeric);
addParameter(p, 'minEffectivePower', 0.000085, @isnumeric);

parse(p, x, fs, varargin{:});
opts = p.Results;

% Normalize
x = x - mean(x);
x = x / max(abs(x));
t_full = (0:length(x)-1) / fs;

% ROI
if opts.runWholeSignal
    xROI = x;
    tROI = t_full;
    opts.ROIstart = 0;
else
    idx1 = round(opts.ROIstart * fs) + 1;
    idx2 = round((opts.ROIstart + opts.ROIlength) * fs);
    xROI = x(idx1:idx2);
    tROI = t_full(idx1:idx2);
end

% Bandpass filter to remove anything below 40 kHz
            bpFilt = designfilt('bandpassiir', ...
                'FilterOrder', 12, ...
                'HalfPowerFrequency1', opts.fcutMin, ...
                'HalfPowerFrequency2', opts.fcutMax, ...
                'SampleRate', fs);

            xROI = filtfilt(bpFilt, xROI);  % Zero-phase filtering to preserve transients

% PSD
nfft = opts.segmentLength;
window = hamming(opts.segmentLength);
[S, F, T_spec] = spectrogram(xROI, window, round(opts.segmentLength * opts.overlapFactor), nfft, fs);
freqMask = (F >= opts.fcutMin) & (F <= opts.fcutMax);
powerEnvelope = sum(abs(S(freqMask, :)).^2, 1);
powerEnvelope = powerEnvelope / max(powerEnvelope);
powerEnvelope = smoothdata(powerEnvelope, 'movmean', opts.maWindow);

% Noise & effective envelope
noiseFloor = movmin(powerEnvelope, opts.noiseWindow);
effectiveEnvelope = max(powerEnvelope - noiseFloor, 0);

% SNR & thresholding
localSNR = min(effectiveEnvelope ./ (noiseFloor + eps), 10);
localMean = movmean(effectiveEnvelope, opts.localWindow);
localStd = movstd(effectiveEnvelope, opts.localWindow);
threshold = (localMean + opts.k * localStd) ./ (1 + opts.w * localSNR);

% Binary mask
binary = effectiveEnvelope > threshold;
edges = diff([0 binary 0]);
starts = find(edges == 1);
ends = find(edges == -1) - 1;

% Create output struct
n = length(starts);
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
    detectedLabels(i).StartTime     = T_spec(starts(i)) + opts.ROIstart;
    detectedLabels(i).EndTime       = T_spec(ends(i))   + opts.ROIstart;
    detectedLabels(i).StartIndex    = starts(i);
    detectedLabels(i).StopIndex     = ends(i);
end

% === MINIMUM POWER FILTER ===
filtered = [];
for i = 1:n
    idxRange = starts(i):ends(i);
    if mean(effectiveEnvelope(idxRange)) >= opts.minEffectivePower
        filtered = [filtered, detectedLabels(i)];
    end
end
detectedLabels = filtered;

end