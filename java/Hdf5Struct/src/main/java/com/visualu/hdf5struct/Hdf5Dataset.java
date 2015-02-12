package com.visualu.hdf5struct;

import ncsa.hdf.object.Dataset;
import ncsa.hdf.object.Datatype;

import java.util.Arrays;
import java.util.List;

/**
 * A Hdf5Dataset corresponds to a dataset in a HDF5 file--and thus a concrete
 * Entry--and a ncsa.hdf.object.Dataset. It wraps the underlying Dataset and
 * supplies some convenience methods.
 */
public class Hdf5Dataset extends Entry {
    private Dataset obj;
    private int datatypeClass;
    private Object data = null;
    private long[] dimens = null;

    public Hdf5Dataset(Dataset obj) {
        // do the least amount of work possible on creation
        this.obj = obj;
        this.datatypeClass = obj.getDatatype().getDatatypeClass();
    }

    /**
     * Forces the dataset to be loaded into memory. The H5 library only reads
     * the basic information about a Dataset initially, this method forces the
     * datatype and the dataspace to be read.
     */
    public void readDataset() {
        obj.open();
        // load the dataset into memory
        obj.init();
        dimens = obj.getDims();
        try {
            data = obj.getData();
        } catch (Exception e) {
            System.out.println(e);
        }
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
     * Accesses the Dataset's raw data and converts it to a double array.
     * Checks to ensure that the object's datatype is CLASS_FLOAT, if it's
     * not, an IllegalArgumentException will be thrown.
     * @return a double array if the Entry's datatype is CLASS_FLOAT
     * @throws IllegalArgumentException
     */
    public double[][] getFloatData() throws IllegalArgumentException {
        if (datatypeClass != Datatype.CLASS_FLOAT) {
            throw new IllegalArgumentException(obj.getName() +
                " does not " + "contain float data");
        }
        double[] temp = (double[]) this.data;
        double[][] ret = new double[getXDim()][getYDim()];
        if (temp.length == getXDim() * getYDim()) {
            for (int i = 0; i < getXDim(); i++) {
                System.arraycopy(temp, (i * getYDim()), ret[i], 0, getYDim());
            }
        }
        return ret;
    }

    /**
     * Accesses the Dataset's raw data and converts in to an int array.
     * Checks to ensure that the object's datatype is CLASS_INTEGER, it it's
     * not, an IllegalArgumentException is thrown.
     * @return an int array if the Entry's datatype is CLASS_INTEGER
     * @throws IllegalArgumentException
     */
    public int[][] getIntData() throws IllegalArgumentException {
        if (datatypeClass != Datatype.CLASS_INTEGER) {
            throw new IllegalArgumentException(obj.getName() +
                " does not " + "contain integer data");
        }
        int[] temp = (int[]) this.data;
        int[][] ret = new int[getXDim()][getYDim()];
        if (temp.length == getXDim() * getYDim()) {
            for (int i = 0; i < getXDim(); i++) {
                System.arraycopy(temp, (i * getYDim()), ret[i], 0, getYDim());
            }
        }
        return ret;
    }

    /**
     * Accesses the Dataset's raw data and converts it to a String array.
     * Checks to ensure that the object's datatype is CLASS_STRING, if it's
     * not, an IllegalArgumentException is thrown.
     * @return a String array if the Entry's datatype is CLASS_STRING
     * @throws IllegalArgumentException
     */
    public String[] getStringData() throws IllegalArgumentException {
        if (datatypeClass != Datatype.CLASS_STRING) {
            throw new IllegalArgumentException(obj.getName() +
                " does not " + "contain String data");
        }
        return (String[]) this.data;
    }

    /**
     * Accesses the Dataset's raw data and converts in to a List of arrays.
     * Checks to ensure that the object's datatype is CLASS_COMPOUND, if it's
     * not, an IllegalArgumentException is thrown.
     * @return a List of arrays if the Entry's datatype is CLASS_COMPOUND
     * @throws IllegalArgumentException
     */
    public List getCompoundData() throws IllegalArgumentException {
        if (datatypeClass != Datatype.CLASS_COMPOUND) {
            throw new IllegalArgumentException(obj.getName() + " does not " +
                "contain compound data");
        }
        return (List) this.data;
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
        return "Name: " + this.obj.getName() +
               "\n\tDimensions: " + (dimens == null ? "?" :
                    Arrays.toString(dimens)) +
               "\n\tType: " + this.datatypeToString();
    }

    /**
     * Converts this object's datatype to a string
     * @return a string representing the datatype
     */
    private String datatypeToString() {
        switch (this.datatypeClass) {
            case Datatype.CLASS_ARRAY:
                return "Array";
            case Datatype.CLASS_BITFIELD:
                return "Bitfield";
            case Datatype.CLASS_CHAR:
                return "Char";
            case Datatype.CLASS_COMPOUND:
                return "Compound";
            case Datatype.CLASS_ENUM:
                return "Enum";
            case Datatype.CLASS_FLOAT:
                return "Float";
            case Datatype.CLASS_INTEGER:
                return "Integer";
            case Datatype.CLASS_NO_CLASS:
                return "No Class";
            case Datatype.CLASS_OPAQUE:
                return "Opaque";
            case Datatype.CLASS_REFERENCE:
                return "Reference";
            case Datatype.CLASS_STRING:
                return "String";
            case Datatype.CLASS_TIME:
                return "Time";
            case Datatype.CLASS_VLEN:
                return "Vlen";
        }
        return "";
    }
}
