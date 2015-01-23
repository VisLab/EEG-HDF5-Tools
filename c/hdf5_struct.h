#ifndef _HDF5_STRUCT_H_
#define _HDF5_STRUCT_H_

#include <stdbool.h>
#include "hdf5.h"

#define MAX_LEN        1024

// shorter access to hdf5_entry_t->data.*
#define FLOAT_DATA(e)  ((e->data.double_data))
#define INT_DATA(e)    ((e->data.int_data))
#define STR_DATA(e)    ((e->data.string_data))
#define GEN_DATA(e)    ((e->data.gen_data))

// access to hdf5_entry_t->dims[...]--mainly to prevent indexing errors
#define X_DIM(e)       ((e->dims[0]))
#define Y_DIM(e)       ((e->dims[1]))

#define IS_GROUP(e)    ((e->type == H5G_GROUP))
#define ENTRY_AT(e, i) ((e->entries[i]))
#define NUM_ENTRY(e)   ((e->num_entries))


/*
 * Buffer for a dataset. To lower memory use, the different types are stored in
 * a union.
 */
union data_buffer {
    int    **int_data;
    double **double_data;
    char    *string_data;
    void    *gen_data;
};

/*
 * An entry in an HDF5 file. It can be either a group or a dataset
 */
typedef struct hdf5_entry {
    int   type;                  // the type of the entry (group or dataset)
    char  name[MAX_LEN];         // the name of the entry
    hid_t id;                    // the id of the entry
    /* specific to datasets */
    bool evaluated;              // whether the dataset has been read
    H5T_class_t class;           // type of the dataset
    hsize_t     dims[2];         // dimensions of the dataset
    int size;                    // size of the dataset in bytes
    union data_buffer data;      // the actual data
    /* specific to groups */
    hsize_t num_entries;         // the number of entries
    struct hdf5_entry **entries; // children entries
} *hdf5_entry_t;

/*
 * Holds information about the overall HDF5 file
 */
typedef struct hdf5_struct {
    hid_t in_file;      // the id of the hdf5 file
    hdf5_entry_t root;  // the root entry
} *hdf5_struct_t;

/*
 * Creates a new hdf5_struct_t from a file.
 */
hdf5_struct_t new_hdf5_struct(const char *path);

/*
 * Frees the memory associated with a hdf5_struct_t
 */
void free_hdf5_struct(const hdf5_struct_t hdf5);

/*
 * Gets the groups that are available in a hdf5_struct_t
 */
char **groups(const hdf5_struct_t hdf5);

/*
 * Returns a specific group in the HDF5 file
 */
hdf5_entry_t get_group(const hdf5_struct_t hdf5, const char *path);

/*
 * Returns a group/dataset from a group
 */
hdf5_entry_t get_subgroup(const hdf5_entry_t entry, const char *path);

/*
 * Prints a hdf5_struct_t
 */
void print_hdf5_struct(const hdf5_struct_t hdf5);

/*
 * Returns the data associated with a hdf5_entry_t object
 */
void *get_data(const hdf5_entry_t entry);

/*
 * Prints a hdf5_entry_t
 */
void print_hdf5_entry(const hdf5_entry_t);

#endif
