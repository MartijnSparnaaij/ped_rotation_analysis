% Get the handle of the parent figure of the given handle
% The handle can be a uicontrol, an axes, a menu ect.
%
% Supports the new graphics system introduced in R2014b
%
% © Martijn Sparnaaij (2019)

function fig = hfigure(h)

figClassStr = 'matlab.ui.Figure';

while (~strcmpi(class(h), figClassStr) && ~strcmpi(class(h), 'double')) || ...
    (strcmpi(class(h), 'double') && ~strcmpi(get(h, 'type'), 'figure'))
  h = get(h, 'Parent');
end

fig = h;

end