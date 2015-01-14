#include <stdlib.h>
#include <string.h>
#include "hdf5.h"
#include "hdf5_hl.h"
#include "hdf5_struct.h"

/* helper functions */
static void         fill_entry_data(const hid_t, hdf5_entry_t);
static void         set_dataset(hdf5_entry_t entry);
static void         set_group(hdf5_entry_t entry);
static void         hdf5_struct_get_entries(hdf5_struct_t);
static void         read_dataset(hid_t root, hdf5_entry_t entry);
static void         print_data(hdf5_entry_t entry);
static void         free_dataset(hdf5_entry_t entry);
static void         free_group(hdf5_entry_t entry);
static void         free_entry(hdf5_entry_t entry);
static hdf5_entry_t get_entry_info(const hid_t, int);

/*
 * Creates a new hdf5_struct_t from a file.
 * \param path: the path to the HDF5 file.
 * \return a pointer to a hdf5_struct_t object.
 */
hdf5_struct_t new_hdf5_struct(const char *path) {
    hdf5_struct_t hdf5 = (hdf5_struct_t) malloc(sizeof(struct hdf5_struct));

    if (hdf5 == NULL) {
        perror("malloc failed in new_hdf5_struct():hdf5");
        return NULL;
    }

    if ((hdf5->in_file = H5Fopen(path, H5F_ACC_RDONLY, H5P_DEFAULT)) < 0) {
        perror("failed to open file");
        free(hdf5);
        return NULL;
    }

    H5Gget_objname_by_idx(hdf5->in_file, (hsize_t) 0, hdf5->root_name, MAX_LEN);
    if ((hdf5->root = H5Gopen1(hdf5->in_file, hdf5->root_name)) < 0) {
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
 */
void hdf5_struct_free(const hdf5_struct_t hdf5) {
    int i;
    for (i = 0; i < hdf5->num_entries; i++) {
        free_entry(hdf5->entries[i]);
        free(hdf5->entries[i]);
    }

    if ((H5Gclose(hdf5->root)) < 0) {
        perror("failed to close root");
    }
    if ((H5Fclose(hdf5->in_file)) < 0) {
        perror("failed to close file");
    }

    free(hdf5->entries);
    free(hdf5);
}

/*
 * Gets the names of the groups from a hdf5_struct_t object.
 * \param hdf5 the hdf5_struct_t object to get the names from
 * \return a pointer to an array of chars containing the names
 */
char **groups(const hdf5_struct_t hdf5) {
    char **buf = (char **) malloc(sizeof(char *) * hdf5->num_entries);
    if (buf == NULL) {
        perror("malloc failed in groups():buf");
    }
    int i;
    for (i = 0; i < hdf5->num_entries; i++) {
        buf[i] = (char *) malloc(sizeof(char) * MAX_LEN);
        if (buf[i] == NULL) {
            perror("malloc failed in groups():buf[i]");
        }
        strcpy(buf[i], hdf5->entries[i]->name);
    }

    return buf;
}

/*
 * Returns a specific group in the HDF5 file
 * \param hdf5 the hdf5_struct_t object to get the entry from
 * \param path the name of the entry to get
 * \return an hdf5_entry_t object or NULL if no object found
 */
hdf5_entry_t get_group(const hdf5_struct_t hdf5, const char *path) {
    int          i;
    hdf5_entry_t entry = NULL;
    for (i = 0; i < hdf5->num_entries; i++) {
        if (strcmp(hdf5->entries[i]->name, path) == 0) {
            entry = hdf5->entries[i];
        }
    }

    for (i = 0; i < entry->num_entries; i++) {
        if (!entry->entries[i]->evaluated) {
            fill_entry_data(entry->id, entry->entries[i]);
        }
    }

    return entry;
}

/*
 * Returns a specific sub entry in a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to search for the sub entry in
 * \param path the path to the sub entry
 * \return an hdf5_entry_t object or NULL if no object found
 */
hdf5_entry_t get_subgroup(const hdf5_entry_t entry, const char *path) {
    int          i;
    hdf5_entry_t sub_entry = NULL;
    for (i = 0; i < entry->num_entries; i++) {
        if (strcmp(entry->entries[i]->name, path) == 0) {
            sub_entry = entry->entries[i];
        }
    }

    return sub_entry;
}

/*
 * Prints information about a hdf5_struct_t object.
 * \param hdf5 the hdf5_struct_t object to print information about
 */
void print_hdf5_struct(const hdf5_struct_t hdf5) {
    printf("HDF5\n====\n");
    printf("id: %d\n", hdf5->in_file);
    printf("name: %s\n", hdf5->root_name);
    printf("root_id: %d\n", hdf5->root);
}

/*******************************************************************************
 *                              Helper functions
 ******************************************************************************/

/*
 * Frees the memory associated with a hdf5_entry_t object.
 * \param entry the hdf5_entry_t object to free.
 */
static void free_entry(const hdf5_entry_t entry) {
    switch (entry->type) {
        case H5G_GROUP:
            free_group(entry);
            break;
        case H5G_DATASET:
            free_dataset(entry);
            break;
    }
}

/*
 * Frees the attributes specific to a group
 * \param entry the group to free
 */
static void free_group(const hdf5_entry_t entry) {
    int i;
    for (i = 0; i < entry->num_entries; i++) {
        free_entry(entry->entries[i]);
        free(entry->entries[i]);
    }

    if (entry->evaluated) {
        if ((H5Gclose(entry->id)) < 0) {
            perror("failed to close group");
        }
    }
    free(entry->entries);
}

/*
 * Frees the attributes specific to a dataset
 * \param entry the dataset to free.
 */
static void free_dataset(const hdf5_entry_t entry) {
    if (entry->evaluated) {
        int i;
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
                for (i = 0; i < X_DIM(entry); i++) {
                    free(LOC_DATA(entry)[i].labels);
                    free(LOC_DATA(entry)[i].type);
                    free(LOC_DATA(entry)[i].ref);
                }
                free(LOC_DATA(entry));
                break;
            default:
                break;
        }
    }
}

/*
 * Gets the entries for a hdf5_struct_t object
 * \param hdf5 the hdf5_struct_t object to fill in the entries
 */
static void hdf5_struct_get_entries(const hdf5_struct_t hdf5) {
    // get the entries from root
    H5G_info_t g_info;
    if ((H5Gget_info(hdf5->root, &g_info) < 0)) {
        perror("H5Gget_info failed");
        return;
    }

    hdf5->num_entries = g_info.nlinks;
    hdf5->entries     = (hdf5_entry_t *)
                        malloc(sizeof(hdf5_entry_t) * hdf5->num_entries);
    if (hdf5->entries == NULL) {
        perror("malloc failed in new_hdf5_struct():entries");
        free(hdf5);
        return;
    }

    int i;
    for (i = 0; i < hdf5->num_entries; i++) {
        if ((hdf5->entries[i] = get_entry_info(hdf5->root, i)) == NULL) {
            perror("failed to get entry");
            return;
        }
        fill_entry_data(hdf5->root, hdf5->entries[i]);
    }
}

/*
 * Gets the information (name and type) about an entry and initializes the entry
 * \param root the parent group
 * \index the index of the entry
 * \return an hdf5_entry_t with filled information
 */
static hdf5_entry_t get_entry_info(const hid_t root, int index) {
    hdf5_entry_t entry = (hdf5_entry_t) malloc(sizeof(struct hdf5_entry));
    if (entry == NULL) {
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
 * in the children entries if it's a group.
 * \param root the parent group
 * \param entry the entry to fill
 */
static void fill_entry_data(const hid_t root, const hdf5_entry_t entry) {
    switch (entry->type) {
        case H5G_GROUP:
            entry->id = H5Gopen1(root, entry->name);
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
 * Sets the attributes specific to a group
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

    entry->evaluated = true;
    entry->id = H5Dopen1(root, entry->name);
    H5LTget_dataset_info(root, entry->name, entry->dims, NULL, &size);
    type = H5Dget_type(entry->id);
    entry->size  = size;
    entry->class = H5Tget_class(type);

    switch (entry->class) {
        case H5T_FLOAT:
            FLOAT_DATA(entry) =
                (float **) malloc(sizeof(float *) * X_DIM(entry));
            FLOAT_DATA(entry)[0] =
                (float *) malloc(X_DIM(entry) * Y_DIM(entry) * sizeof(float));
            for (i = 1; i < X_DIM(entry); i++) {
                FLOAT_DATA(entry)[i] = FLOAT_DATA(entry)[0] + i * Y_DIM(entry);
            }
            H5LTread_dataset_float(root, entry->name, FLOAT_DATA(entry)[0]);
            break;
        case H5T_INTEGER:
            INT_DATA(entry)    = (int **) malloc(sizeof(int *) * X_DIM(entry));
            INT_DATA(entry)[0] =
                (int *) malloc(X_DIM(entry) * Y_DIM(entry) * sizeof(int));
            for (i = 1; i < X_DIM(entry); i++) {
                INT_DATA(entry)[i] = INT_DATA(entry)[0] + i * Y_DIM(entry);
            }
            H5LTread_dataset_int(root, entry->name, INT_DATA(entry)[0]);
            break;
        case H5T_STRING:
            buf = (char *) calloc(size + 1, sizeof(char));
            STR_DATA(entry) = calloc(1, size + 1);
            H5LTread_dataset_string(root, entry->name, buf);
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
            // assumes that the *only* compound data type is channel locations
            H5TBget_table_info(root, entry->name, &n_fields, &n_records);
            sizes   = (size_t *) malloc(sizeof(size_t) * n_fields);
            offsets = (size_t *) malloc(sizeof(size_t) * n_fields);
            H5TBget_field_info(root, entry->name, NULL, sizes, offsets, &size);

            LOC_DATA(entry) = (struct channel_loc *)
                              malloc(sizeof(struct channel_loc) * n_records);
            H5TBread_records(root, entry->name, 0, n_records, size,
                             offsets, sizes, LOC_DATA(entry));
            free(sizes);
            free(offsets);
            break;
        case H5T_REFERENCE:
            printf("reference: %s\n", entry->name);
            break;
        case H5T_ENUM:
            printf("enum: %s\n", entry->name);
            break;
        case H5T_VLEN:
            printf("vlen: %s\n", entry->name);
            break;
        case H5T_ARRAY:
            printf("array: %s\n", entry->name);
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
 * Prints information about a hdf5_entry_t object.
 * \param entry the hdf5_entry object to print information about
 */
void print_hdf5_entry(const hdf5_entry_t entry) {
    printf("\tHDF5 ENTRY\n\t==========\n");
    printf("\tname: %s\n", entry->name);
    printf("\tdims: %llu x %llu\n", X_DIM(entry), Y_DIM(entry));
    printf("\tevaluated? %s\n", entry->evaluated ? "true" : "false");
    print_data(entry);
    switch (entry->type) {
        case H5G_GROUP:
            printf("\t%s\n", "Group");
            printf("\tNum Entries: %llu\n", entry->num_entries);
            printf("SUB");
            int i;
            for (i = 0; i < entry->num_entries; i++) {
                print_hdf5_entry(entry->entries[i]);
            }
            break;
        case H5G_DATASET:
            printf("\t%s\n", "Dataset");
            break;
        case H5G_TYPE:
            printf("\t%s\n", "Named datatype");
            break;
        case H5G_LINK:
            printf("\t%s\n", "Link");
            break;
        case H5G_UDLINK:
            printf("\t%s\n", "User-defined Link");
            break;
    }
}

/*
 * Prints the data in hdf5_entry-t.data.*
 * \param entry the hdf5_entry_t object to print the data from
 */
static void print_data(const hdf5_entry_t entry) {
    int i, j;
    printf("\t[ ");
    switch (entry->class) {
        case H5T_FLOAT:
            for (i = 0; i < X_DIM(entry); i++) {
                for (j = 0; j < Y_DIM(entry); j++) {
                    printf("%.0f ", FLOAT_DATA(entry)[i][j]);
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
            for (i = 0; i < X_DIM(entry); i++) {
                printf("%-5s%-5s%12f%12f%12f%12f%12f%12f%12f%12f%12f%12s\n\t",
                       LOC_DATA(entry)[i].labels, LOC_DATA(entry)[i].type,
                       LOC_DATA(entry)[i].theta, LOC_DATA(entry)[i].radius,
                       LOC_DATA(entry)[i].X, LOC_DATA(entry)[i].Y,
                       LOC_DATA(entry)[i].Z, LOC_DATA(entry)[i].sph_theta,
                       LOC_DATA(entry)[i].sph_phi,
                       LOC_DATA(entry)[i].sph_radius, LOC_DATA(entry)[i].urchan,
                       LOC_DATA(entry)[i].ref);
            }
            break;
        default:
            printf("TODO ");
    }
    printf("]\n");
}
