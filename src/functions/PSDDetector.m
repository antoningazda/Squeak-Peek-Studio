function detectedLabels = PSDDetector(x, fs, varargin)
% PSDDetector detects USV events in a waveform using a PSD-based method.
%
%   detectedLabels = PSDDetector(x, fs, 'param', value, ...)
%
%   Inputs:
%       x  : audio signal (vector)
%       fs : sampling rate in Hz
%
%   Optional Name-Value pairs:
%       'fcutMin'       : Min frequency cutoff (Hz) [40000]
%       'fcutMax'       : Max frequency cutoff (Hz) [120000]
%       'ROIstart'      : ROI start time (s) [60]
%       'ROIlength'     : ROI duration (s) [10]
%       'runWholeSignal': if true, ignore ROI [true]
%       'segmentLength' : PSD window length [8192]
%       'overlapFactor' : window overlap (0–1) [0.59]
%       'maWindow'      : moving avg window for smoothing [3]
%       'noiseWindow'   : for noise floor [240]
%       'localWindow'   : for local mean/std [194]
%       'k'             : adaptive threshold scale [0.023]
%       'w'             : local SNR weight [0.994]
%
%   Output:
%       detectedLabels: struct array with .StartTime and .EndTime (in sec)

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
addParameter(p, 'minEffectivePower', 0.00085, @isnumeric);

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