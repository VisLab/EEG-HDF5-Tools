% Creates a HDF5 file and writes the contents of a structure to it.
%
% Usage:
% 
%   >> struct2h5(fid, group, structure)
%
% Input:
%
%   fid        
%                   The name of the HDF5 file to write the data to.
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

function struct2h5(fid, h5data, groupPath)
p = parseArguments(fid, h5data, groupPath);

% Initialize fileId
fileId = -1;
% Flag for creation of initial hearichical strucutre
% flag_init = false;
try
    %fileId = getFileId(p.hdf5File);
    fileId = fid;
    formattedPath = formatGroupPath(p.groupPath);
    if ~strcmpi(formattedPath, '/')
        writeGroup(fileId, formattedPath);
    end
    if isstruct(h5data)
        addStructureDatasets(fileId, formattedPath, h5data);
    else
        addDataset(fileId, formattedPath, inputname(2), h5data);
    end
    % We close the file ourselves
    % H5F.close(fileId);
catch ME
    if fileId ~= -1
        H5F.close(fileId);
    end
    rethrow(ME);
end

    function fileId = getFileId(hdf5File)
        % Get the file id of the HDF5 file
         if exist(hdf5File, 'file') == 2
            fileId = H5F.open(hdf5File, 'H5F_ACC_RDWR', ...
                'H5P_DEFAULT');    
        else
            fileId = H5F.create(hdf5File, 'H5F_ACC_TRUNC', ...
                'H5P_DEFAULT', 'H5P_DEFAULT');
        end   
    end % getFileId

    function formattedPath = formatGroupPath(groupPath)
        % Format the object path 
        formattedPath = strtrim(groupPath);
        if isempty(formattedPath)
           fprintf('Path is empty ... using root path\n'); 
           formattedPath = '/';
        elseif ~isequal(formattedPath,'/') && formattedPath(end) == '/';
            formattedPath = formattedPath(1:end-1);
        end
    end % formatGroupPath

    function addDataset(fileId, groupPath, datasetName, dataset)
        % Writes the dataset to the file under the specified path
        switch class(dataset)
%             case 'cellstr'
%                 writeCellStr(fileId, [groupPath, '/', datasetName], ...
%                     {dataset})
            case 'char'
                writeStr(fileId, [groupPath, '/', datasetName], dataset);
            case 'double'
                writeDouble(fileId, [groupPath, '/', datasetName], ...
                    dataset);
            case 'logical'  
                writeDouble(fileId, [groupPath, '/', datasetName], ...
                    dataset);
            case 'single'
                writeSingle(fileId, [groupPath, '/', datasetName], ...
                    dataset);
            case 'struct'
                if isscalar(dataset)
                    writeGroup(fileId, ...
                        [groupPath, '/', datasetName]);
                    addStructureDatasets(fileId, ...
                        [groupPath, '/', datasetName], dataset);
                elseif ~isscalar(dataset) && ...
                        ~isNestedStructure(dataset)
                    writeStructure(fileId, ...
                        [groupPath, '/', datasetName], dataset);
                end
            case 'cell'
                writeCell(fileId,...
                    [groupPath, '/', datasetName], dataset);
        end
    end % addDataset

    function addStructureDatasets(fileId, groupPath, structure)
        % Writes the structure fields to the file under the specified path
        fieldNames = fieldnames(structure);
        for a = 1:length(fieldNames)
            addDataset(fileId, groupPath, fieldNames{a}, ...
                structure.(fieldNames{a}));
        end
    end % addStructureDatasets

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

    function p = parseArguments(fid, h5data, groupPath)
        % Parses the arguements passed in and returns the results
        p = inputParser();
        p.addRequired('fid');
        p.addRequired('h5data');
        p.addOptional('groupPath', '/', @(x) isempty(x) || ischar(x));
        p.parse(fid, h5data, groupPath);
        p = p.Results;
    end % parseArguments

end % struct2h5