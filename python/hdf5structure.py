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
        self._h5file = h5py.File(self._filename, 'r')

    def groups(self):
        """
        Returns the groups in the HDF5 file
        :return: list of the top-level groups
        """
        return self._h5file.keys()

    def get_lazy_group(self, group):
        """
        Returns a lazy group from the HDF5 file
        :param group: the group to retrieve
        :type group: string
        :return: a dictionary with either Groups or Datasets
        """
        try:
            self._h5file[group]
        except KeyError:
            print "no group with name '{0}' found".format(group)
            return {}
        return self._h5file[group]

    def get_group(self, group):
        """
        Returns an evaluated group from the HDF5 file
        :param group: the group to evaluate and retrieve
        :type group: string
        :return: a dictionary with the values evaluated
        """
        return self._force(self.get_lazy_group(group))

    def _force(self, values):
        """
        Evaluates a group
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
        return "file: {0}\ngroups: {1}".format(
            self._filename, ", ".join(self.groups()))
