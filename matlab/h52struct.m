% Reads in a HDF5 file and loads its data into a structure. A path can
% optionally be specified to retrieve a particular group or a dataset.
% If a group path is specified then only that group and its associated
% datasets are retrieved. Group and dataset attributes are stored in
% the .attributes field.
%
% Usage:
%
%   >> hdf5Data = h52struct(hdf5File)
%
%
%   >> hdf5Data = h52struct(hdf5File, groupPath)
%
% Input:
%
%   hdf5File
%                   The name of the HDF5 file to create the structure from.
%
%   Optional:
%
%   objectPath
%                   The path to a HDF5 dataset or a group. If the path is
%                   a group then its assoicated datasets are retrieved. 
%
% Output:
%
%   hdf5Data
%                   The contents retrieved from the HDF5 file.
%
% Examples:
%
%   Reads a HDF5 file 'noisyParameters.h5' and loads it into a structure
%   'hdf5Data'.
%
%   hdf5Data = h52struct('noisyParameters.h5');
%
%   Reads a HDF5 file 'CT2WS_fold1_results.hdf5' and read dataset 
%   '/optimizer_weights/param_1'.
%
%   hdf5Data = h52struct('CT2WS_fold1_results.hdf5', 
%   '/optimizer_weights/param_1');

function hdf5Data = h52struct(hdf5File, varargin)
p = parseArguments(hdf5File, varargin{:});
fileId = -1;
try
    fileId = H5F.open(hdf5File,'H5F_ACC_RDONLY','H5P_DEFAULT');
    formattedPath = formatObjectPath(p.objectPath);
    hdf5Data = readData(fileId, formattedPath);
    H5F.close(fileId);
catch ME
    if fileId ~= -1
        H5F.close(fileId);
    end
    rethrow(ME);
end

    function formattedPath = formatObjectPath(objectPath)
        % Format the object path 
        formattedPath = strtrim(objectPath);
        if isempty(formattedPath)
           fprintf('Path is empty ... using root path\n'); 
           formattedPath = '/';
        elseif ~isequal(formattedPath,'/') && formattedPath(end) == '/';
            formattedPath = formattedPath(1:end-1);
        end        
    end % formatObjectPath

    function hdf5Data = readData(fileId, rootPath)
        % Read the data associated with the HDF5 file path
        objectId = H5O.open(fileId, rootPath, 'H5P_DEFAULT');
        objectInfo = H5O.get_info(objectId);
        switch (objectInfo.type)
            case H5ML.get_constant_value('H5G_GROUP')
                hdf5Data = readGroup(fileId, rootPath, [], []);
            case H5ML.get_constant_value('H5G_DATASET')
                hdf5Data = readDataset(fileId, rootPath);
        end
    end % readData

    function [status, iterationData] = addDatasetToStructure(groupId, ...
            childName, childStructure)
        % Adds dataset information to a structure
        index = length(childStructure);
        childStructure(index + 1).name = childName;
        objectId = H5O.open(groupId, childName, 'H5P_DEFAULT');
        objectInfo = H5O.get_info(objectId);
        switch (objectInfo.type)
            case H5ML.get_constant_value('H5G_GROUP')
                childStructure(index + 1).objectType = 'Group';
            case H5ML.get_constant_value('H5G_DATASET')
                childStructure(index + 1).objectType = 'Dataset';
        end
        iterationData = childStructure;
        status = 0;
        H5O.close(objectId);
    end % addDatasetToStructure

    function [status, iterationData] = addAttributeToStructure(groupId, ...
            attName, ~, attStructure)
        % Adds dataset information to a structure
        status = 0;
        attributeValue = readAttribute(groupId, attName);
        attStructure.(attName) = attributeValue;
        iterationData = attStructure;
    end % addDatasetToStructure

    function outputStructure = createEmptyStructureFields(structureFields)
        % Creates empty fields in a structure array
        for a = 1:length(structureFields)
            outputStructure.(structureFields{a}) = [];
        end
    end % createEmptyStructFields

    function childStructure = getGroupDatasets(fileId, groupPath)
        % Gets all datasets of a group
        groupId = H5G.open(fileId, groupPath);
        [~, ~, childStructure] =  ...
            H5L.iterate(groupId, 'H5_INDEX_NAME', 'H5_ITER_INC', 0, ...
            @addDatasetToStructure,[]);
        H5G.close(groupId);
    end % getGroupDatasets

    function attStructure = getGroupAttributes(fileId, groupPath)
        % Gets all attributes in group
        groupId = H5G.open(fileId, groupPath);
        [~, ~, attStructure] =  ...
            H5A.iterate(groupId, 'H5_INDEX_NAME', 'H5_ITER_INC', 0, ...
            @addAttributeToStructure, []);
        H5G.close(groupId);
    end % getGroupAttributes

    function dataset = postProcessDataset(dataset, datasetId, ...
            isStructField)
        % Processes the dataset
        if isstruct(dataset)
            dataset = struct2StructArray(dataset);
        elseif ischar(dataset)
            ndim = numel(size(dataset));
            dataset = permute(dataset,ndim:-1:1);
            if ndim > 2
                dataset = dataset';
            end
        elseif isnan(dataset)
            dims = [0, 0];
            if ~isStructField
                dims = readAttribute(datasetId, 'dims');
            end
            switch class(dataset)
                case 'single'
                    dataset = single.empty(dims);
                case 'double'
                    dataset = double.empty(dims);
            end
        elseif isscalar(dataset) && isequal('double',class(dataset)) ...
                && ~isStructField && (dataset == 0 || dataset == 1)
            datasetIsLogical = readAttribute(datasetId, 'islogical')';
            if strcmpi('true', datasetIsLogical)
                dataset = logical(dataset);
            end
        end
    end % postProcessDataset

    function attributeValue = readAttribute(datasetId, attribute)
        % Reads a attribute
        attributeId = H5A.open(datasetId, attribute);
        attributeValue = H5A.read(attributeId);
        type_id = H5A.get_type(attributeId);
        class_id = H5T.get_class(type_id);
        if iscell(attributeValue) && length(attributeValue) == 1
            attributeValue = convertJSON(attributeValue{1});
        elseif class_id == H5ML.get_constant_value('H5T_STRING')
            ndim = numel(size(attributeValue));
            attributeValue = permute(attributeValue,ndim:-1:1);
            if ndim > 2
                attributeValue = attributeValue';
            end
        end
    end % readAttribute

    function json = convertJSON(attValue)
        % Checks to see if the attribute value is a JSON string and if so
        % converts it into structure array
        json = attValue;
        trimStr = strtrim(attValue);
        if trimStr(1) == '{' && trimStr(end) == '}'
            json = loadjson(attValue);
        end
    end % convertJSON

    function dataset = readDataset(fileId, datasetPath)
        % Reads a dataset
        fprintf('Retrieving Dataset ''%s''...\n', datasetPath);
        datasetId = H5D.open(fileId, datasetPath);
        dataset = H5D.read(datasetId);
        dataset = postProcessDataset(dataset, datasetId, false);
        H5D.close(datasetId);
    end % readDataset

    function parentStructure = readGroup(fileId, hdf5Path, ...
            parentStructure, childStructure)
        % Reads hdf5 groups and datasets
        fprintf('Retrieving Group ''%s''...\n', hdf5Path);
        attStruct = getGroupAttributes(fileId, hdf5Path);
        if ~isempty(attStruct)
            parentStructure.attributes = attStruct;
        end
        if isempty(childStructure)
            childStructure = getGroupDatasets(fileId, hdf5Path);
        end
        % Handle when / is passed in
        if hdf5Path == '/'
           hdf5Path = ''; 
        end
        for a = 1:length(childStructure);
            if strcmpi(childStructure(a).objectType, 'Group')
                grandChildStructure = getGroupDatasets(fileId, ...
                    [hdf5Path, '/', childStructure(a).name]);
                if ~isempty(grandChildStructure)
                    parentStructure.(childStructure(a).name) = ...
                        createEmptyStructureFields({grandChildStructure.name});
                    parentStructure.(childStructure(a).name) = ...
                        readGroup(fileId, ...
                        [hdf5Path, '/', childStructure(a).name], ....
                        parentStructure.(childStructure(a).name), ...
                        grandChildStructure);
                else
                    parentStructure.(childStructure(a).name) = [];
                end
            else
                parentStructure.(childStructure(a).name) = ...
                    readDataset(fileId, ...
                    [hdf5Path, '/', childStructure(a).name]);
            end
        end
    end % readHdf5Data

    function structureArray = struct2StructArray(structure)
        % Converts a scalar structure to a structure array
        fieldNames = fieldnames(structure);
        structValues = cell(length(fieldNames), 1, ...
            length(structure.(fieldNames{1})));
        for a = 1:length(structure.(fieldNames{1}))
            for b = 1:length(fieldNames)
                if iscellstr(structure.(fieldNames{b}))
                    structValues{b, 1, a} = ...
                        structure.(fieldNames{b}){a};
                else
                    structValues{b, 1, a} = ...
                        postProcessDataset(...
                        structure.(fieldNames{b})(a), [], true);
                end
            end
        end
        structureArray = cell2struct(structValues,fieldNames,1);
    end % struct2StructArray

    function p = parseArguments(hdf5File, varargin)
        % Parses the arguements passed in and returns the results
        p = inputParser();
        p.addRequired('hdf5File', @(x) (~isempty(x) && ischar(x)));
        p.addOptional('objectPath', '/', @ischar);
        p.parse(hdf5File, varargin{:});
        p = p.Results;
    end % parseArguments

end % h52struct