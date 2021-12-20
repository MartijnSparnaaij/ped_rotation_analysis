% Get the handle of the parent figure of the given handle
% The handle can be a uicontrol, an axes, a menu ect.
%
% Supports the new graphics system introduced in R2014b
%
% Copyright (c) 2021 Martijn Sparnaaij
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

function fig = hfigure(h)

figClassStr = 'matlab.ui.Figure';

while (~strcmpi(class(h), figClassStr) && ~strcmpi(class(h), 'double')) || ...
    (strcmpi(class(h), 'double') && ~strcmpi(get(h, 'type'), 'figure'))
  h = get(h, 'Parent');
end

fig = h;

end