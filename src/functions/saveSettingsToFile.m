function saveSettingsToFile(app, filepath)
%SAVESETTINGSTOFILE Save application settings to a JSON file.
%
%   saveSettingsToFile(app)
%   saveSettingsToFile(app, filepath)
%
%   This method saves the current application settings stored in
%   `app.AppSettings` to a `.json` file. If `filepath` is not provided,
%   a file dialog prompts the user to select the destination path.
%
%   Input arguments:
%       app      - App Designer app object containing AppSettings struct
%       filepath - (optional) Full path to save the settings JSON file
%
%   Notes:
%       - Settings are serialized using MATLAB's built-in jsonencode
%       - If the file cannot be opened, a UI alert is shown
%
%   Example:
%       app.saveSettingsToFile();               % Prompt user to save
%       app.saveSettingsToFile("myconfig.json");% Save directly
%
%   Author:
%       Antonín Gazda me@antoningazda.com
%       Master's Thesis — Software for Visualization, Segmentation,
%       and Sonification of Ultrasonic Vocalizations of Laboratory Rats
%       Czech Technical University in Prague, 2025

if nargin < 2
    [file, path] = uiputfile('*.json', 'Save Settings As');
    if isequal(file, 0)
        return; % User canceled
    end
    filepath = fullfile(path, file);
end

jsonText = jsonencode(app.AppSettings);
fid = fopen(filepath, 'w');
if fid == -1
    uialert(app.SqueakPeekStudioUIFigure, 'Could not open file for writing.', 'File Error');
    return;
end
fwrite(fid, jsonText, 'char');
fclose(fid);
end

