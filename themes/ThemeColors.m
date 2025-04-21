classdef ThemeColors
    properties (Constant)
        Light = struct("Background", [1 1 1], "Text", [0 0 0], "Primary", [0.2 0.6 1], "Accent", [1 0.5 0]);
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