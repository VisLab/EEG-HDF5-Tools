#hdf5structure

*hdf5Structure* is a Python module to read data created by MATLAB and EEGLAB.

##Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* [h5py](http://www.h5py.org/) (available via `pip`)
* [numpy](http://www.numpy.org/)

##Hdf5Structure(h5file)
#####hf5file: the path to a HDF5 file

    >>> import hdf5Structure
    >>> np = hdf5Structure.Hdf5Structure('file.h5')
    >>> print np
    file: file.h5
    groups: highPass, lineNoise, name, reference, resampling, version

###Methods
####groups
Returns a list of the groups available in the `Hdf5Structure` object.

    >>> np.groups()
    [u'highPass', u'lineNoise', u'name', u'reference', u'resampling', u'version']

####get\_group(groupname)
#####groupname: the name of the group
Returns a dictionary with the datasets from `groupname`

    >>> np.get_group('version')
    {u'HighPass': 'v0.21',
     u'Interpolation': 'v0.21',
     u'LineNoise': 'v0.21',
     u'Reference': 'v0.21',
     u'Resampling': 'v0.21'}

####get\_lazy\_group(groupname)
#####groupname: the name of the group
Returns a lazy dictionary with the datasets from `groupname`

    >>> np.get_lazy_group('version')
    {u'HighPass': <HDF5 dataset "HighPass": shape (), type "|S5">,
     u'Interpolation': <HDF5 dataset "Interpolation": shape (), type "|S5">,
     u'LineNoise': <HDF5 dataset "LineNoise": shape (), type "|S5">,
     u'Reference': <HDF5 dataset "Reference": shape (), type "|S5">,
     u'Resampling': <HDF5 dataset "Resampling": shape (), type "|S5">}

you can then extract the needed value

    >>> version = np.get_lazy_group('version')
    >>> version.keys()
    [u'Resampling', u'Interpolation', u'LineNoise', u'Reference', u'HighPass']
    >>> version['Resamlping'].value
    'v0.21'
