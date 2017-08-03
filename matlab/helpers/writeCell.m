function writeCell(fileId, dataset, value)
% Writes a cell dataset to the specified HDF5 file.
%
%   >> writeCell(fileId, dataset, value)
%
% Input:
%
%   fileId            
%                     The file id.
%
%   dataset           
%                     The path of the dataset.
%
%   value             
%                     The value of the dataset.
%

% Need to pad the array so that every entry has the same size
% Not necessary for chars
if isa(value{1}, 'double') 
    lens = cellfun(@(e) length(reshape(e, [], 1)), value);
    limLen = max(lens);
    valueIn = cellfun(@(e) padarray(e, [limLen - length(reshape(e, [], 1)), 0], ...
        0, 'post'), value, 'UniformOutput', false);
    
    % Get back the file name, this allows to use high level fun
%     fname = H5F.get_name(fileId);
%     hdf5write(fname, dataset, value, 'WriteMode', 'append');

    % Transpose and convert into matrix
    valueIn = cell2mat(reshape(valueIn, [1, length(valueIn)]));
    
    writeDouble(fileId, dataset, ...
        valueIn);
    
elseif isa(value{1}, 'char')
    % Stick to low level functions
    writeCellStr(fileId, dataset, value)
end



% fileType = H5T.copy('H5T_FORTRAN_S1');
% H5T.set_size(fileType, 'H5T_VARIABLE');
% memType = H5T.copy('H5T_C_S1');
% H5T.set_size(memType, 'H5T_VARIABLE');
% dims = size(value);
% flippedDims = fliplr(dims);
% spaceId = H5S.create_simple(ndims(value),flippedDims, []);
% datasetId = H5D.create (fileId, dataset, fileType, spaceId, 'H5P_DEFAULT');
% H5D.write(datasetId, memType, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', value);
% H5D.close(datasetId);
% H5S.close(spaceId);
end