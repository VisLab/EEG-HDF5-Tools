library("rhdf5")

# Reads a HDF5 file into a NoisyParameters object.
#   np <- NoisyParameter("file.h5")
#   np@resampling$originalFrequency

# HDReader
setClass("HDReader",
  representation(
    file="character",
    contents="data.frame"
))

# constructor
.HDReader <- function(file) {
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
# channelInformation field.
.gen <- function(np) {
  for (i in 1:length(np@contents$name)) {
    row <- np@contents[i, ]
    
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
        delayedAssign("toReturn", .access(object, section))
        return(toReturn)
      })))
  }
}

# NoisyParameters
setClass("noisyParameters",
  representation(reader="HDReader",
                 name="character",
                 high.pass="list",
                 line.noise="list",
                 reference="list",
                 resampling="list",
                 version="list"))

# constructor
NoisyParameters <- function(file) {
  reader <- .HDReader(file)
  # lazy load reference
  delayedAssign("this.reference", .reference(reader))
  
  new("noisyParameters",
      reader=reader,
      name=.name(reader),
      high.pass=.highPass(reader),
      line.noise=.lineNoise(reader),
      reference=this.reference,
      resampling=.resampling(reader),
      version=.version(reader))
}

# ChannelLocations
setClass("channelLocations",
  representation(reader="HDReader",
                 reference="data.frame",
                 noisy.out="data.frame",
                 noisy.out.original="data.frame"
))

# constructor
ChannelLocations <- function(reader) {
  new("channelLocations",
      reader=reader,
      reference=data.frame(.reference.channelLocations(reader)),
      noisy.out=data.frame(.reference.noisyOut.channelLocations(reader)),
      noisy.out.original=data.frame(
        .reference.noisyOutOriginal.channelLocations(reader))
      )  
}
