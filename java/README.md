<!--- Written in GitHub falvored Markdown -->
#Hdf5Struct

Hdf5Struct makes reading HDF5 files easier in Java.

##Dependencies
* [HDF5 Java Products](http://www.hdfgroup.org/products/java/)

`Hdf5Struct` is technically a Maven project, but the jar from the HDF5 Group
that is available on Maven's Central Repository is from 2010 and `Hdf5Struct`
fails to build correctly. If a new version is ever available, the `pom.xml` will
be updated.

* Maven (to build the documentation)

##Documentation
To generate the Javadoc for this project using Maven, run

    mvn javadoc:javadoc

in the root directory, and the documentation should be available in
`target/site/apidocs`.

###General Overview
`Hdf5Struct` provides three main classes: `Entry`, `Hdf5Group`, and
`Hdf5Dataset`. An Entry is a general entry in a HDF5 file, and Hdf5Group and
Hdf5Dataset are more specific entries.

Hdf5Group objects have methods to view the entries in a group and to get an
entry.

Hdf5Dataset objects have methods to read the dataset and to get the dataset from
the object.

##Example
```java
import com.visualu.hdf5struct;
import com.visualu.hdf5struct.cmpd;

public class Test {
    public static void main(String[] args) {
        Hdf5Struct h5 = new Hdf5Struct("noiseDetection");

        // getEntry returns a generic Entry, so the cast is necessary
        Hdf5Group nd = (Hdf5Group) h5.getEntry("noisyParameters");

        // toString is overridden for Hdf5Struct, Hdf5Group, and Hdf5Dataset
        System.out.println(nd);

        // Hdf5Groups are iterable
        for (Entry e : nd) {
            if (e.isGroup()) {
                // process a group
            }
            if (e.isDataset()) {
                // process a dataset
            }
        }

        /* Reading compound datasets */
        Hdf5Group ref = (Hdf5Group) nd.getEntry("reference");
        Hdf5Dataset channelLocations = (Hdf5Dataset)
            ref.getEntry("channelLocations");

        // ChannelLocations provides a static method--fromList--to convert the
        // data from a compound dataset into an array of ChannelLocations
        // objects.
        ChannelLocations[] cls =
            ChannelLocations.fromList(channelLocations.getCompoundData());

        for (ChannelLocations cl : cls) {
            System.out.println(cl);
        }
    }
}
```
