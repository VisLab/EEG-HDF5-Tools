package com.visualu.hdf5struct;

import ch.systemsx.cisd.base.mdarray.MDDoubleArray;
import ch.systemsx.cisd.base.mdarray.MDIntArray;
import ch.systemsx.cisd.hdf5.HDF5CompoundDataList;
import ch.systemsx.cisd.hdf5.HDF5DataClass;
import ch.systemsx.cisd.hdf5.HDF5DataSetInformation;
import ch.systemsx.cisd.hdf5.IHDF5Reader;

import java.util.Arrays;

/**
 * A Hdf5Dataset corresponds to a dataset in a HDF5 file. Datasets contain the
 * actual data stored in the HDF5 file along with various attributes about
 * the data such as dimensions and rank. The methods to get numeric datasets
 * returns a MDArray from the jhdf5 library. To get the data into an array
 * call getAsFlatArray or toMatrix.
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
     * Access the Dataset's double data.
     * @return a MDDoubleArray containing doubles
     * @throws IllegalArgumentException if the Dataset does not contain doubles
     */
    public MDDoubleArray getDoubleData() throws IllegalArgumentException {
        if (this.info.getTypeInformation().getDataClass() !=
                HDF5DataClass.FLOAT) {
            throw new IllegalArgumentException(path +
                "does not contain float data");
        }
        if (this.info.getRank() == 1) {
            return new MDDoubleArray(reader.float64().readArray(path), dimens);
        } else {
            return new MDDoubleArray(reader.float64().readMatrix(path));
        }
    }

    /**
     * Access the Dataset's integer data
     * @return a MDIntArray containing integers
     * @throws IllegalArgumentException if the Dataset does not contain integers
     */
    public MDIntArray getIntData() throws IllegalArgumentException {
        if (this.info.getTypeInformation().getDataClass() !=
                HDF5DataClass.INTEGER) {
            throw new IllegalArgumentException(path +
                "does not contain integer data");
        }
        if (this.info.getRank() == 1) {
            return new MDIntArray(reader.int32().readArray(path), dimens);
        } else {
            return new MDIntArray(reader.int32().readMatrix(path));
        }
    }

    /**
     * Access the Dataset's String data
     * @return a string array
     * @throws IllegalArgumentException if the Dataset does not contain an
     * array of strings
     */
    public String[] getStringData() throws IllegalArgumentException {
        try {
            return reader.string().readArray(path);
        } catch (Exception e) {
            throw new IllegalArgumentException(path +
                "does not contain string data");
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
