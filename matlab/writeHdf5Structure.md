#writeHdf5Structure

*writeHdf5Structure* is a function that stores a MATLAB structure in a hdf5 file. 

## Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* MATLAB 

## Functions and Methods
writeHdf5Structure(file, root, structure)

### Input
* `file`: the name of the hdf5 file to write the structure to 
* `root`: the root path in the hdf5 file to store the structure in 
* `structure`: the structure variable containing the data

### Output

## Examples

writeHdf5Structure('noisyParameters.h5', '/noisyParameters', EEG.etc.noiseDetection);

## Notes
writeHdf5Structure stores the following structure field data types:
* `cellstr`
* `double`
* `single`
* `string`
* `structure` 
