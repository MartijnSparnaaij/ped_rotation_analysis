% Function to convert a structure field name to a cell
%
% e.g. field.subfield.a -> {field, subfield, a}
%
% © Martijn Sparnaaij (2019)

function fieldNmC = field2cell(fieldNm)
 
if verLessThan('Matlab', '8.2')
  C = textscan(fieldNm, '%s', 'Delimiter', '.');
  fieldNmC = C{1};
else
  fieldNmC = strsplit(fieldNm, '.');
end
fieldNmC(cellfun(@isempty,fieldNmC)) = [];
 
end  
%__________________________________________________________
