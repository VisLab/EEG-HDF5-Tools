package com.visualu.hdf5struct;

import ch.systemsx.cisd.hdf5.HDF5Factory;
import ch.systemsx.cisd.hdf5.IHDF5Writer;

import java.util.Arrays;

/**
 * Class to represent the overall HDF5 file. It maintains information about
 * the root of the file as well as information about the file itself.
 */
public class Hdf5Struct {
    private String filename;
    private IHDF5Writer writer;
    private Hdf5Group root;

    public Hdf5Struct(String filename) {
        this.filename = filename;
        this.writer = HDF5Factory.open(this.filename);
        this.root = new Hdf5Group("/", writer);
    }

    /**
     * Returns a generic entry with a specific name
     * @param name the name of the Entry to search for
     * @return an Entry
     */
    public Entry getEntry(String name) {
        return root.getEntry(name);
    }

    /**
     * Retrieves a Group from root
     * @param name the name of the Group to retrieve
     * @return a Hdf5Group or null if no Group was found
     */
    public Hdf5Group getGroup(String name) {
        return root.getGroup(name);
    }

    /**
     * Retrieves a Dataset from root
     * @param name the name of the Dataset to retrieve
     * @return a Hdf5Dataset or null if no Dataset was found.
     */
    public Hdf5Dataset getDataset(String name) {
        return root.getDataset(name);
    }

    /**
     * Searches the entire file for a Group
     * @param name the name of the Group to search for
     * @return the first Group named name or null if no Group was found
     */
    public Hdf5Group findGroup(String name) {
        return root.findGroup(name);
    }

    /**
     * Searches the entire file for a Dataset
     * @param name the name of the Dataset to search for
     * @return the first Dataset named name or null if no Dataset was found
     */
    public Hdf5Dataset findDataset(String name) {
        return root.findDataset(name);
    }

    /**
     * Creates a new dataset in the HDF5 file
     * @param path the path of the new dataset
     * @param data the double array to write
     */
    public void writeDataset(String path, double data[]) {
        this.writer.float64().createArray(path, data.length);
        this.writer.float64().writeArray(path, data);
    }

    /**
     * Creates a new dataset in the HDF5 file
     * @param path the path of the new dataset
     * @param data the double matrix to write
     */
    public void writeDataset(String path, double data[][]) {
        this.writer.float64().createMatrix(path, data.length, data[0].length);
        this.writer.float64().writeMatrix(path, data);
    }

    /**
     * Creates a new dataset in the HDF5 file
     * @param path the path of the new dataset
     * @param data the integer array to write
     */
    public void writeDataset(String path, int data[]) {
        this.writer.int32().createArray(path, data.length);
        this.writer.int32().writeArray(path, data);
    }

    /**
     * Creates a new dataset in the HDF5 file
     * @param path the path of the new dataset
     * @param data the integer matrix to write
     */
    public void writeDataset(String path, int data[][]) {
        this.writer.int32().createMatrix(path, data.length, data[0].length);
        this.writer.int32().writeMatrix(path, data);
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
