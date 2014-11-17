function writeEmptyStr(fileId, dataset)
% Writes a empty string dataset to the specified HDF5 file
%
% writeEmptyStr(fileId, dataset, value)
%
% Input:
%   fileId            The file id
%   dataset           The path of the dataset
%

valueType = H5T.copy('H5T_FORTRAN_S1');
spaceId = H5S.create('H5S_NULL');
datasetId = H5D.create(fileId, dataset, valueType, spaceId, ...
    'H5P_DEFAULT');
H5D.close(datasetId);
H5S.close(spaceId);

end % writeEmptyStr

