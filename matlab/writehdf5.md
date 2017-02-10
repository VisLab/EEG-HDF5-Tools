#writeHdf5Structure

*writeHdf5Structure* is a function that stores a MATLAB structure in a hdf5 file. 

## Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* [JSONlab](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)
* MATLAB 

## Functions and Methods
writeHdf5Structure(file, root, structure)

### Input
* `hdf5File`: The name of the HDF5 file to write the structure to.
* `group`: The name of the HDF5 group to write the structure data under. 
* `structure`: The structure array containing the data.

### Output

## Examples

Creates a HDF5 file 'noisyParameters.h5' and writes the contents of the structure EEG.etc.noiseDetection to dataset /noisyParameters.

`writehdf5('noisyParameters.h5', '/noisyParameters', EEG.etc.noiseDetection);`

## Notes
writeHdf5Structure stores the following structure field data types:
* `cellstr`
* `double`
* `single`
* `string`
* `structure` 
