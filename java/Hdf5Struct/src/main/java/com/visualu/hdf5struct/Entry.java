package com.visualu.hdf5struct;

/**
 * An Entry is an abstract entity in a HDF5 file. The only information
 * tracked by an Entry is if it's a Group or an Entry; it is meant to be
 * subtyped.
 */
abstract public class Entry {
    /*
     * Only one of the following methods has to be defined in a subclass
     */

    /**
     * Whether or not an Entry represents a Group
     * @return true if the Entry is a Group; false otherwise
     */
    public boolean isGroup() {
        return !isDataset();
    }

    /**
     * Whether or not an Entry represents a Dataset
     * @return true if the Entry is a Dataset; false otherwise
     */
    public boolean isDataset() {
        return !isGroup();
    }
}
