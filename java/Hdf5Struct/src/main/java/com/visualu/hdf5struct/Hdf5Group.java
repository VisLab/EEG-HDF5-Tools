package com.visualu.hdf5struct;

import ch.systemsx.cisd.hdf5.IHDF5Reader;

import java.util.*;

/**
 * A Hdf5Group corresponds to a group in a HDF5 file. It contains other
 * entries that can be either Groups or Datasets. To see the names of the
 * entries contain in a Group call the `entries` method, an Entry can be
 * retrieved from a Group by calling the `getEntry` method with the name of
 * the Entry. Groups also implement the Iterable interface.
 */
public class Hdf5Group extends Entry implements Iterable<Entry> {
    private String path;
    private IHDF5Reader reader;
    private Map<String, Entry> entries = new HashMap<String, Entry>();
    private Iterator<Entry> iterator;

    protected Hdf5Group(String path, IHDF5Reader reader) {
        this.path = path;
        this.reader = reader;
        for (String entry : reader.getGroupMembers(path)) {
            entries.put(entry, null);
        }
    }

    /**
     * Returns the names of the entries available in this group
     * @return the names of the entries in an array
     */
    public String[] entries() {
        List<String> names = this.reader.getGroupMembers(path);
        return names.toArray(new String[entries.size()]);
    }

    /**
     * Retrieves a generic Entry that belongs to this group.
     * @param name the name of the entry to retrieve
     * @return the entry named name or null if no entry is found.
     */
    public Entry getEntry(String name) {
        if (!reader.exists(path + name)) {
            return null;
        }
        Entry entry = entries.get(name);
        // only evaluate an Entry once
        if (entry == null) {
            if (reader.isGroup(path + name)) {
                return new Hdf5Group(path + name + "/", reader);
            } else {
                return new Hdf5Dataset(path + name + "/", reader);
            }
        }
        return entry;
    }

    /**
     * Retrieves a Group that belongs to this group
     * @param name the name of the group to retrieve
     * @return a Hdf5Group or null if no Group was found
     */
    public Hdf5Group getGroup(String name) {
        Entry e = this.getEntry(name);
        if (e.isGroup()) {
            return ((Hdf5Group) e);
        }

        return null;
    }

    /**
     * Searches through this group and all sub-groups for a Group
     * @param name the name of the Group to search for
     * @return the first Hdf5Group named name or null if no Group was found.
     */
    public Hdf5Group findGroup(String name) {
        // look for a group in this group
        if (this.entries.containsKey(name) && this.getEntry(name).isGroup()) {
            return this.getGroup(name);
        } else {
            // look in subgroups
            Hdf5Group result;
            for (Entry e: this) {
                if (e.isGroup()) {
                    Hdf5Group g = (Hdf5Group) e;
                    result = g.findGroup(name);
                    if (result != null) {
                        return result;
                    }
                }
            }
        }
        return null;
    }

    /**
     * Retrieves a Dataset that belongs to this group
     * @param name the name of the dataset to retrieve
     * @return a Hdf5Dataset or null if no Dataset was found
     */
    public Hdf5Dataset getDataset(String name) {
        Entry e = this.getEntry(name);
        if (e.isDataset()) {
            return ((Hdf5Dataset) e);
        }
        return null;
    }

    /**
     * Searches through this group and all sub-groups for a Dataset
     * @param name the name of the Dataset to search for
     * @return the first Hdf5Dataset named name or null if no Dataset was found.
     */
    public Hdf5Dataset findDataset(String name) {
        // look for a dataset in this group
        if (this.entries.containsKey(name) && this.getEntry(name).isDataset()) {
            return this.getDataset(name);
        }
        else {
            // look in subgroups
            Hdf5Dataset result;
            for (Entry e: this) {
                if (e.isGroup()) {
                    Hdf5Group g = (Hdf5Group) e;
                    result = g.findDataset(name);
                    if (result != null) {
                        return result;
                    }
                }
            }
        }
        return null;
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
        return "Path: " + this.path +
                "\n\tNumber of entries: " + entries.size() +
                "\n\tEntries: " + Arrays.toString(this.entries());
    }

    /*
     * Iterable implementation
     */
    public Iterator<Entry> iterator() {
        // evaluate *everything* first
        for (String name: this.entries.keySet()) {
            entries.put(name, this.getEntry(name));
        }

        List<Entry> vals = new ArrayList<Entry>(this.entries.values());
        this.iterator = vals.iterator();
        return this.iterator;
    }

    public boolean hasNext() {
        return this.iterator.hasNext();
    }
}
