function saveSettingsToFile(app, filepath)
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

