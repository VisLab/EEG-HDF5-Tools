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
    entries: noisyParameters

###Methods
####entries
Returns a list of the entries available in the `Hdf5Structure` object.

    >>> np.entriess()
    [u'noisyParameters']

####get\_entry(entryname)
#####entryname: the name of the entry
Returns a dictionary with the entries from `entryname`

    >>> np.get_entry('version')
    {u'lineNoise': {u'tau': array([[ 100.]]), u'fScanBandWidth': array([[ 2.]]),
        u'Fs': array([[ 512.]]), u'fPassBand': array([[  45.], [ 256.]]),
        u'taperWindowStep': array([[ 1.]]), u'taperWindowSize': array([[ 4.]]),
        u'p': array([[ 0.01]]),
        u'tapers': array([[  4.41025331e-05,   4.72471906e-05,   5.05019946e-05, ...,}
    ...}

####get\_lazy\_entry(entryname)
#####entryname: the name of the entry
Returns a lazy dictionary with the entries from `entryname`

    >>> np.get_lazy_entry('noisyParameters')
    <HDF5 group "/noisyParameters" (6 members)>

you can then extract the needed value

    >>> noisy_pam = np.get_lazy_entry('noisyParameters')
    >>> noisy_pam.keys()
    [u'highPass', u'lineNoise', u'name', u'reference', u'resampling', u'version']
    >>> version = noisy_pam.get('version')
    >>> version.get('Resampling').value
    'v0.21'
