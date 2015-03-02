package com.visualu.hdf5struct;

import ch.systemsx.cisd.hdf5.HDF5Factory;
import ch.systemsx.cisd.hdf5.IHDF5Reader;

import java.util.Arrays;

/**
 * Class to represent the overall HDF5 file. It maintains information about
 * the root of the file as well as information about the file itself.
 */
public class Hdf5Struct {
    private String filename;
    private IHDF5Reader reader;
    private Hdf5Group root;

    public Hdf5Struct(String filename) {
        this.filename = filename;
        this.reader = HDF5Factory.openForReading(this.filename);
        this.root = new Hdf5Group("/", reader);
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
