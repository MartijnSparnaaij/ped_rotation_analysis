% Function for setting and getting the standard application data
%
% Called by getAppData and setAppData

% © Martijn Sparnaaij (2019)

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
