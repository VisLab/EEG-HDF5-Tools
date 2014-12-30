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

# hdf5Structure
setClass("hdf5Structure",
  representation(
    name="ANY",
    reader="ANY",
    data="ANY"
))

# Constructor for hdf5Structure
Hdf5Structure <- function(file) {
  hd <- .HDReader(file)
  np <- new("hdf5Structure")
  slot(np, "reader") <- hd
  slot(np, "data") <- list()
  root <- paste(hd@contents[1, ]$group, hd@contents[1, ]$name, sep="")
                
  for (i in 2:length(hd@contents$name)) {
    row <- hd@contents[i, ]
    # only grab from the top-level
    if (row$group == root) {
      np@data[row$name] <- "ANY"
    }
  }
  
  list.names <- names(np@data)
  for (i in 1:length(np@data)) {
    # wrap the attributes in functions to feign lazy evaluation
    func <- paste("function(eval=T) {
                    return(", ".access(hd,", "\"", root, "/", list.names[i],
                  "\")) }", sep="")
    np@data[[i]] <- eval(parse(text=func))
  }
  return(np)
}

# returns a group
setGeneric('get.group', function(hdf5Structure, ...) {
    standardGeneric('get.group')
  })

setMethod('get.group', signature(hdf5Structure='hdf5Structure'),
  function(hdf5Structure, section) {
    if (section %in% names(hdf5Structure@data)) {
      if (typeof(hdf5Structure@data[[section]]) == "closure") {
        hdf5Structure <- .force.eval(hdf5Structure, section)
      }
      return(hdf5Structure@data[[section]])  
    } else {
      warning(paste("no group with name '", section, "' found", sep=''))
    }
  })

# forces evaluation of a group
setGeneric('.force.eval', function(hdf5Structure, ...) {
  standardGeneric('.force.eval')
})

setMethod('.force.eval', signature(hdf5Structure='hdf5Structure'),
  function(hdf5Structure, section) {
    slots <- slotNames(hdf5Structure)
    if (section %in% names(hdf5Structure@data)) {
      if (typeof(hdf5Structure@data[[section]]) == "closure") {
        hdf5Structure@data[[section]] <- hdf5Structure@data[[section]]()
      }
      return(hdf5Structure)
    } else {
      warning(paste("no group with name '", section, "' found", sep=''))  
    }
  })

# shows the groups in the object
setGeneric('groups',
  function(object) {
    standardGeneric('groups')
  })

setMethod('groups', signature(object='hdf5Structure'),
  function(object) {
    return(names(object@data))
})

# custom show function
setMethod("show", signature(object='hdf5Structure'),
  function(object) {
    file <- paste("file:", object@reader@file)
    groups <- paste("groups:", paste(groups(object), collapse=", "))
    cat(file, groups, sep="\n")
  })
