% Function for getting the standard application data
%
% Calls:
% data = getAppData(h);
% data = getAppData(h, fieldname);
%
% h         = handle of the object
% fieldname = a fieldname of the application data
% data      = standard application data or just the data from the given fieldname
%
% Calls appData

% © Martijn Sparnaaij (2019)

function data = getAppData(h, varargin)
  
data = appData('get', h, varargin{:});

end  
%__________________________________________________________
