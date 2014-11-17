function iterationData = readHdf5Structure(file)
fileId = H5F.open(file,'H5F_ACC_RDONLY','H5P_DEFAULT');
groupId = H5G.open(fileId, '/noisyParameters');
[iterationStatus, iterationCount, iterationData] =  ...
    H5L.iterate(groupId, 'H5_INDEX_NAME', 'H5_ITER_INC', 0, ...
    @findGroupChildren,[]);
H5G.close(groupId);
H5F.close(fileId);

    function [status, opdata_out] = findGroupChildren(groupId, ...
            childName,childStructure)
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
        opdata_out = childStructure;
        status = 0;
    end

end

