clc; clear; close all;
%% ========================================
%  PSD Parameter Optimization via Bayesian Optimization
%  Author: Antonín Gazda - me@antoningazda.com
%  Master's Thesis: Software for Visualization, Segmentation,
%                   and Sonification of Ultrasonic Vocalizations
%                   of Laboratory Rats (CTU, 2025)
%  ========================================

%% FIXED PARAMETERS
fcutMin       = 40000;
fcutMax       = 120000;
fs            = 250000;
ROIstart      = 100;
ROIlength     = 30;
runWholeSignal = false;

%% === USER INPUT ===
% Select audio file
[audioFileName, audioDir] = uigetfile({'*.wav','WAV Audio'}, 'Select USV Denoised Audio File');
if isequal(audioFileName, 0), error('Audio file selection canceled.'); end
audioFullPath = fullfile(audioDir, audioFileName);

% Select ground truth labels
[labelFileName, labelDir] = uigetfile({'*.txt','Text Label File'}, 'Select Ground Truth Label File');
if isequal(labelFileName, 0), error('Label file selection canceled.'); end
labelFullPath = fullfile(labelDir, labelFileName);

[x, fs_audio] = audioread(audioFullPath);
if fs_audio ~= fs
    x = resample(x, fs, fs_audio);
end
x = x - mean(x);
x = x / max(abs(x));

%% === LOAD LABELS ===
providedLabelsFull = importLabels(labelFullPath, fs);

if runWholeSignal
    providedLabelsROI = providedLabelsFull;
    ROIstart = 0;
    ROIlength = length(x)/fs;
else
    ROIend = ROIstart + ROIlength;
    providedLabelsROI = providedLabelsFull(arrayfun(@(l) l.StartTime >= ROIstart && l.EndTime <= ROIend, providedLabelsFull));
end
tempProvidedFile = fullfile(tempdir, "provided_labels_ROI.txt");
exportLabels(providedLabelsROI, tempProvidedFile);

%% === BAYESOPT VARIABLES ===
vars = [ ...
    optimizableVariable('segLen', [1024, 8192], 'Type','integer'), ...
    optimizableVariable('overlap', [0.25, 0.75]), ...
    optimizableVariable('maW', [1, 5], 'Type','integer'), ...
    optimizableVariable('noiseW', [50, 300], 'Type','integer'), ...
    optimizableVariable('localW', [25, 250], 'Type','integer'), ...
    optimizableVariable('k', [0.01, 0.05]), ...
    optimizableVariable('w', [0.9, 1.0]) ];

%% === RUN OPTIMIZATION ===
objFun = @(opt) detectorObjective(opt, x, fs, ROIstart, ROIlength, runWholeSignal, fcutMin, fcutMax, tempProvidedFile);
results = bayesopt(objFun, vars, ...
    'MaxObjectiveEvaluations', 30, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', ...
    'Verbose', 1);

bestParams = bestPoint(results);
fprintf("\nBest F1: %.4f\n", -results.MinObjective);
disp(bestParams);

%% === FINAL DETECTION ===
labels = PSDDetector(x, fs, ...
    'segmentLength', bestParams.segLen, ...
    'overlapFactor', bestParams.overlap, ...
    'maWindow', bestParams.maW, ...
    'noiseWindow', bestParams.noiseW, ...
    'localWindow', bestParams.localW, ...
    'k', bestParams.k, ...
    'w', bestParams.w, ...
    'ROIstart', ROIstart, ...
    'ROIlength', ROIlength, ...
    'fcutMin', fcutMin, ...
    'fcutMax', fcutMax, ...
    'runWholeSignal', runWholeSignal);

tempDetectedFile = fullfile(tempdir, "detected_labels.txt");
exportLabelsDetector(labels, tempDetectedFile);

stats = compareLabels(tempProvidedFile, tempDetectedFile, fs);
fprintf('\nDetection Performance:\n');
disp(stats);

%% === SAVE DETECTION OUTPUT ===
[~, audioBaseName, ~] = fileparts(audioFileName);
outputPath = fullfile(audioDir, [audioBaseName '_detected.txt']);
exportLabelsDetector(labels, outputPath);
fprintf("Detection results saved to: %s\n", outputPath);

%% === OBJECTIVE FUNCTION ===
function objective = detectorObjective(opt, x, fs, ROIstart, ROIlength, runWholeSignal, fcutMin, fcutMax, gtPath)
labels = PSDDetector(x, fs, ...
    'segmentLength', opt.segLen, ...
    'overlapFactor', opt.overlap, ...
    'maWindow', opt.maW, ...
    'noiseWindow', opt.noiseW, ...
    'localWindow', opt.localW, ...
    'k', opt.k, ...
    'w', opt.w, ...
    'ROIstart', ROIstart, ...
    'ROIlength', ROIlength, ...
    'fcutMin', fcutMin, ...
    'fcutMax', fcutMax, ...
    'runWholeSignal', runWholeSignal);

tempDetectedPath = fullfile(tempdir, "detected_labels.txt");
exportLabelsDetector(labels, tempDetectedPath);

stats = compareLabels(gtPath, tempDetectedPath, fs);
objective = -stats.F1Score;
end