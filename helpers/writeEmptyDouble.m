function writeEmptyDouble(fileId, dataset)
% Writes a empty double precision dataset to the specified HDF5 file
%
% writeEmptyDouble(fileId, dataset, value)
%
% Input:
%   fileId            The file id 
%   dataset           The path of the dataset 
%

valueType = H5T.copy('H5T_NATIVE_DOUBLE');
spaceId = H5S.create('H5S_NULL');
datasetId = H5D.create(fileId, dataset, valueType, spaceId, ...
    'H5P_DEFAULT');
H5D.close(datasetId);
H5S.close(spaceId);

end % writeEmptyDouble

