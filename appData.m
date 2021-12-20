% Function for setting and getting the standard application data
%
% Called by getAppData and setAppData
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

function varargout = appData(action, varargin)

if nargout
  varargout = cell(1, nargout);
end

switch lower(action)
  case 'get'
    h = varargin{1};
    data = getappdata(h, appData('dataName'));
    if numel(varargin) == 2
      fldNms = varargin{2};
      if ~iscell(fldNms)
        fldNms = field2cell(fldNms);
      end
      try
        varargout{1} = getfield(data, fldNms{:});
      catch ME
        error('%s', ME.getReport)
      end
    else
      varargout{1} = data;
    end
  case 'set'
    h = varargin{1};
    value = varargin{2};
    if numel(varargin) == 3
      data = appData('get', h);
      fldNms = varargin{3};
      if ~iscell(fldNms)
        fldNms = field2cell(fldNms);
      end
      try
        data = setfield(data, fldNms{:}, value);
      catch ME
        error('%s', ME.getReport)
      end
    else
      data = value;
    end
    setappdata(h, appData('dataName'), data)
    varargout{1} = data;
  case 'dataname'
    varargout{1} = 'appData';
  otherwise
    error('Unknown action "%s"', action)
end

end
%__________________________________________________________
