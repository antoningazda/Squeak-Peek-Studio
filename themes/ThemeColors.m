classdef ThemeColors
    properties (Constant)
Light = struct( ...
    "Background", [1, 1, 1], ...            % pure white
    "Text", [0.05, 0.05, 0.05], ...         % near-black text
    "Primary", [125/255, 206/255, 210/255], ...        % brighter soft blue
    "Accent", [249/255, 192/255, 110/255] ...          % brighter orange-yellow
);

Dark  = struct("Background", [0.1 0.1 0.1], "Text", [1 1 1], "Primary", [0.3 0.7 0.3], "Accent", [1 0.2 0.2]);
    end

    methods (Static)
        function theme = get(name)
            switch lower(name)
                case "light"
                    theme = ThemeColors.Light;
                case "dark"
                    theme = ThemeColors.Dark;
                otherwise
                    warning("Unknown theme '%s'. Falling back to Light.", name);
                    theme = ThemeColors.Light;
            end
        end
    end
end