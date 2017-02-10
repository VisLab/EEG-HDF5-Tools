The EEG-HEDF5-Tools matlab package provides functions for converting EEG data structures into HDF5 format and vice versa. The *h52struct* function reads a HDF5 file and loads it in a structure. The *struct2h5* function stores a structure in a hdf5 file. 

## Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* [JSONlab](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)
* MATLAB 

## Writing Examples

Creates a HDF5 file 'noisyParameters.h5' and writes the contents of the structure EEG.etc.noiseDetection to dataset /noisyParameters.

`struct2h5('noisyParameters.h5', '/noisyParameters', EEG.etc.noiseDetection);`

## Reading Examples

Reads a HDF5 file 'noisyParameters.h5' and loads it into a structure 'hdf5Data'.

`hdf5Data = h52struct('noisyParameters.h5');`

Reads a HDF5 file 'CT2WS_fold1_results.hdf5' and read dataset '/optimizer_weights/param_1'.

`hdf5Data = h52struct('CT2WS_fold1_results.hdf5', '/optimizer_weights/param_1');`

## Notes
writeHdf5Structure stores the following structure field data types:
* `cellstr`
* `double`
* `single`
* `string`
* `structure` 
