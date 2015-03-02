<!--- Written in GitHub falvored Markdown -->
#Hdf5Struct

Hdf5Struct makes reading HDF5 files easier in Java.

##Dependencies
* [jhdf5](https://wiki-bsse.ethz.ch/pages/viewpage.action?pageId=26609113)
* [Maven](https://maven.apache.org/)

##Building and Documentation
To build the jar, run `mvn package` and a jar should now be in `./target/`

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

#Compiling and Running
`jhdf5` simplifies the run process compared to the HDF Group's Java library.
However, Java's CLASSPATH still has to be modified.

*Note: The following commands assume that `Hdf5Struct.jar` is in the working directory.*

To compile a program, run

    javac -cp .:Hdf5Struct.jar <file.java>

And to run the program, run

    java -cp ".:Hdf5Struct.jar:<path-to-jhdf5>/lib/batteries_included/*" <file>
