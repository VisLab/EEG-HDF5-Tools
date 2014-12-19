#EEG-HDF5

*EEG-HDF5* is a package to read data from MATLAB. Some of the features include

* Dynamic class definitions
* Lazy evaluation

##Dependencies

* [HDF5](http://www.hdfgroup.org/HDF5/)
* [Bioconductor](http://www.bioconductor.org/)
* [rhdf5](http://www.bioconductor.org/packages/release/bioc/html/rhdf5.html)

##Objects
###hdf5Structure
`hdf5Structure` is the only class exposed by EEG. Its structure is dynamically
created according to the structure of the HDF5 file that was used to create it.
However the following attributes are always available:

  * `name`: the name of the dataset
  * `reader`: the structure of the HDF5 file

`hdf5Structure` objects shouldn't be created with R's built-in `new` method,
instead use the `Hdf5Structure` function.

##Functions and Methods
###Hdf5Structure('file.h5')
####creates a `hdf5Structure` object

`Hdf5Structure` is the main function that is made available through EEG.
The only parameter is a path to a HDF5 file.

	> np <- Hdf5Structure(file)
	> np
	file: file.h5
	groups: highPass, lineNoise, reference, resampling, version
	
`Hdf5Structure` dynamically generates a new instance of `hdf5Structure` whose
fields correspond to the top-level groups of the HDF5 file. In the above
example, `np` was defined according to the file that was passed to
`Hdf5Structure`.

**An important note:** `reader` and `name` are eagerly evaluated upon creation.

###groups(hdf5Structure)
####shows the groups in the `hdf5Structure` object.
`groups` prints the groups that are in the `hdf5Structure` object.

	> groups(np)
	[1] "highPass"   "lineNoise"  "reference"  "resampling" "version"   
	
###get.group(hdf5Structure, group)
####returns a group
`get.group` is used to get a group from a `noisyParameter` object. If it is
necessary, it will first evaluate the group.

	> get.group(np, "highPass")$highPassFilterCommand
	[1] "EEG1 = pop_eegfiltnew(EEG1, [], 1, 3300, true, [], 0);"
	
The above line roughly corresponds to
	
	np.highPass.highPassFilterCommand
	
in MATLAB.