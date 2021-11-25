% Function for setting the standard application data
%
% Call:
% data = setAppData(h, data);
%
% h    = handle of the object
% data = application data
%
% Calls appData
%
% © Martijn Sparnaaij (2019)

function varargout = setAppData(h, data, varargin)

if nargout
  varargout = cell(1, nargout);
  data = appData('set', h, data, varargin{:});
  varargout{1} = data;
else
  appData('set', h, data, varargin{:});
end

end
%__________________________________________________________
