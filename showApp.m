function showApp()
    if evalin('base', 'exist(''app'', ''var'')')
        try
            evalin('base', 'app.SqueakPeekStudioUIFigure.Visible = ''on'';');
            fprintf('App window restored.\n');
        catch ME
            warning(' Could not show app%s\n', ME.message);
            
        end
    else
        fprintf('No ''app'' found in base workspace.\n');
    end
end