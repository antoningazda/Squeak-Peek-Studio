function [x, t] = vocoder(signal, fs, ST, slowdown, SpectralLow, SpectralHigh, wlen, wshift)
    % VOCODER with pitch shifting and slowdown
    %
    % Inputs:
    %   signal: raw audio
    %   fs: sample rate
    %   ST: semitone shift (e.g., -50)
    %   slowdown: slowdown factor (>1 slows down)
    %   SpectralLow, SpectralHigh: freq cutoffs in Hz
    %   wlen: FFT window length (e.g. 512)
    %   wshift: frame shift (e.g. 128)
    %
    % Outputs:
    %   x: processed audio (audible range)
    %   t: time vector

    N = length(signal);              
    signal = signal - mean(signal);
    signal = signal / max(abs(signal) + eps);  % normalize

    N1 = wshift;
    N2 = round(2^(ST / 12) * N1);
    R  = N2 / N1;

    % === ANALYSIS ===
    X = [];
    k = 1;
    for start = 0:wshift:N - wlen
        frame = signal(start + 1:start + wlen) .* hamming(wlen);
        X(:, k) = fft(frame);     
        k = k + 1;
    end

    origLen = size(X, 2);
    xi = (0:1/R:origLen - 2)';
    Xmag = interp1(0:origLen - 1, abs(X'), xi, 'linear', 'extrap')';

    new_grid = floor(xi) + 1;
    D = diff(angle(X'))';
    D_new = D(:, new_grid);
    phaseX = cumsum(D_new');
    Y = (Xmag .* exp(1j * phaseX))';

    % === SPECTRAL CUTOFF ===
    spectralCutColumnHigh = round((fs - SpectralHigh) / (fs / wlen)) + 1;
    spectralCutColumnLow  = round((fs - SpectralLow) / (fs / wlen)) + 1;
    Y(1:spectralCutColumnHigh, :) = 0;
    Y(spectralCutColumnLow:end, :) = 0;

    % === SYNTHESIS ===
    x = zeros(N + wlen, 1);
    for k = 1:size(Y, 2)
        segment = real(ifft(Y(:, k), wlen)) .* hamming(wlen);
        startIdx = (k - 1) * wshift + 1;
        x(startIdx:startIdx + wlen - 1) = x(startIdx:startIdx + wlen - 1) + segment;
    end

    % === SLOWDOWN ===
    x = resample(x, slowdown, 1);
    x = x / max(abs(x) + eps);
    t = (0:length(x) - 1) / fs;
end