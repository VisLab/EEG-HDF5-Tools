<!--- Written in GitHub flavored Markdown -->
#HDF5 Overview
HDF5 is "a versatile data format that can represent very complex data objects"
and metadata in a portable way. While the HDF group provides programming tools
to interact with HDF5 files, the API is complex and large. To help mitigate this
problem, `hdf5_struct` simplifies the C API and allows easier access to HDF5
files.

HDF5 files mimic the structure of a file system. There is a root directory and
the root directory can contain sub-directories or files. In HDF5 files, groups
represent directories and datasets represent files.

At a very basic level, the use of `hdf5_struct` can be broken down into steps:

1. Create a variable to represent the overall HDF5 file
2. Extract an entry from the file
3. Operate on the entry

An entry in a HDF5 file can be either a group or a dataset, if it's a dataset
you can read the data and query various features of it (i.e, the dimensions)

If the entry is a group, you can extract more entries from it and repeat the
process.

#hdf5_struct
`hdf5_struct` allows easier access to HDF5 files using C. It provides functions
to create variables that represent the file and access datasets or groups in a
file

##Dependencies
* [HDF5](http://www.hdfgroup.org/HDF5/)
* While it's _not_ required, it is recommended to use
[`h5cc`](http://www.hdfgroup.org/HDF5/Tutor/compile.html) to compile your
programs.

##Structs
There are two main structs
* `hdf5_struct_t`
* `hdf5_entry_t`.

`hdf5_struct_t` is used to represent the structure of the overall file.

`hdf5_entry_t` objects represent specific datasets or groups in an HDF5 file. If
a `hdf5_entry_t` object represents a group, it contains an array of children
`hdf5_entry_t` objects, if it is a dataset, it contains the corresponding data.

Here's a simple example of how `hdf5_struct_t` objects and `hdf5_entry_t`
objects are related.

```
sample.h5          // hdf5_struct_t: represents the entire file
+---groupA         // hdf5_entry_t: represents groupA; contains data
+---groupB         // hdf5_entry_t: represents groupB; contains groupC
    +---dataC      // hdf5_entry_t: represents groupB/dataC; contains data
...
```

##Functions
[Creation and Deletion](#creation)

[Accessing Entries](#accessing)

[Accessing Data from Datasets](#data)

[Writing Data](#writing)

[Printing](#printing)

##<a name="creation"></a>Creation and Deletion
###new_hdf5_struct(char \*path)
Creates a new `hdf5_struct_t` object from the file path `path`. If any errors
occur `NULL` is returned. Free the memory associated with the pointer returned
by this function with `free_hdf5_struct`.

####Example for `new_hdf5_struct`
```c
hdf5_struct_t hdf5;
if ((hdf5 = new_hdf5_struct("/path/to/file.h5")) == NULL) {
    printf("Unable to create hdf5_struct");
    return;
}
```

###free_hdf5_struct(hdf5_struct_t hdf5)
Frees the memory associated with a `hdf5_entry_t` object created by
`new_hdf5_struct`.

####Example for `free_hdf5_struct`
```c
free_hdf5_struct(hdf5);
```

##<a name="accessing"></a>Accessing Entries
**A note about accessing entries:** To improve performance, when a group is
evaluated, only the group itself is read, this means that the children of that
group will remain unevaluated until you call `get_entry` or `get_subentry` on
that child entry.

If you have any intention to use the entry in some way, it is recommended to
access it using the `get_entry` or `get_subentry` functions.

For example, given this structure

```
sample.h5
+---groupA
+---groupB
    +---dataC
...
```

when `get_entry(sample, "groupB");` is called, only the information about
`groupB` will be evaluated, the only information known about `dataC` will be
it's name. Calling `get_subentry(groupB, "dataC")` will evaluate `dataC` and
fill in the missing information.

###hdf5_entry_t get_entry(hdf5_struct_t hdf5, char \*path)
Returns an entry from a `hdf5_struct_t` object or `NULL` if no entry is found or
if `path` does not point to a group.

####Example for `get_entry`
```c
hdf5_entry_t group_b;
if ((group_b = get_entry(hdf5, "groupB")) == NULL) {
    printf("failed to get groupB");
    return;
}
```

###hdf5_entry_t get_subentry(hdf5_entry_t entry, char \*path)
Returns an entry from a `hdf5_entry_t` object or `NULL` if no entry
is found or if `path` does not point to a group.

####Example for `get_subentry`
```c
hdf5_entry_t dataset_c;
if ((dataset_c = get_subentry(groupB, "dataC")) == NULL) {
    printf("failed to open dataset C");
    return;
}
```

###hdf5_entry_t get_group(hdf5_entry_t entry, char \*path)
Similar to `get_subentry` but the returned entry is guaranteed to be a group.
Returns `NULL` if a group can't be found.

###hdf5_entry_t get_dataset(hdf5_entry_t entry, char \*path)
Simialr to `get_subentry` but the returned entry is guaranteed to be a dataset.
Returns `NULL` if a dataset can't be found.

##<a name="data"></a>Accessing Data from Datasets
###int \*\*get_int_data(hdf5_entry_t entry)
Returns the int data associated with a `hdf5_entry_t` object or `NULL` if the
entry is a group. If `entry` does not contain int data, a message is printed to
stdout and `NULL` is returned.

####Example for `get_int_data`
```c
int **buf = get_int_data(dataset_c);
```

###double \*\*get_double_data(hdf5_entry_t entry)
Returns the double data associated with a `hdf5_entry_t` object or `NULL` if the
entry is a group. If `entry` does not contain double data, a message is printed
to stdout and `NULL` is returned.

####Example for `get_double_data`
```c
double **buf = get_double_data(dataset_c);
```

###char \*get_string_data(hdf5_entry_t entry)
Returns the string data associated with a `hdf5_entry_t` object or `NULL` if the
entry is a group. If `entry` does not contain string data, a message is printed
to stdout and `NULL` is returned.

####Example for `get_string_data`
```c
char *buf = get_string_data(dataset_c);
```

###void \*get_cmpd_data(hdf5_entry_t entry)
Returns the compound data associated with a `hdf5_entry_t` object or `NULL` if the
entry is a group. If `entry` does not contain compound data, a message is printed
to stdout and `NULL` is returned.

####Example for `get_compound_data`
```c
void *buf = get_cmpd_data(dataset_c);

// alternatively, if you know the structure of the data you can use a struct
// array
struct <struct name> *buf = get_cmpd_data(dataset);
```

##<a name="writing"></a>Writing Data
**Note**: the HDF5 library expects data written to files to be contiguous blocks
of memory. Because of this, explicitly malloc'd arrays should be used. While
this is straight-forward with arrays, writing matrices involves 'flattening' them
and treating an array as a matrix.

###void write_int_array(hdf5_entry_t entry, const char \*name, const hsize_t \*dims, int \*data)
Creates a new dataset in the group represented by `entry`. The name of the
dataset will be `name`. `dims` should be an array with the dimensions of the new
dataset and `data` is the actual data to be written.

####Example for `write_int_array`
```c
int i = 0;
hsize_t dims[1] = {10};
int *array = (int *) malloc(sizeof(int) * 10);

for (i = 0; i < 10; i++) {
    array[i] = i;
}

write_int_array(nd, "sample", dims, array);
```

###void write_double_array(hdf5_entry_t entry, const char \*name, const hsize_t \*dims, double \*data)
Creates a new dataset in the group represented by `entry`. The name of the
dataset will be `name`. `dims` should be an array with the dimensions of the new
dataset and `data` is the actual data to be written.

####Example for `write_double_array`
```c
int i = 0;
hsize_t dims[1] = {10};
double *array = (double *) malloc(sizeof(double) * 10);

for (i = 0; i < 10; i++) {
    array[i] = 3.16;
}

write_double_array(nd, "sample", dims, array);
```

###void write_int_matrix(hdf5_entry_t entry, const char \*name, const hsize_t \*dims, int \*data)
Creates a new dataset in the group represented by `entry`. The name of the
dataset will be `name`. `dims` should be an array with the dimensions of the new
dataset and `data` is the actual data to be written.

####Example for `write_int_matrix`
```c
int width = 10;
int height = 10;
int i, j;
hsize_t dims[2] = {width, height};
int *matrix = (int *) malloc(sizeof(int) * width * height);
for (i = 0; i < width; i++) {
    for (j = 0; j < height; j++) {
        matrix[i + j * width] = 0.0;
    }
}

write_int_matrix(nd, "sample", dims, matrix);
```

###void write_double_matrix(hdf5_entry_t entry, const char \*name, const hsize_t \*dims, int \*data)
Creates a new dataset in the group represented by `entry`. The name of the
dataset will be `name`. `dims` should be an array with the dimensions of the new
dataset and `data` is the actual data to be written.

####Example for `write_double_matrix`
```c
int width = 10;
int height = 10;
int i, j;
hsize_t dims[2] = {width, height};
double *matrix = (double *) malloc(sizeof(double) * width * height);
for (i = 0; i < width; i++) {
    for (j = 0; j < height; j++) {
        matrix[i + j * width] = 0.0;
    }
}

write_double_matrix(nd, "sample", dims, matrix);
```

###void write_string(hdf5_entry_t entry, const char \*name, const char \*buf)
Creates a new dataset in the group represented by `entry`. The name of the
dataset will be `name` and `data` is the actual data to be written.

####Example for `write_string`
```c
char *name = (char *) malloc(sizeof(char) * 10);
strcpy(name, "HDF5");
write_string(nd, "name", name);
```

##<a name="printing"></a>Printing
###print_hdf5_struct(hdf5_struct_t hdf5)
Prints basic information about a `hdf5_struct_t` object.

####Example for `print_hdf5_entry`
```c
print_hdf5_struct(hdf5);
```

###print_hdf5_entry(hdf5_entry_t entry)
Prints basic information about a `hdf5_entry_t` object.

####Example for `print_hdf5_entry`
```c
print_hdf5_entry(group_B);
```

##Macros
##Attribute Access
###X_DIM(entry)
Returns the first dimension of `entry`.

###Y_DIM(entry)
Returns the second dimension of `entry`.

##Convenience Macros
###IS_GROUP(entry)
Returns true if `entry` is a group, otherwise returns false.

###ENTRY_AT(entry, i)
Returns the child entry at index `i` belonging to `entry`.

###NUM_ENTRY(entry)
Returns the number of child entries belonging to `entry`.

##Tying It All Together...

```c
/*
 * sample.c
 *
 * This is a sample program that uses hdf5_struct.h to access specific datasets
 * in a HDF5 file.
 */

#include <stdio.h>
#include <stdlib.h>
#include "hdf5_struct.h"
#include "channel_locations.h"

int main() {
    // the file to work with
    char *file = "noiseDetection.h5";

    /* Basic access */
    // create the initial hdf5_struct_t object
    hdf5_struct_t hdf5 = new_hdf5_struct(file);

    hdf5_entry_t nd = get_entry(hdf5, "root");

    /* Accessing compound data types */
    hdf5_entry_t ref = get_group(nd, "reference");
    hdf5_entry_t channel_loc = get_dataset(ref, "channelLocations");
    print_hdf5_entry(channel_loc);
    printf("\n");

    // get the data from channel_loc and coerce it to a channel_location array
    struct channel_locations *buf = get_cmpd_data(channel_loc);

    // print the actual data
    int i;
    for (i = 0; i < X_DIM(channel_loc); i++) {
        print_channel_locations(buf[i]);
        // unfortunately, free_hdf5_struct does not free memory associated
        // with compound data types, only the related buffer
        free_channel_locations(buf[i]);
    }

    // finally release the memory associated with the hdf5_struct_t
    free_hdf5_struct(hdf5);

    return 0;
}
```

## Limitations
- Due to the nature of C, compound data types are read as raw data. However,
  certain structs are supplied to provide access to some of the more common
  compound datatypes.

- Since C lacks generics, there are functions to write datasets for each data
  type (`int`, `double`, and `char *`)
