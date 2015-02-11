package com.visualu.hdf5struct;

import ncsa.hdf.object.Dataset;
import ncsa.hdf.object.Datatype;

import java.util.Arrays;

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
     * Checks to ensure that the object's datatype is CLASS_FLOAT.
     * @return a double array if the Entry's datatype is CLASS_FLOAT; else null
     */
    public double[][] getFloatData() {
        double[] temp = (double []) this.data;
        if (temp.length == getXDim() * getYDim()
                && datatypeClass == Datatype.CLASS_FLOAT) {
            double[][] ret = new double[getXDim()][getYDim()];
            for (int i = 0; i < getXDim(); i++) {
                System.arraycopy(temp, (i * getYDim()), ret[i], 0, getYDim());
            }
            return ret;
        }
        return null;
    }

    /**
     * Accesses the Dataset's raw data and converts in to an int array.
     * Checks to ensure that the object's datatype is CLASS_INTEGER.
     * @return an int array if the Entry's datatype is CLASS_INTEGER; else null.
     */
    public int[][] getIntData() {
        int[] temp = (int []) this.data;
        if (temp.length == getXDim() * getYDim()
                && datatypeClass == Datatype.CLASS_INTEGER) {
            int[][] ret = new int[getXDim()][getYDim()];
            for (int i = 0; i < getXDim(); i++) {
                System.arraycopy(temp, (i * getYDim()), ret[i], 0, getYDim());
            }
        }
        return null;
    }

    /**
     * Accesses the Dataset's raw data and converts it to a String array.
     * Checks to ensure that the object's datatype is CLASS_STRING.
     * @return a String array if the Entry's datatype is CLASS_STRING; else null
     */
    public String[] getStringData() {
        if (datatypeClass == Datatype.CLASS_STRING) {
            return (String[]) this.data;
        }
        return null;
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
                "\n\tDimensions: " + (dimens == null ? "?" : Arrays.toString
                (dimens)) +
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
