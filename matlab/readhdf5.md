#readHdf5Structure

*readHdf5Structure* is a function that reads a HDF5 file and loads it in a structure. 

## Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* [JSONlab](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)
* MATLAB 

## Functions and Methods
hdf5Struct = readHdf5Structure(file)

### Input
* `hdf5File`: The name of the HDF5 file to create the structure from.
* `objectPath`: The path to a HDF5 dataset or a group. If the path is a group then its assoicated datasets are retrieved.

### Output
* `hdf5Data`: The contents retrieved from the HDF5 file

## Examples

Reads a HDF5 file 'noisyParameters.h5' and loads it into a structure 'hdf5Data'.

hdf5Data = readHdf5Structure('noisyParameters.h5');

Reads a HDF5 file 'CT2WS_fold1_results.hdf5' and read dataset '/optimizer_weights/param_1'.

hdf5Data = readHdf5Structure('CT2WS_fold1_results.hdf5', '/optimizer_weights/param_1');


