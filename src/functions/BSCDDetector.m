function detectedLabels = BSCDDetector(audioData, fs, varargin)
% BSCDDetector Detects ultrasonic vocalization events using the Bayesian
% Sequential Change Detector (BSCD) method.
%
%   detectedLabels = BSCDDetector(audioData, fs)
%   detectedLabels = BSCDDetector(audioData, fs, 'Name', Value, ...)
%
%   This function applies a Bayesian evidence-based change detection
%   method to identify segments of interest (e.g., ultrasonic vocalizations)
%   in high-frequency audio data. It uses a smoothed BSCD output as the
%   detection envelope and performs thresholding to extract event boundaries.
%
%   Input arguments:
%       audioData      : Vector containing the audio signal
%       fs             : Sampling frequency in Hz
%
%   Name-Value Pair Arguments (optional):
%       'fcutMin'        : Minimum frequency cutoff for bandpass filter [40000]
%       'fcutMax'        : Maximum frequency cutoff for bandpass filter [120000]
%       'ROIstart'       : Region of interest start time in seconds [1]
%       'ROIlength'      : Region of interest duration in seconds [1]
%       'runWholeSignal' : If true, ignore ROI and process full signal [true]
%
%       BSCD-specific parameters:
%       'wlen'           : BSCD window length in seconds [0.01]
%       'maWindow'       : Moving average window (samples) for envelope smoothing [5000]
%
%       Adaptive thresholding parameters:
%       'noiseWindow'    : Noise estimation window (samples) [256]
%       'localWindow'    : Local mean/std window for threshold [256]
%       'k'              : Scaling factor for adaptive threshold [0.023]
%       'w'              : SNR weight for adaptive threshold [0.994]
%
%   Output:
%       detectedLabels : Struct array with fields:
%           - StartTime (s)
%           - EndTime (s)
%           - Label (default 'd')
%           - StartFrequency / EndFrequency (set to 0)
%           - StartIndex / StopIndex (in samples)
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025
%
%
%   Example:
%       labels = BSCDDetector(x, fs, 'ROIstart', 10, 'ROIlength', 5);
%% Input Parsing and Default Settings
p = inputParser;
% Basic settings
addParameter(p, 'fcutMin', 40000, @isnumeric);
addParameter(p, 'fcutMax', 120000, @isnumeric);
addParameter(p, 'ROIstart', 1, @isnumeric);
addParameter(p, 'ROIlength', 1, @isnumeric);
addParameter(p, 'runWholeSignal', true, @islogical);

% BSCD detector parameters
addParameter(p, 'wlen', 0.01, @isnumeric);
addParameter(p, 'maWindow', 5000, @isnumeric);

% Noise tracking & Adaptive Threshold parameters
addParameter(p, 'noiseWindow', 256, @isnumeric);
addParameter(p, 'localWindow', 256, @isnumeric);
addParameter(p, 'k', 0.023, @isnumeric);
addParameter(p, 'w', 0.994, @isnumeric);

parse(p, varargin{:});
opts = p.Results;

%% LOAD AUDIO

t_full = (0:length(audioData)-1) / fs;
audioData = audioData - mean(audioData);
audioData = audioData / max(abs(audioData));

%% SELECT SIGNAL ROI or Whole Signal
if opts.runWholeSignal
    xROI = audioData;
    tROI = t_full;
    opts.ROIstart = 0;       % Whole signal starts at 0
    opts.ROIlength = t_full(end);
else
    startIndex = round(opts.ROIstart * fs) + 1;
    endIndex   = round((opts.ROIstart + opts.ROIlength) * fs);
    xROI = audioData(startIndex:endIndex);
    tROI = t_full(startIndex:endIndex);
end

%% BANDPASS FILTER
bpFilter = designfilt('bandpassiir', 'FilterOrder', 12, ...
    'HalfPowerFrequency1', opts.fcutMin, 'HalfPowerFrequency2', opts.fcutMax, ...
    'SampleRate', fs);
filteredAudioSegment = filtfilt(bpFilter, xROI);

%% BSCD CALCULATION
%tic;
%fprintf('Calculating BSCD...\n');
bscdOut = bscd(filteredAudioSegment.^2, opts.wlen * fs);
%toc;
bscdOutMovMean = smoothdata(bscdOut, 'movmean', opts.maWindow);

% Create time axis for BSCD output (using ROI start and ROIlength)
startTime = opts.ROIstart;
endTime = opts.ROIstart + opts.ROIlength;
t_bscd = linspace(startTime, endTime, length(bscdOutMovMean));
powerEnvelope = bscdOutMovMean;

%% DETECTION USING BSCD
optimalThreshold = mean(powerEnvelope) * ones(size(powerEnvelope));
binaryDetections = powerEnvelope > optimalThreshold;
detectionDiff = diff([0, binaryDetections, 0]);
startIndices = find(detectionDiff == 1);
endIndices = find(detectionDiff == -1) - 1;
nEvents = length(startIndices);
detectedLabels = struct('StartTime', cell(nEvents,1), 'EndTime', cell(nEvents,1));
for i = 1:nEvents
    detectedLabels(i).StartTime = t_bscd(startIndices(i));
    detectedLabels(i).EndTime = t_bscd(endIndices(i));
end


% Create output struct
n = length(startIndices);
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
    detectedLabels(i).StartTime     = t_bscd(startIndices(i)) + opts.ROIstart;
    detectedLabels(i).EndTime       = t_bscd(endIndices(i))   + opts.ROIstart;
    detectedLabels(i).StartIndex    = startIndices(i);
    detectedLabels(i).StopIndex     = endIndices(i);
end
end