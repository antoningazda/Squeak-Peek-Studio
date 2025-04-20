classdef ThemeColors
    properties (Constant)
        % Light theme
        Light = struct( ...
            'Background', [0.98 0.98 0.97], ...     % soft warm white
            'Primary', [0.42 0.76 0.85], ...        % soft blue
            'Accent', [0.99 0.73 0.55], ...         % gentle coral
            'Text', [0.1 0.1 0.1], ...              % dark gray
            'Border', [0.85 0.85 0.85] ...          % light gray
        );

        % Dark theme
        Dark = struct( ...
            'Background', [0.11 0.13 0.15], ...     % slate black
            'Primary', [0.32 0.84 0.90], ...        % vibrant cyan
            'Accent', [1.00 0.71 0.36], ...         % warm amber
            'Text', [0.95 0.95 0.95], ...           % light gray
            'Border', [0.25 0.25 0.25] ...          % dark gray
        );
    end
end