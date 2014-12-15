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

# Constructor for noisyParameters
# dynamically generates the class, attributes, and methods
NoisyParameters <- function(file) {
  hd <- .HDReader(file)
  slots <- list()
  slots[["reader"]] <- "ANY"
  slots[["name"]] <- "ANY"
  for (i in 2:length(hd@contents$name)) {
    row <- hd@contents[i, ]
    # only grab the groups at the top-level
    if (toString(row$otype) == "H5I_GROUP" && row$group=="/noisyParameters") {
      slots[[row$name]] <- "ANY"
    }
  }
  
  setClass('noisyParameters', slots=slots)
  np <- new("noisyParameters")
  slot(np, "reader") <- hd
  slot(np, "name") <- .access(hd, '/noisyParameters/name')
  
  names <- slotNames(np)
  names.length <- length(names)
  
  for (i in 3:names.length) {
    # wrap the attributes in function to feign lazy evaluation
    func <- paste("function(eval=T) {
                    return(", ".access(hd, \"/noisyParameters/", names[i], "\")) }",
                  sep="")
    slot(np, names[i]) <- eval(parse(text=func))
  }
  return(np)
}

# returns a group
setGeneric('get.group', function(noisyParameters, ...) {
    standardGeneric('get.group')
  })

setMethod('get.group', signature(noisyParameters='noisyParameters'),
  function(noisyParameters, section) {
    slots <- slotNames(noisyParameters)
    if (section %in% slots) {
      if (typeof(slot(np, section)) == "closure") {
        noisyParameters <- force.eval(noisyParameters, section)
      }
      return(slot(noisyParameters, section))  
      }
  })

# forces evaluation of a group
setGeneric('force.eval', function(noisyParameters, ...) {
  standardGeneric('force.eval')
})

setMethod('force.eval', signature(noisyParameters='noisyParameters'),
  function(noisyParameters, section) {
    slots <- slotNames(noisyParameters)
    if (section %in% slots) {
      if (typeof(slot(noisyParameters, section)) == "closure") {
        slot(noisyParameters, section) <- slot(noisyParameters, section)()
      }
      return(noisyParameters)
    }
  })

# forces evaluation of all groups
setGeneric('force.all',
  function(object) {
    standardGeneric('force.all')
  })

setMethod('force.all', signature(object='noisyParameters'),
  function(object) {
    object.new <- object
    slots <- slotNames(object)
    for (i in 3:length(slots)) {
      object.new <- force.eval(object.new, slots[i])
    }
    return(object.new)
  })

# shows the groups in the object
setGeneric('groups',
  function(object) {
    standardGeneric('groups')
  })

setMethod('groups', signature(object='noisyParameters'),
  function(object) {
    slots <- slotNames(object)
    return(slots[3:length(slots)])
})

# custom show function
setMethod("show", signature(object='noisyParameters'),
  function(object) {
    slots <- slotNames(object)[3:length(slotNames(object))]
    file <- paste("file:", object@reader@file)
    dataset <- paste("dataset:", object@name)
    groups <- paste("groups:", paste(slots, collapse=", "))
    cat(file, dataset, groups, sep="\n")
  })
