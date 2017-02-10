% Creates a HDF5 file and writes the contents of a structure to it.
%
% Usage:
% 
%   >> struct2h5(hdf5File, group, structure)
%
% Input:
%
%   hdf5File        
%                   The name of the HDF5 file to write the structure to.
%
%   group         
%                   The name of the HDF5 group to write the structure data
%                   under. 
%
%   structure       
%                   The structure array containing the data.
%
% Examples:
%
%   Creates a HDF5 file 'noisyParameters.h5' and writes the contents of the
%   structure EEG.etc.noiseDetection to dataset /noisyParameters.
%
%   struct2h5('noisyParameters.h5', '/noisyParameters', ...
%   EEG.etc.noiseDetection);
%
% Notes:
%
%   writeHdf5Structure stores the following field data types:
%
%   cellstr
%   double
%   single
%   string
%   structure

function struct2h5(hdf5File, group, structure)
fileId = H5F.create(hdf5File, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', ...
    'H5P_DEFAULT');
writeGroup(fileId, ['/', strrep(group, '/', '')]);
addDataset(fileId, ['/', strrep(group, '/', '')], structure);
H5F.close(fileId);

    function addDataset(fileId, path, structure)
        % Writes the structure fields to the file under the specified path
        fieldNames = fieldnames(structure);
        for a = 1:length(fieldNames)
            switch class(structure.(fieldNames{a}))
                case 'cellstr'
                    writeCellStr(fileId, [path, '/', fieldNames{a}], ...
                        {structure.(fieldNames{a})})
                case 'char'
                    writeStr(fileId, [path, '/', fieldNames{a}], ...
                        structure.(fieldNames{a}));
                case 'double'
                    writeDouble(fileId, ...
                        [path, '/', fieldNames{a}], ...
                        structure.(fieldNames{a}));
                case 'logical'  
                    writeDouble(fileId, ...
                        [path, '/', fieldNames{a}], ...
                        structure.(fieldNames{a}));
                case 'single'
                    writeSingle(fileId, ...
                        [path, '/', fieldNames{a}], ...
                        structure.(fieldNames{a}));
                case 'struct'
                    if isscalar(structure.(fieldNames{a}))
                        writeGroup(fileId, [path, '/', fieldNames{a}]);
                        addDataset(fileId, [path, '/', fieldNames{a}], ...
                            structure.(fieldNames{a}));
                    elseif ~isscalar(structure.(fieldNames{a})) && ...
                            ~isNestedStructure(structure.(fieldNames{a}))
                        writeStructure(fileId, ...
                            [path, '/', fieldNames{a}], ...
                            structure.(fieldNames{a}));
                    end
            end
        end
    end % addDataset

    function nestedStructure = isNestedStructure(structure)
        % Checks to see if a structure contains a nested field
        nestedStructure = false;
        fieldNames = fieldnames(structure);
        for a = 1:length(structure)           
            for b = 1:length(fieldNames)
                if isstruct(structure(a).(fieldNames{b}))
                    nestedStructure = true;
                end
            end
        end
    end % isNestedStructure

end % struct2h5