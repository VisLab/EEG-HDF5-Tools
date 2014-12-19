library("rhdf5")

# Reads a HDF5 file into a hdf5Structure object.
#   np <- Hdf5Structure("file.h5")
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

# Constructor for hdf5Structure
# dynamically generates the class, attributes, and methods
Hdf5Structure <- function(file) {
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
  
  setClass('hdf5Structure', slots=slots)
  np <- new("hdf5Structure")
  slot(np, "reader") <- hd
  slot(np, "name") <- .access(hd, '/noisyParameters/name')
  
  names <- slotNames(np)
  names.length <- length(names)
  
  for (i in 3:names.length) {
    # wrap the attributes in function to feign lazy evaluation
    func <- paste("function(eval=T) {
                    return(", ".access(hd, \"/noisyParameters/", names[i],
                  "\")) }", sep="")
    slot(np, names[i]) <- eval(parse(text=func))
  }
  return(np)
}

# returns a group
setGeneric('get.group', function(hdf5Structure, ...) {
    standardGeneric('get.group')
  })

setMethod('get.group', signature(hdf5Structure='hdf5Structure'),
  function(hdf5Structure, section) {
    slots <- slotNames(hdf5Structure)
    if (section %in% slots) {
      if (typeof(slot(np, section)) == "closure") {
        hdf5Structure <- .force.eval(hdf5Structure, section)
      }
      return(slot(hdf5Structure, section))  
      }
  })

# forces evaluation of a group
setGeneric('.force.eval', function(hdf5Structure, ...) {
  standardGeneric('.force.eval')
})

setMethod('.force.eval', signature(hdf5Structure='hdf5Structure'),
  function(hdf5Structure, section) {
    slots <- slotNames(hdf5Structure)
    if (section %in% slots) {
      if (typeof(slot(hdf5Structure, section)) == "closure") {
        slot(hdf5Structure, section) <- slot(hdf5Structure, section)()
      }
      return(hdf5Structure)
    }
  })

# shows the groups in the object
setGeneric('groups',
  function(object) {
    standardGeneric('groups')
  })

setMethod('groups', signature(object='hdf5Structure'),
  function(object) {
    slots <- slotNames(object)
    return(slots[3:length(slots)])
})

# custom show function
setMethod("show", signature(object='hdf5Structure'),
  function(object) {
    slots <- slotNames(object)[3:length(slotNames(object))]
    file <- paste("file:", object@reader@file)
    groups <- paste("groups:", paste(slots, collapse=", "))
    cat(file, groups, sep="\n")
  })
