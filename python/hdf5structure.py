"""
Provides functionality to read data from HDF5 files created by MATLAB.
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
        Creates and writes a new dataset in the HDF5 file
        :param path: the path of the new dataset to create
        :type path: string
        :param data: the dataset to write to HDF5 file
        """
        self._h5file.create_dataset(path, data=data)

    def get_lazy_entry(self, entry):
        """
        Returns a lazy entry from the HDF5 file
        :param entry: the entry to retrieve
        :type entry: string
        :return: a dictionary with either Groups or Datasets
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
        Evaluates an entry
        :param values: the values to evaluate
        :type values: dictionary
        """
        forced = {}
        if type(values) == h5py.Dataset:
            return values.value
        else:
            for key, value in values.iteritems():
                forced[key] = self._force(value)

        return forced

    def __str__(self):
        return "file: {0}\nentries: {1}".format(
            self._filename, ", ".join(self.entries()))
