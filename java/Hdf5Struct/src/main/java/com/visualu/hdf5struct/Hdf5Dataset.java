package com.visualu.hdf5struct;

import ch.systemsx.cisd.hdf5.*;

import java.util.Arrays;

/**
 * A Hdf5Dataset corresponds to a dataset in a HDF5 file. Datasets contain the
 * actual data stored in the HDF5 file along with various attributes about
 * the data such as dimensions and rank.
 */
public class Hdf5Dataset extends Entry {
    private String path;
    private IHDF5Reader reader;
    private HDF5DataSetInformation info;
    private long[] dimens = null;

    protected Hdf5Dataset(String path, IHDF5Reader reader) {
        this.path = path;
        this.reader = reader;
        this.info = reader.getDataSetInformation(path);
        this.dimens = info.getDimensions();
    }

    /**
     * Access the X dimension size for this Dataset
     * @return the X dimension
     */
    public int getXDim() {
        return (int) this.dimens[0];
    }

    /**
     * Access the Y dimension size for this Dataset
     * @return the Y dimension
     */
    public int getYDim() {
        return (int) this.dimens[1];
    }

    /**
     * Returns the rank of the Dataset
     * @return an int representing the rank of the Dataset.
     */
    public int getRank() {
        return this.info.getRank();
    }

    /*
     * Reading Data
     */

    /**
     * Access the Dataset's float matrix
     * @return a 2D double array
     * @throws IllegalArgumentException if the Dataset does contain a float
     * matrix
     */
    public double[][] getFloatMatrix() throws IllegalArgumentException {
        try {
            return reader.float64().readMatrix(path);
        } catch (Exception e) {
            throw new IllegalArgumentException(path +
                " does not contain a float matrix");
        }
    }

    /**
     * Access the Dataset's float array
     * @return a double array
     * @throws IllegalArgumentException if the Dataset does not contain a
     * float array
     */
    public double[] getFloatArray() throws IllegalArgumentException {
        if ((this.info.getRank() != 1) ||
            (this.info.getTypeInformation().getDataClass() !=
                HDF5DataClass.FLOAT)) {
            throw new IllegalArgumentException(path +
                " does not contain an integer array");
        }
        return reader.float64().readArray(path);
    }

    /**
     * Access the Dataset's integer matrix
     * @return a 2D integer array
     * @throws IllegalArgumentException if the Dataset does not contain an
     * integer matrix
     */
    public int[][] getIntMatrix() throws IllegalArgumentException {
        try {
            return reader.int32().readMatrix(path);
        } catch (Exception e) {
            throw new IllegalArgumentException(path +
                " does not contain an integer matrix");
        }
    }

    /**
     * Access the Dataset's integer array
     * @return an integer array
     * @throws IllegalArgumentException if the Dataset does not contain an
     * integer array
     */
    public int[] getIntArray() throws IllegalArgumentException {
        if ((this.info.getRank() != 1) ||
            (this.info.getTypeInformation().getDataClass() !=
                HDF5DataClass.INTEGER)) {
            throw new IllegalArgumentException(path +
                " does not contain an integer array");
        }
        return reader.int32().readArray(path);
    }

    /**
     * Access the Dataset's string array
     * @return a string array
     * @throws IllegalArgumentException if the Dataset does not contain an
     * array of strings
     */
    public String getStringData() throws IllegalArgumentException {
        try {
            return reader.string().read(path);
        } catch (Exception e) {
            throw new IllegalArgumentException(path +
                "does not contain a string");
        }
    }

    /**
     * Access the Dataset's compound data
     * @return an HDF5CompoundDataList array
     * @throws IllegalArgumentException if the Dataset does not contain
     * compound data
     */
    public HDF5CompoundDataList[] getCompoundData()
        throws IllegalArgumentException {
        try {
            return reader.compound().readArray(path, HDF5CompoundDataList.class);
        } catch (Exception e) {
            throw new IllegalArgumentException(path +
                "does not contain compound data");
        }
    }

    /**
     * Returns the type of the Dataset
     * @return the type of the Dataset as a String
     */
    public String getDataType() {
        return this.info.getTypeInformation().getDataClass().toString()
                        .toLowerCase();
    }

    /**
     * Checks if this Entry is a Dataset
     * @return true if the Entry is a Dataset; false otherwise
     */
    public boolean isDataset() {
        return true;
    }

    /**
     * Summarizes this object
     * @return a delightful string
     */
    public String toString() {
        return "Path: " + this.path +
               "\n\tDimensions: " + Arrays.toString(this.dimens) +
               "\n\tType: " + this.getDataType();
    }
}
