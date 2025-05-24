classdef ThemeColors
%THEMECOLORS Provides predefined UI theme color sets for the application.
%
%   This utility class defines reusable color themes for the visual
%   styling of UI components in the Squeak Peek Studio App. Each theme
%   consists of named fields: Background, Text, Primary, and Accent,
%   stored as RGB triplets in the range [0,1].
%
%   Themes:
%       - Light: White background with soft blue and orange accents
%       - Gray : White background with monochrome greyscale tones
%
%   Usage:
%       theme = ThemeColors.get("light");
%       app.SpectrogramUIAxes.Color = theme.Background;
%
%   Static Methods:
%       get(name)  - Returns the struct for a specified theme name
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

    properties (Constant)
        Light = struct( ...
            "Background", [1, 1, 1], ...                  % pure white
            "Text", [0.05, 0.05, 0.05], ...                   % near-black text
            "Primary", [125/255, 206/255, 210/255], ...   % brighter soft blue
            "Accent", [249/255, 192/255, 110/255] ...     % brighter orange-yellow
            );

        Gray = struct( ...
            "Background", [1.0, 1.0, 1.0], ...      % pure white background
            "Text", [0.05, 0.05, 0.05], ...         % near-black text
            "Primary", [0.8, 0.8, 0.8], ...         % medium grey primary highlight
            "Accent", [0.6, 0.6, 0.6] ...           % darker grey for emphasis/accent
            );
    end

    methods (Static)
        function theme = get(name)
            switch lower(name)
                case "light"
                    theme = ThemeColors.Light;
                case "gray"
                    theme = ThemeColors.Gray;
                otherwise
                    warning("Unknown theme '%s'. Falling back to Light.", name);
                    theme = ThemeColors.Light;
            end
        end
    end
end