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
##Creation and Deletion
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

##Accessing Entries and Data
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

###void \*get_data(hdf5_entry_t entry)
Returns the data associated with a `hdf5_entry_t` object or `NULL` if the entry
is a group

####Example for `get_data`
```c
/* assumes that dataC contains integers */
int **buf = get_data(dataset_c);
```

##Printing
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
##Data Access
###FLOAT_DATA(entry)
Returns the double data from a `hdf5_entry_t` object.

###INT_DATA(entry)
Returns the int data from a `hdf5_entry_t` object.

###STR_DATA(entry)
Returns the string data from a `hdf5_entry_t` object.

###GEN_DATA(entry)
Returns a raw data buffer representing a compound data type from a
`hdf5_entry_t` object.

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
    char *file = "noisyParameters.h5";

    /* Basic access */
    // create the initial hdf5_struct_t object
    hdf5_struct_t hdf5 = new_hdf5_struct(file);

    hdf5_entry_t np = get_entry(hdf5, "noisyParameters");

    // get the entry named 'highPass' in the noisyParameters group
    hdf5_entry_t high_pass = get_subentry(np, "highPass");

    // print basic information about the entries in high_pass
    int i;
    for (i = 0; i < NUM_ENTRY(high_pass); i++) {
        print_hdf5_entry(ENTRY_AT(high_pass, i));
        printf("\n");
    }

    /* Accessing compound data types */
    hdf5_entry_t ref = get_subentry(np, "reference");
    hdf5_entry_t channel_loc = get_subentry(ref, "channelLocations");
    print_hdf5_entry(channel_loc);
    printf("\n");

    // get the data from channel_loc and coerce it to a channel_location array
    struct channel_locations *buf = get_data(channel_loc);

    // print the actual data
    for (i = 0; i < X_DIM(channel_loc); i++) {
        print_channel_locations(buf[i]);
        // unfortunately, free_hdf5_struct does not free memory associated
        // with compound data types, only the related buffer
        free(buf[i].labels);
        free(buf[i].type);
        free(buf[i].ref);
    }

    // finally release the memory associated with the hdf5_struct_t
    free_hdf5_struct(hdf5);

    return 0;
}
```

## Limitations
Due to the nature of C, compound data types are read as raw data. However,
certain structs are supplied to provide access to some of the more common
compound datatypes.
