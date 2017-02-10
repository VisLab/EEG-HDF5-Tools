#readHdf5Structure

*readHdf5Structure* is a function that reads a HDF5 file and loads it in a structure. 

## Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* MATLAB 
* JSONlab

## Functions and Methods
hdf5Struct = readHdf5Structure(file)

### Input
* `hdf5File`: The name of the HDF5 file to read the structure from

### Output
* `hdf5Struct`: A structure containing the contents from the HDF5 file

## Examples

Reads a HDF5 file 'noisyParameters.h5' and loads it into a structure hdf5Struct.

hdf5Struct = readHdf5Structure('noisyParameters.h5');

## Notes
