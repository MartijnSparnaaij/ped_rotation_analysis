% Assign the given variables to the base workspace
%
% assignInBase(varname_1, var_1, ..., varname_n, var_n)

function assignInBase(varargin)
  
if mod(nargin, 2)
  error('Number of inputs (%u) is not equal to 2 or a multiplicate of 2', nargin)
end

for ii = 1:2:nargin
  assignin('base', varargin{ii}, varargin{ii+1})  
end % for ii

end  
%__________________________________________________________
