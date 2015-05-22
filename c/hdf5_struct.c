/*
 * This file has a lot of functions but most of them do one thing and are pretty
 * short. The fact that C doesn't support generics also adds to the number of
 * functions.
 *
 * Just like the other versions, this was written with laziness in mind. It does
 * add some complications to the implementation but after testing with valgrind
 * and massif, it keeps memory usage reasonably low.
 */

#include <stdlib.h>
#include <string.h>
#include "hdf5.h"
#include "hdf5_hl.h"
#include "hdf5_struct.h"

/* helper functions */
static void fill_entry_data(const hid_t, hdf5_entry_t);
static void set_dataset(hdf5_entry_t entry);
static void set_group(hdf5_entry_t entry);
static void hdf5_struct_get_entries(hdf5_struct_t);
static void read_dataset(hid_t root, hdf5_entry_t entry);
static void print_data(hdf5_entry_t entry);
static void print_data_type(hdf5_entry_t entry);
static void free_dataset(hdf5_entry_t entry);
static void free_group(hdf5_entry_t entry);
static void free_entry(hdf5_entry_t entry);
static hdf5_entry_t get_entry_info(const hid_t, int);

/*
 * Creates a new hdf5_struct_t from a file.
 * \param path: the path to the HDF5 file.
 * \return a pointer to a hdf5_struct_t object.
 *
 * Creating the `hdf5_struct` is kinda convoluted, but it's something like this:
 * new_hdf5_struct: this is the public function that starts everything
 *   - hdf5_struct_get_entries: allocates the array
 *     - get_entry_info: allocates memory for each entry, gets name and type
 *     - fill_entry_data: dispatch function based on the type of entry
 *       - set_group: allocates the array for the entries in this group
 *         - get_entry_info: same as above
 *       - read_dataset: reads in the dataset based on data type
 *
 * new_hdf5_struct only gets the information for entries located at the root of
 * the HDF5 file.
 */
hdf5_struct_t new_hdf5_struct(const char *path) {
    hdf5_struct_t hdf5;
    if ((hdf5 = (hdf5_struct_t) malloc(sizeof(struct hdf5_struct))) == NULL) {
        perror("malloc failed in new_hdf5_struct():hdf5");
        return NULL;
    }

    if ((hdf5->in_file = H5Fopen(path, H5F_ACC_RDWR, H5P_DEFAULT)) < 0) {
        perror("failed to open file");
        free(hdf5);
        return NULL;
    }

    if ((hdf5->root = (hdf5_entry_t)
                      malloc(sizeof(struct hdf5_entry))) == NULL) {
        perror("malloc failed in new_hdf5_struct():root");
        free(hdf5);
        return NULL;
    }

    strcpy(hdf5->root->name, "/");
    if ((hdf5->root->id = H5Gopen(hdf5->in_file, "/", H5P_DEFAULT)) < 0) {
        perror("failed to open root");
        free(hdf5);
        return NULL;
    }

    // evaluate the first layer
    hdf5_struct_get_entries(hdf5);

    return hdf5;
}

/*
 * Frees the memory associated with a hdf5_struct_t object.
 * \param hdf5 the hdf5_struct_t object to free.
 *
 * Freeing a hdf5_struct is similar to creating one, but in reverse
 * free_hdf5_struct: starts the process
 *   - free_entry: dispatch function based on the entry's type
 *     - free_group: calls `free_entry` on the entries in this group
 *     - free_dataset: frees the array associated with the dataset
 *
 * Along the way all the file handles are also closed
 */
void free_hdf5_struct(const hdf5_struct_t hdf5) {
    int i;
    for (i = 0; i < hdf5->root->num_entries; i++) {
        free_entry(hdf5->root->entries[i]);
        free(hdf5->root->entries[i]);
    }

    if ((H5Gclose(hdf5->root->id)) < 0) {
        perror("failed to close root");
    }
    if ((H5Fclose(hdf5->in_file)) < 0) {
        perror("failed to close file");
    }

    free(hdf5->root->entries);
    free(hdf5->root);
    free(hdf5);
}

/*
 * Gets the names of the entries from a hdf5_struct_t object.
 * \param hdf5 the hdf5_struct_t object to get the names from
 * \return a pointer to an array of chars containing the names
 */
char **entries(const hdf5_struct_t hdf5) {
    char **buf = (char **) malloc(sizeof(char *) * hdf5->root->num_entries);
    if (buf == NULL) {
        perror("malloc failed in entries():buf");
    }
    int i;
    for (i = 0; i < hdf5->root->num_entries; i++) {
        buf[i] = (char *) calloc(MAX_LEN, sizeof(char));
        if (buf[i] == NULL) {
            perror("malloc failed in entries():buf[i]");
        }
        strcpy(buf[i], hdf5->root->entries[i]->name);
    }

    return buf;
}

/*
 * Returns a specific entry in the HDF5 file
 * \param hdf5 the hdf5_struct_t object to get the entry from
 * \param path the name of the entry to get
 * \return an hdf5_entry_t object or NULL if no object found
 */
hdf5_entry_t get_entry(const hdf5_struct_t hdf5, const char *path) {
    hdf5_entry_t entry = get_subentry(hdf5->root, path);
    return entry;
}

/*
 * Returns a group from a hdf5_entry_t or NULL if the path doesn't point to a
 * group.
 * \param entry the hdf5_entry_t object to search through
 * \param path the path to the group
 * \return a hdf5_entry_t that is a group or NULL if one can't be found
 */
hdf5_entry_t get_group(const hdf5_entry_t entry, const char *path) {
    hdf5_entry_t e;
    if ((e = get_subentry(entry, path)) == NULL) {
        return NULL;
    }
    if (IS_GROUP(e)) {
        return e;
    } else {
        return NULL;
    }
}

/*
 * Returns a dataset from a hdf5_entry_t or NULL if the path doesn't point to a
 * dataset
 * \param entry the hdf5_entry_t object to search through
 * \param path the path to the dataset
 * \return a hdf5_entry_t that is a dataset or NULL if one can't be found
 */
hdf5_entry_t get_dataset(const hdf5_entry_t entry, const char *path) {
    hdf5_entry_t e;
    if ((e = get_subentry(entry, path)) == NULL) {
        return NULL;
    }
    if (!IS_GROUP(e)) {
        return e;
    } else {
        return NULL;
    }
}

/*
 * Returns a specific sub entry in a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to search for the sub entry in
 * \param path the path to the sub entry
 * \return an hdf5_entry_t object or NULL if no object found
 */
hdf5_entry_t get_subentry(const hdf5_entry_t entry, const char *path) {
    if (!IS_GROUP(entry)) {
        return NULL;
    }
    int i;
    hdf5_entry_t sub_entry;
    for (i = 0; i < entry->num_entries; i++) {
        if (strcmp(entry->entries[i]->name, path) == 0) {
            if ((sub_entry = entry->entries[i]) == NULL) {
                return NULL;
            }
            if (!sub_entry->evaluated) {
                fill_entry_data(entry->id, sub_entry);
            }
        }
    }

    return sub_entry;
}

/*
 * Returns the int data associated with a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to access
 * \return the int ** associated with a hdf5_entry_t object or NULL
 */
int **get_int_data(const hdf5_entry_t entry) {
    if (IS_GROUP(entry) || (entry->class != H5T_INTEGER)) {
        printf("%s does not contain integer data\n", entry->name);
        return NULL;
    }
    return INT_DATA(entry);
}

/*
 * Returns the float data associated with a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to access
 * \return the double ** associated with a hdf5_entry_t object or NULL
 */
double **get_double_data(const hdf5_entry_t entry) {
    if (IS_GROUP(entry) || (entry->class != H5T_FLOAT)) {
        printf("%s does not contain float data\n", entry->name);
        return NULL;
    }
    return FLOAT_DATA(entry);
}

/*
 * Returns the string data associated with a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to access
 * \return the char * associated with a hdf5_entry_t object or NULL
 */
char *get_string_data(const hdf5_entry_t entry) {
    if (IS_GROUP(entry) || (entry->class != H5T_STRING)) {
        printf("%s does not contain string data\n", entry->name);
        return NULL;
    }
    return STR_DATA(entry);
}

/*
 * Returns the compound data associated with a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to access
 * \return the void * associated with a hdf5_entry_t object or NULL
 */
void *get_cmpd_data(const hdf5_entry_t entry) {
    if (IS_GROUP(entry) || (entry->class != H5T_COMPOUND)) {
        printf("%s does not contain compound data\n", entry->name);
        return NULL;
    }
    return GEN_DATA(entry);
}

/*
 * Writes an integer array to a group
 * \param hdf5 the group to create the entry in
 * \param name the name of the new dataset
 * \param dims the dimensions of the new dataset
 * \param buf the data to write
 */
void write_int_array(hdf5_entry_t   entry,
                     const char    *name,
                     const hsize_t *dims,
                     int           *buf) {
    if (!IS_GROUP(entry)) {
        return;
    }
    if ((H5LTmake_dataset_int(entry->id, name, 1, (hsize_t *) dims, buf)) < 0) {
        printf("failed to write dataset\n");
    }
}

/*
 * Writes an integer matrix to a group
 * \param hdf5 the group to create the entry in
 * \param name the name of the new dataset
 * \param dims the dimensions of the new dataset
 * \param buf the data to write
 */
void write_int_matrix(hdf5_entry_t   entry,
                      const char    *name,
                      const hsize_t *dims,
                      int           *buf) {
    if (!IS_GROUP(entry)) {
        return;
    }
    if ((H5LTmake_dataset_int(entry->id, name, 2, dims, buf)) < 0) {
        printf("failed to write dataset\n");
    }
}

/*
 * Writes a double array to a group
 * \param hdf5 the group to create the entry in
 * \param name the name of the new dataset
 * \param dims the dimensions of the new dataset
 * \param buf the data to write
 */
void write_double_array(hdf5_entry_t   entry,
                        const char    *name,
                        const hsize_t *dims,
                        double        *buf) {
    if (!IS_GROUP(entry)) {
        return;
    }
    if ((H5LTmake_dataset_double(entry->id, name, 1,
                                 (hsize_t *) dims, buf)) < 0) {
        printf("failed to write dataset\n");
    }
}

/*
 * Writes a double matrix to a group
 * \param hdf5 the group to create the entry in
 * \param name the name of the new dataset
 * \param dims the dimensions of the new dataset
 * \param buf the data to write
 */
void write_double_matrix(hdf5_entry_t   entry,
                         const char    *name,
                         const hsize_t *dims,
                         double        *buf) {
    if (!IS_GROUP(entry)) {
        return;
    }
    if ((H5LTmake_dataset_double(entry->id, name, 2, dims, buf)) < 0) {
        printf("failed to write dataset\n");
    }
}

/*
 * Writes a string to a group
 * \param hdf5 the group to create the entry in
 * \param name the name of the new dataset
 * \param buf the data to write
 */
void write_string(hdf5_entry_t entry, const char *name, const char *buf) {
    if (!IS_GROUP(entry)) {
        return;
    }
    if ((H5LTmake_dataset_string(entry->id, name, buf)) < 0) {
        printf("failed to write dataset\n");
    }
}

/*
 * Prints information about a hdf5_struct_t object.
 * \param hdf5 the hdf5_struct_t object to print information about
 */
void print_hdf5_struct(const hdf5_struct_t hdf5) {
    int i;
    printf("name: %s\n", hdf5->root->name);
    printf("entries: ");
    for (i = 0; i < hdf5->root->num_entries; i++) {
        printf("%s ", hdf5->root->entries[i]->name);
    }
    printf("\n");
}

/*
 * Prints information about a hdf5_entry_t object.
 * \param entry the hdf5_entry object to print information about
 */
void print_hdf5_entry(const hdf5_entry_t entry) {
    printf("name: %s\n", entry->name);
    printf("evaluated: %s\n", entry->evaluated ? "true" : "false");
    switch (entry->type) {
        case H5G_GROUP:
            printf("num entries: %llu\n", entry->num_entries);
            printf("contains: ");
            int i;
            for (i = 0; i < entry->num_entries; i++) {
                printf("%s ", entry->entries[i]->name);
            }
            printf("\n");
            break;
        case H5G_DATASET:
            // conservative definition of 'large' data set
            printf("dims: %llu x %llu\n", X_DIM(entry), Y_DIM(entry));
            printf("type: ");
            print_data_type(entry);
            if (X_DIM(entry) * Y_DIM(entry) <= 100) {
                print_data(entry);
            } else {
                printf("[ large dataset ]\n");
            }
            break;
        case H5G_TYPE:
            printf("%s\n", "Named datatype");
            break;
        case H5G_LINK:
            printf("%s\n", "Link");
            break;
        case H5G_UDLINK:
            printf("%s\n", "User-defined Link");
            break;
    }
}

/*******************************************************************************
 *                              Helper functions
 ******************************************************************************/

/*
 * Frees the memory associated with a hdf5_entry_t object. Based on the entry's
 * type, this functions calls the appropriate function
 * \param entry the hdf5_entry_t object to free.
 */
static void free_entry(const hdf5_entry_t entry) {
    if (entry->evaluated) {
        switch (entry->type) {
            case H5G_GROUP:
                free_group(entry);
                break;
            case H5G_DATASET:
                free_dataset(entry);
                break;
        }
    }
}

/*
 * Frees the attributes specific to a group. Frees the entries contained in the
 * group and closes the handle to the group
 * \param entry the group to free
 */
static void free_group(const hdf5_entry_t entry) {
    int i;
    for (i = 0; i < entry->num_entries; i++) {
        free_entry(entry->entries[i]);
        free(entry->entries[i]);
    }

    if ((H5Gclose(entry->id)) < 0) {
        perror("failed to close group");
    }
    free(entry->entries);
}

/*
 * Frees the attributes specific to a dataset. Frees the array associated with
 * the dataset and closes the handle to the dataset
 * \param entry the dataset to free.
 */
static void free_dataset(const hdf5_entry_t entry) {
    if ((H5Dclose(entry->id)) < 0) {
        perror("failed to close dataset");
    }
    switch (entry->class) {
        case H5T_INTEGER:
            free(INT_DATA(entry)[0]);
            free(INT_DATA(entry));
            break;
        case H5T_FLOAT:
            free(FLOAT_DATA(entry)[0]);
            free(FLOAT_DATA(entry));
            break;
        case H5T_STRING:
            free(STR_DATA(entry));
            break;
        case H5T_COMPOUND:
            free(GEN_DATA(entry));
            break;
        default:
            break;
    }
}

/*
 * Gets the root entries for a hdf5_struct_t object. Allocates the array needed
 * to store the entries.
 * \param hdf5 the hdf5_struct_t object to fill in the entries
 */
static void hdf5_struct_get_entries(const hdf5_struct_t hdf5) {
    // get the entries from root
    H5G_info_t g_info;
    if ((H5Gget_info(hdf5->root->id, &g_info) < 0)) {
        perror("H5Gget_info failed");
        return;
    }

    hdf5->root->num_entries = g_info.nlinks;
    hdf5->root->entries     = (hdf5_entry_t *) malloc(sizeof(hdf5_entry_t) *
                                                      hdf5->root->num_entries);
    if (hdf5->root->entries == NULL) {
        perror("malloc failed in new_hdf5_struct():entries");
        free(hdf5);
        return;
    }

    int i;
    for (i = 0; i < hdf5->root->num_entries; i++) {
        if ((hdf5->root->entries[i] =
                 get_entry_info(hdf5->root->id, i)) == NULL) {
            perror("failed to get entry");
            return;
        }
        fill_entry_data(hdf5->root->id, hdf5->root->entries[i]);
    }
}

/*
 * Gets the information--name and type--about an entry and initializes the entry
 * \param root the parent group
 * \index the index of the entry
 * \return an hdf5_entry_t with filled information
 */
static hdf5_entry_t get_entry_info(const hid_t root, int index) {
    hdf5_entry_t entry;
    if ((entry = (hdf5_entry_t) calloc(1, sizeof(struct hdf5_entry))) == NULL) {
        perror("malloc failed in get_entry():entry");
        return NULL;
    }

    H5Gget_objname_by_idx(root, (hsize_t) index, entry->name, MAX_LEN);

    // TODO objtype_by_idx is deprecated
    entry->type = H5Gget_objtype_by_idx(root, (size_t) index);

    return entry;
}

/*
 * Fills is the data field of an hdf5_entry_t object if it's a dataset or fills
 * in the children entries if it's a group. This function calls the appropriate
 * function based on the entry's type and essentially evaluates the entry
 * \param root the parent group
 * \param entry the entry to fill
 */
static void fill_entry_data(const hid_t root, const hdf5_entry_t entry) {
    switch (entry->type) {
        case H5G_GROUP:
            if ((entry->id = H5Gopen(root, entry->name, H5P_DEFAULT)) < 0) {
                perror("failed to open group");
                return;
            }
            set_group(entry);
            break;
        case H5G_DATASET:
            read_dataset(root, entry);
            set_dataset(entry);
            break;
        default:
            break;
    }
}

/*
 * Sets the attributes specific to a dataset
 * \param entry the entry to set to a dataset
 */
static void set_dataset(const hdf5_entry_t entry) {
    entry->entries     = NULL;
    entry->num_entries = 0;
}

/*
 * Sets the attributes specific to a group. Allocates the array to store the
 * children entries.
 * \param entry the entry to set to a group
 */
static void set_group(const hdf5_entry_t entry) {
    H5G_info_t g_info;
    entry->evaluated = true;
    if ((H5Gget_info(entry->id, &g_info) < 0)) {
        perror("H5Gget_info failed");
        return;
    }

    entry->num_entries = g_info.nlinks;
    entry->entries     = (hdf5_entry_t *)
                         malloc(sizeof(hdf5_entry_t) * entry->num_entries);
    if (entry->entries == NULL) {
        perror("malloc failed in new_hdf5_struct():entries");
        free(entry);
        return;
    }

    int i;
    for (i = 0; i < entry->num_entries; i++) {
        entry->entries[i] = get_entry_info(entry->id, i);
    }
}

/*
 * Reads a dataset into the buffer of a hdf5_entry_t object
 * \param root the parent group
 * \param entry the entry to read the data into
 */
static void read_dataset(const hid_t root, const hdf5_entry_t entry) {
    int     i;
    char   *buf;
    hid_t   type;
    size_t  size;
    size_t *sizes;
    size_t *offsets;
    hsize_t n_fields;
    hsize_t n_records;

    if ((entry->id = H5Dopen(root, entry->name, H5P_DEFAULT)) < 0) {
        perror("failed to open dataset");
        return;
    }
    if ((H5LTget_dataset_info(root, entry->name, entry->dims, NULL,
                              &size)) < 0) {
        perror("failed to get dataset info");
        return;
    }
    if ((type = H5Dget_type(entry->id)) < 0) {
        perror("failed to get dataset type");
        return;
    }

    entry->evaluated = true;
    entry->size  = size;
    entry->class = H5Tget_class(type);

    switch (entry->class) {
        case H5T_FLOAT:
            FLOAT_DATA(entry) =
                (double **) malloc(sizeof(double *) * X_DIM(entry));
            FLOAT_DATA(entry)[0] =
                (double *) malloc(X_DIM(entry) * Y_DIM(entry) * sizeof(double));
            for (i = 1; i < X_DIM(entry); i++) {
                FLOAT_DATA(entry)[i] = FLOAT_DATA(entry)[0] + i * Y_DIM(entry);
            }
            if ((H5LTread_dataset_double(root, entry->name,
                                         FLOAT_DATA(entry)[0])) < 0) {
                perror("failed to read dataset");
                return;
            }
            break;
        case H5T_INTEGER:
            INT_DATA(entry)    = (int **) malloc(sizeof(int *) * X_DIM(entry));
            INT_DATA(entry)[0] =
                (int *) malloc(X_DIM(entry) * Y_DIM(entry) * sizeof(int));
            for (i = 1; i < X_DIM(entry); i++) {
                INT_DATA(entry)[i] = INT_DATA(entry)[0] + i * Y_DIM(entry);
            }
            if ((H5LTread_dataset_int(root, entry->name,
                                      INT_DATA(entry)[0])) < 0) {
                perror("failed to read dataset");
                return;
            }
            break;
        case H5T_STRING:
            buf = (char *) calloc(size + 1, sizeof(char));
            STR_DATA(entry) = calloc(1, size + 1);
            if ((H5LTread_dataset_string(root, entry->name, buf)) < 0) {
                perror("failed to read dataset");
                return;
            }
            strcpy(STR_DATA(entry), buf);
            free(buf);
            break;
        case H5T_BITFIELD:
            printf("bitfield: %s\n", entry->name);
            break;
        case H5T_OPAQUE:
            printf("opaque: %s\n", entry->name);
            break;
        case H5T_COMPOUND:
            H5TBget_table_info(root, entry->name, &n_fields, &n_records);
            sizes   = (size_t *) malloc(sizeof(size_t) * n_fields);
            offsets = (size_t *) malloc(sizeof(size_t) * n_fields);
            H5TBget_field_info(root, entry->name, NULL, sizes, offsets, &size);

            GEN_DATA(entry) = malloc(size * n_records);
            if ((H5TBread_table(root, entry->name, size, offsets,
                                sizes, GEN_DATA(entry))) < 0) {
                perror("failed to read dataset");
            }
            free(sizes);
            free(offsets);
            break;
        case H5T_REFERENCE:
            printf("TODO reference: %s\n", entry->name);
            break;
        case H5T_ENUM:
            printf("TODO enum: %s\n", entry->name);
            break;
        case H5T_VLEN:
            printf("TODO vlen: %s\n", entry->name);
            break;
        case H5T_ARRAY:
            printf("TODO array: %s\n", entry->name);
            break;
        case H5T_NO_CLASS:
            printf("Not a valid class: %s\n. No data read", entry->name);
            break;
        case H5T_NCLASSES:
            printf("nclasses: %s\n. No data read", entry->name);
        case H5T_TIME:
            printf("Time not supported: %s\n. No data read", entry->name);
            break;
    }
}

/*
 * Prints the data type of a hdf5_entry_t object.
 * \param entry a hdf5_entry_t object
 */
static void print_data_type(const hdf5_entry_t entry) {
    if (!entry->evaluated) {
        printf("?\n");
        return;
    }
    switch (entry->class) {
        case H5T_INTEGER:
            printf("integer\n");
            break;
        case H5T_FLOAT:
            printf("double\n");
            break;
        case H5T_STRING:
            printf("string\n");
            break;
        case H5T_COMPOUND:
            printf("compound\n");
            break;
        default:
            printf("other\n");
    }
}

/*
 * Prints the data in hdf5_entry-t.data.*
 * \param entry the hdf5_entry_t object to print the data from
 */
static void print_data(const hdf5_entry_t entry) {
    int i, j;
    printf("[ ");
    switch (entry->class) {
        case H5T_FLOAT:
            for (i = 0; i < X_DIM(entry); i++) {
                for (j = 0; j < Y_DIM(entry); j++) {
                    printf("%.2f ", FLOAT_DATA(entry)[i][j]);
                }
            }
            break;
        case H5T_INTEGER:
            for (i = 0; i < X_DIM(entry); i++) {
                for (j = 0; j < Y_DIM(entry); j++) {
                    printf("%d ", INT_DATA(entry)[i][j]);
                }
            }
            break;
        case H5T_STRING:
            printf("%s ", STR_DATA(entry));
            break;
        case H5T_COMPOUND:
            printf("compound data type ");
            break;
        default:
            printf("TODO ");
    }
    printf("]\n");
}
