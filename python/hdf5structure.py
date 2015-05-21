"""
Provides functionality to read data from HDF5 files created by MATLAB.

This is a thin wrapper around the h5py library. Similar to the R version, the
biggest difference is a little more laziness and the ability to either eagerly
read a dataset or to read it lazily.
"""
import sys
try:
    import h5py
except ImportError:
    print "please install h5py"
    sys.exit()


class Hdf5Structure(object):
    def __init__(self, h5file):
        """
        :param h5file: path to the HDF5 file
        :type h5file: string
        """
        self._filename = h5file
        self._h5file = h5py.File(self._filename, 'r+')

    def entries(self):
        """
        Returns the entries in the HDF5 file
        :return: list of the top-level entries
        """
        return self._h5file.keys()

    def write_dataset(self, path, data):
        """
        Creates and writes a new dataset in the HDF5 file. In order to maintain
        a similar API between the different versions, there isn't a method to
        create a new group
        :param path: the path of the new dataset to create
        :type path: string
        :param data: the dataset to write to the HDF5 file
        """
        self._h5file.create_dataset(path, data=data)

    def get_lazy_entry(self, entry):
        """
        Returns a lazy entry from the HDF5 file
        :param entry: the entry to retrieve
        :type entry: string
        :return: a dictionary with either a group or a dataset
        """
        try:
            self._h5file[entry]
        except KeyError:
            print "no entry with name '{0}' found".format(entry)
            return {}
        return self._h5file[entry]

    def get_entry(self, entry):
        """
        Returns an evaluated entry from the HDF5 file
        :param entry: the entry to evaluate and retrieve
        :type entry: string
        :return: a dictionary with the values evaluated
        """
        return self._force(self.get_lazy_entry(entry))

    def _force(self, values):
        """
        Evaluates an entry. If the entry is a group, the children entries are
        also evaluated, if the entry is a dataset, the actual dataset is read.
        :param values: the values to evaluate
        :type values: dictionary
        """
        if type(values) == h5py.Dataset:
            return values.value
        else:
            return {k: self._force(v) for k, v in values.iteritems()}

    def __str__(self):
        """
        Returns the name of the file and the entries that are in the file
        """
        return "file: {0}\nentries: {1}".format(
            self._filename, ", ".join(self.entries()))
