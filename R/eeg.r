library("rhdf5")

setClass("HDReader",
  representation(
    file="character",
    contents="data.frame"))

# Constructor
HDReader <- function(file) {
  contents <- h5ls(file)
  np <- new("HDReader", file=file, contents=contents)
  .gen(np)
  return(np)
}

# generic access function
setGeneric(".access",
  function(object, ...) {
    standardGeneric(".access")
})

setMethod(".access", signature(object="HDReader"),
  function(object, part) {
    h5read(object@file, part)
})

# generates the functions to read in specific fields from the HDF5 file, i.e
# reference.channelInformation(new HDReader("file")) to read the
# channelInformation field. All the functions are private
.gen <- function(np) {
  for (i in 1:length(np@contents$name)) {
    row <- np@contents[i, ]
    if (toString(row$otype) == "H5I_DATASET") {
      section <- paste(row$group, row$name, sep="/")
      fName <- gsub("([a-z])/", "\\1.",
                    gsub("^/noisyParameters/", ".", section))
      # generate generic methods
      setGeneric(fName,
        eval(substitute(function(object) {
          return(.access(object, section))
        })))
      
      setMethod(fName, signature(object="HDReader"),
        eval(substitute(function(object) {
          return(.access(object, section))
        })))
    }
  }
}

setClass("channelLocations",
  representation(reader="HDReader",
                 x="matrix",
                 y="matrix",
                 z="matrix",
                 labels="matrix",
                 radius="matrix",
                 ref="matrix",
                 sph_phi="matrix",
                 sph_radius="matrix",
                 sph_theta="matrix",
                 theta="matrix",
                 type="matrix",
                 urchan="matrix"
  ))

ChannelLocations <- function(reader) {
  new("channelLocations",
      reader=reader,
      x=.reference.channelLocations.X(reader),
      y=.reference.channelLocations.Y(reader),
      z=.reference.channelLocations.Z(reader),
      labels=.reference.channelLocations.labels(reader),
      radius=.reference.channelLocations.radius(reader),
      ref=.reference.channelLocations.ref(reader),
      sph_phi=.reference.channelLocations.sph_phi(reader),
      sph_radius=.reference.channelLocations.sph_radius(reader),
      sph_theta=.reference.channelLocations.sph_theta(reader),
      theta=.reference.channelLocations.theta(reader),
      type=.reference.channelLocations.type(reader),
      urchan=.reference.channelLocations.urchan(reader)
      )  
}
