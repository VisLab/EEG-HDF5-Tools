package com.visualu.hdf5struct;

import ncsa.hdf.object.Dataset;
import ncsa.hdf.object.HObject;
import ncsa.hdf.object.h5.H5Group;

import java.util.*;

/**
 * A Hdf5Group corresponds to a group in a HDF5 file--and thus a
 * concrete Entry--and a ncsa.hdf.h5.H5Group. It wraps the underlying H5Group
 * and supplies some convenience methods.
 */
public class Hdf5Group extends Entry implements Iterable<Entry> {
    private H5Group obj;
    private Map<String, Entry> entries = new HashMap<String, Entry>();
    private Iterator<Entry> iterator;

    public Hdf5Group(H5Group obj) {
        this.obj = obj;
        obj.open();
        for (HObject entry : obj.getMemberList()) {
            if (entry instanceof H5Group) {
                entries.put(entry.getName(), new Hdf5Group((H5Group) entry));
            }
            if (entry instanceof Dataset) {
                entries.put(entry.getName(), new Hdf5Dataset((Dataset) entry));
            }
        }
    }

    /**
     * Returns the names of the entries available in this group
     * @return the names of the entries in an array
     */
    public String[] entries() {
        LinkedList<String> names = new LinkedList<String>();
        for (String name : this.entries.keySet()) {
            names.add(name);
        }
        return names.toArray(new String[entries.size()]);
    }

    /**
     * Retrieves an entry that belongs to this group and calls `readDataset`
     * if necessary.
     * @param name the name of the entry to retrieve
     * @return the entry named name or null if no entry is found.
     */
    public Entry getEntry(String name) {
        Entry entry = entries.get(name);
        // read dataset on request
        if (entry.isDataset()) {
            ((Hdf5Dataset) entry).readDataset();
        }
        return entry;
    }

    /**
     * Checks if this Entry is a Group.
     * @return true if the Entry is a Group; false otherwise
     */
    public boolean isGroup() {
        return true;
    }

    /**
     * Summarizes the group
     * @return a nice String
     */
    public String toString() {
        return "Name: " + this.obj.getName() +
                "\n\tNumber of entries: " + obj.getNumberOfMembersInFile () +
                "\n\tEntries: " + Arrays.toString(this.entries());
    }

    /*
     * Iterable implementation
     */
    public Iterator<Entry> iterator() {
        List<Entry> vals = new ArrayList<Entry>(this.entries.values());
        this.iterator = vals.iterator();
        return this.iterator;
    }

    public boolean hasNext() {
        return this.iterator.hasNext();
    }

}
