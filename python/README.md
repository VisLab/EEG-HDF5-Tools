#hdf5structure

*hdf5Structure* is a Python module to read data created by MATLAB and EEGLAB.

##Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* [h5py](http://www.h5py.org/) (available via `pip`)
* [numpy](http://www.numpy.org/)

##Hdf5Structure(h5file)
#####hf5file: the path to a HDF5 file

    >>> import hdf5Structure
    >>> nd = hdf5Structure.Hdf5Structure('file.h5')
    >>> print nd
    file: file.h5
    entries: noiseDetection

###Methods
####entries
Returns a list of the entries available in the `Hdf5Structure` object.

    >>> nd.entries()
    [u'noiseDetection']

####get\_entry(entryname)
#####entryname: the name of the entry
Returns a dictionary with the entries from `entryname`

    >>> nd.get_entry('root')
    {u'lineNoise': {u'tau': array([[ 100.]]), u'fScanBandWidth': array([[ 2.]]),
        u'Fs': array([[ 512.]]), u'fPassBand': array([[  45.], [ 256.]]),
        u'taperWindowStep': array([[ 1.]]), u'taperWindowSize': array([[ 4.]]),
        u'p': array([[ 0.01]]),
        u'tapers': array([[  4.41025331e-05,   4.72471906e-05,   5.05019946e-05, ...,}
    ...}

####get\_lazy\_entry(entryname)
#####entryname: the name of the entry
Returns a `h5py.Group` or `h5py.Dataset` with the entries from `entryname`

    >>> nd.get_lazy_entry('root')
    <HDF5 group "/noiseDetection" (6 members)>

you can then extract the needed value

    >>> noise_det = nd.get_lazy_entry('root')
    >>> noise_det.keys()
    [u'highPass', u'lineNoise', u'name', u'reference', u'resampling', u'version']
    >>> version = noisy_det.get('version')
    >>> version.get('Resampling').value
    'v0.21'

####write\_dataset(path, data)
#####path: the path of the dataset to create
#####data: the data to write to the HDF5 file
Creates and writes a new dataset to the HDF5 file.

For example

    >>> sample = nd.write_dataset('root/sample', range(1, 1000))

will create a new dataset located at "root/sample" consisting of the
numbers 1 through 1000
