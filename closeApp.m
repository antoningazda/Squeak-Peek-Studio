% closeApp.m

if evalin('base', 'exist(''app'', ''var'')')
    try
        evalin('base', 'delete(app); clear app;');
        fprintf('Closed and cleared ''app'' from base workspace.\n');
    catch ME
        warning('Could not delete app: %s\n', ME.message);
    end
else
    fprintf('No ''app'' found in base workspace.\n');
end