function hideApp()
    if evalin('base', 'exist(''app'', ''var'')')
        try
            evalin('base', 'app.SqueakPeekStudioUIFigure.Visible = ''off'';');
            fprintf('App hidden (window invisible, still alive).\n');
        catch ME
            warning('Could not hide app: %s\n', ME.message);
        end
    else
        fprintf('No ''app'' found to hide.\n');
    end
end