package com.visualu.hdf5struct;

import ncsa.hdf.object.h5.H5File;
import ncsa.hdf.object.h5.H5Group;

import java.util.Arrays;

/**
 * Basic class to represent the overall HDF5 file.
 * This class is essentially a wrapper around the root Hdf5Group object, but
 * it also maintains information related to the file that it represents.
 */
public class Hdf5Struct {
    private String filename;
    private Hdf5Group root;

    public Hdf5Struct(String filename) {
        this.filename = filename;
        H5File infile = new H5File(this.filename);
        try {
            infile.open();
        } catch (Exception e) {
            System.out.println(e);
        }
        // Double casting! Straight from the HDF5 Group's example
        root = new Hdf5Group((H5Group) ((javax.swing.tree
                .DefaultMutableTreeNode)
                infile.getRootNode()).getUserObject());
    }

    /**
     * Returns an entry with a specific name
     * @param name the name of the Entry to search for
     * @return an Entry
     */
    public Entry getEntry(String name) {
        return root.getEntry(name);
    }

    /**
     * Returns the names of the entries available in this file's root group
     * @return the names of the entries in an array
     */
    public String[] entries() {
        return root.entries();
    }

    /**
     * Returns a string summarizing the object
     * @return a pretty string
     */
    public String toString() {
        return "filename: " + this.filename +
                "\nEntries: " + Arrays.toString(this.entries());
    }
}
