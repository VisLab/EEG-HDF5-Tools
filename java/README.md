<!--- Written in GitHub falvored Markdown -->
#Hdf5Struct

Hdf5Struct makes reading HDF5 files easier in Java.

##Dependencies
* [HDF5 Java Products](http://www.hdfgroup.org/products/java/)

* Maven

##Building and Documentation
To build the jar, run `mvn package` a jar should now be in `./target/`

To generate the Javadocs, run `mvn javadoc:javadoc` in the root directory, and
the documentation should be available in `./target/site/apidocs`.

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
import com.visualu.hdf5struct.*;
import com.visualu.hdf5struct.cmpd;

public class Test {
    public static void main(String[] args) {
        Hdf5Struct h5 = new Hdf5Struct("noiseDetection.h5");

        // getEntry returns a generic Entry, so the cast is necessary
        Hdf5Group nd = (Hdf5Group) h5.getEntry("noisyDetection");

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

#Running
Running a program that depends on the HDF5 libraries and jars involves modifying
Java's classpath and native library path.

To compile a file, run

    javac -cp .:Hdf5Struct.jar <file.java>

And to run the program, run

    java -cp ".:Hdf5Struct.jar:<path-to-HDF5View-jars>/*" -Djava.library.path=<path-to-HDF5View-libs>" <file>
