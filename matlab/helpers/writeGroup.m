% Writes a group to the specified HDF5 file.
%
%   >> writeGroup(fileId, group)
%
% Input:
%
%   fileId            
%                     The file id. 
%   group             
%                     The path of the group. 
%

function writeGroup(fileId, group)

% If doing initial run, we want to create hierarchical structure which
% apparently can be done only level-by-level

% if flag_init
%     % Split on delimiter
%     groups = strsplit(group, '/');
%     % Remove empty cells
%     groups = groups(~strcmp('', groups));
%     % Create new dataset
%     groupId = cell(size(groups));
%     groupName = [];
% 
%     for i = 1 : length(groups)
%         groupName = [groupName, '/', groups{i}];
%         groupId{i} = H5G.create(fileId, groupName, 'H5P_DEFAULT', 'H5P_DEFAULT', ...
%         'H5P_DEFAULT');
%     end
% 
%     % Close all opened groups
%     for k = 1 : length(groupId)  
%         H5G.close(groupId{k});
%     end
    
% else 
    % otherwise, if adding just one level, can do it the old way
    % there may be a way how to interrogate the file for existing groups.
    groupId = H5G.create(fileId, group, 'H5P_DEFAULT', 'H5P_DEFAULT', ...
        'H5P_DEFAULT');
    H5G.close(groupId);
    
% end

end % writeGroup