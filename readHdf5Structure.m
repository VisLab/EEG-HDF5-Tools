function hdf5Struct = readHdf5Structure(file)
fileId = H5F.open(file,'H5F_ACC_RDONLY','H5P_DEFAULT');
% Get root group
hdf5Path = '/';
childStructure = getGroupChildren(fileId, hdf5Path);
% Get top group
hdf5Path = [hdf5Path, childStructure.name];
childStructure = getGroupChildren(fileId, hdf5Path);
% Create empty fields
hdf5Struct = createEmptyStructFields({childStructure.name});
% Populate fields
hdf5Struct = readHdf5Data(fileId, hdf5Path, hdf5Struct, childStructure);
% Close everything
H5F.close(fileId);

    function parentStructure = readHdf5Data(fileId, hdf5Path, ...
            parentStructure, childStructure)
        for a = 1:length(childStructure);
            if strcmpi(childStructure(a).objectType, 'Group')
                grandChildStructure = getGroupChildren(fileId, ...
                    [hdf5Path, '/', childStructure(a).name]);
                parentStructure.(childStructure(a).name) = ...
                    createEmptyStructFields({grandChildStructure.name});
                parentStructure.(childStructure(a).name) = ...
                    readHdf5Data(fileId, ...
                    [hdf5Path, '/', childStructure(a).name], ....
                    parentStructure.(childStructure(a).name), ...
                    grandChildStructure);
            else
                parentStructure.(childStructure(a).name) = ...
                    readDataset(fileId, ...
                    [hdf5Path, '/', childStructure(a).name]);
            end
        end
        
    end

    function dataset = readDataset(fileId, datasetPath)
        datasetId = H5D.open(fileId, datasetPath);
        dataType = H5D.get_type(datasetId);
        dataset = H5D.read(datasetId);
        dataset = postProcessData(dataType, dataset);
        H5D.close(datasetId);
    end

    function dataset = postProcessData(dataType, dataset)
        switch (dataType)
            case H5ML.get_constant_value('H5T_STRING')
                dataset = dataset';
        end
    end

    function outputStructure = createEmptyStructFields(structureFields)
        for a = 1:length(structureFields)
            outputStructure.(structureFields{a}) = [];
        end
    end

    function childStructure = getGroupChildren(fileId, groupPath)
        groupId = H5G.open(fileId, groupPath);
        [~, ~, childStructure] =  ...
            H5L.iterate(groupId, 'H5_INDEX_NAME', 'H5_ITER_INC', 0, ...
            @findGroupChildren,[]);
        H5G.close(groupId);
    end

    function [status, iterationData] = findGroupChildren(groupId, ...
            childName, childStructure)
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
    end

end

