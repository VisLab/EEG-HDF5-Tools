package com.visualu.hdf5struct;

import ch.systemsx.cisd.hdf5.IHDF5Reader;

import java.util.*;

/**
 * A Hdf5Group corresponds to a group in a HDF5 file--and thus a
 * concrete Entry. It contains other entries that can be either Groups or
 * Datasets. To see the names of the entries contain in a Group call the
 * `entries` method, an Entry can be retrieved from a Group by calling the
 * `getEntry` method with the name of the Entry. Groups also implement the
 * Iterable interface.
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
     * Retrieves an entry that belongs to this group and calls `readDataset`
     * if necessary.
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
