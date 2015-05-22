#EEG-HDF5

*EEG-HDF5* is a package to read data created by MATLAB.

##Dependencies

* [HDF5](http://www.hdfgroup.org/HDF5/)
* [Bioconductor](http://www.bioconductor.org/)
* [rhdf5](http://www.bioconductor.org/packages/release/bioc/html/rhdf5.html)

##Objects
###hdf5Structure
`hdf5Structure` is the only class exposed by EEG. Its structure is dynamically
created according to the structure of the HDF5 file that was used to create it.

`hdf5Structure` objects shouldn't be created with R's built-in `new` method,
instead use the `Hdf5Structure` function.

##Functions and Methods
###Hdf5Structure('file.h5', root="/")
####creates a `hdf5Structure` object

`Hdf5Structure` is the main function that is made available through EEG.
The main parameter is a path to a HDF5 file.

	> nd <- Hdf5Structure(file)
	> nd
	file: file.h5
	entries: root

`Hdf5Structure` dynamically generates a new instance of `hdf5Structure` whose
fields correspond to the top-level entries of the HDF5 file. In the above
example, `nd` was defined according to the file that was passed to
`Hdf5Structure`.

If everything in the HDF5 file is contained in one main group, you can specify that group as the root to improve performance.

For example, if the structure of the HDF5 file was

```
/
+--- main
   +--- aDataset
   +--- anotherDataset
   +--- aGroup
		+--- ...
```

Specifying the root as "main" will be better than opening the file at "/"

	> nd <- Hdf5Structure(file, root="/main")

###entries(hdf5Structure)
####shows the entries in the `hdf5Structure` object.
`entries` prints the entries that are in the `hdf5Structure` object.

	> entries(nd)
	[1] "root"

###get.entry(hdf5Structure, entry)
####returns a entry
`get.entry` is used to get an entry from a `hdf5Structure` object. If it is
necessary, it will first evaluate the entry.

	> nd <- get.entry(nd, "root")
	> nd$highPass$highPassFilterCommand
	[1] "EEG1 = pop_eegfiltnew(EEG1, [], 1, 3300, true, [], 0);"

The above lines roughly corresponds to

	nd.highPass.highPassFilterCommand

in MATLAB.

###write.dataset(hdf5Structure, location, object)
####writes a new entry in the HDF5 file
`write.dataset` is used to update the existing HDF5 file with a new dataset. The new
entry, the `object` parameter, will be written at `location`.

For example

	> write.dataset(nd, "root/sample", 1:1000)

will create a new dataset located at "noiseDetection/sample" consisting of the
numbers 1 through 1000.
