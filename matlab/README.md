*readHdf5Structure* is a function that reads a HDF5 file and loads it in a structure. 
*writeHdf5Structure* is a function that stores a MATLAB structure in a hdf5 file. 

## Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* [JSONlab](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)
* MATLAB 

## Writing Examples

Creates a HDF5 file 'noisyParameters.h5' and writes the contents of the structure EEG.etc.noiseDetection to dataset /noisyParameters.

`writehdf5('noisyParameters.h5', '/noisyParameters', EEG.etc.noiseDetection);`

## Reading Examples

Reads a HDF5 file 'noisyParameters.h5' and loads it into a structure 'hdf5Data'.

`hdf5Data = readHdf5Structure('noisyParameters.h5');`

Reads a HDF5 file 'CT2WS_fold1_results.hdf5' and read dataset '/optimizer_weights/param_1'.

`hdf5Data = readHdf5Structure('CT2WS_fold1_results.hdf5', '/optimizer_weights/param_1');`

## Notes
writeHdf5Structure stores the following structure field data types:
* `cellstr`
* `double`
* `single`
* `string`
* `structure` 
