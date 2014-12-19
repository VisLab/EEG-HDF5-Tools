"""
Provides functionality to read data from HDF5 files created by MATLAB.
"""
import sys
try:
    import h5py
except ImportError:
    print "please install h5py"
    sys.exit()


class NoisyParameters(object):
    def __init__(self, h5file):
        """
        :param h5file: path to the HDF5 file
        :type h5file: string
        """
        self._filename = h5file
        self._h5file = h5py.File(self._filename, 'r')['noisyParameters']
        self._dataset = self._h5file['name'].value

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
        return {key: self._h5file[group][key] for key in
                self._h5file[group].keys()}

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
        for key, value in values.iteritems():
            if type(value) == h5py.Dataset:
                forced[key] = value.value
            else:
                forced[key] = self._force(value)

        return forced

    def __str__(self):
        return "file: {0}\ndataset: {1}\ngroups: {2}".format(
            self._in_file, self._dataset, ", ".join(self.groups()))
