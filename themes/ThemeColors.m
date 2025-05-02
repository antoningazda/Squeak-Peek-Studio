classdef ThemeColors
    properties (Constant)
Light = struct( ...
    "Background", [1, 1, 1], ...            % pure white
    "Text", [0.05, 0.05, 0.05], ...         % near-black text
    "Primary", [125/255, 206/255, 210/255], ...        % brighter soft blue
    "Accent", [249/255, 192/255, 110/255] ...          % brighter orange-yellow
);

Dark = struct( ...
    "Background", [0.07, 0.07, 0.07], ...                % deep dark gray
    "Text", [0.95, 0.95, 0.95], ...                      % light text
    "Primary", [72/255, 175/255, 179/255], ...           % muted teal (dark mode safe)
    "Accent", [255/255, 171/255, 64/255] ...             % warm amber accent
);
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