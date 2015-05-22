library("rhdf5")

# Reads a HDF5 file into a hdf5Structure object.
#   np <- Hdf5Structure("file.h5")
#   np@resampling$originalFrequency
#
# This is a thin wrapper around the rhdf5 library. The main addition is improved
# laziness. R *is* lazy, but unfortunately, it's strict when you create a class,
# the work-around is to store the actual groups as thunks in a list. It's only
# when they are actually requested that the thunk is evaluated and the group is
# returned.

# HDReader class
# This class is not exposed and is only used internally. The main purpose of it
# is to ease reading the HDF5 file.
# 
# methods
# - .access
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
# This function wraps `h5read` and simply allows you to access a group without
# having to specify the file. It shortens the code since paths can get long
setGeneric(".access",
  function(object, ...) {
    standardGeneric(".access")
})

setMethod(".access", signature(object="HDReader"),
  function(object, part) {
    h5read(object@file, part)
})

# hdf5Structure class
# This class is exposed and provides access to the groups in the HDF5 file.
#
# methods
# - get.entry
# - .force.eval
# - entries
# - write.dataset
setClass("hdf5Structure",
  representation(
    name="ANY",
    reader="ANY",
    data="ANY"
))

# Constructor for hdf5Structure
Hdf5Structure <- function(file, root="/") {
  hd <- .HDReader(file)
  np <- new("hdf5Structure")
  slot(np, "reader") <- hd
  slot(np, "data") <- list()
                
  for (i in 1:length(hd@contents$name)) {
    row <- hd@contents[i, ]
    # only grab from the top-level
    if (row$group == root) {
      np@data[row$name] <- "ANY"
    }
  }
  
  list.names <- names(np@data)
  for (i in 1:length(np@data)) {
    # wrap the attributes in functions to feign lazy evaluation. According to
    # an answer on StackOverflow, a function should have at least one parameter,
    # `eval=T` is just thrown in for this reason
    func <- if (root == "/") {
              paste("function(eval=T) {
                    return(", ".access(hd,", "\"", root, list.names[i],
                    "\")) }", sep="")
            } else {
              paste("function(eval=T) {
                    return(", ".access(hd,", "\"", root, "/", list.names[i],
                    "\")) }", sep="")
            }
    np@data[[i]] <- eval(parse(text=func))
  }
  return(np)
}

# Returns an entry from a hdf5structure. If the entry is still a closure, it
# evaluates it before returning it
setGeneric('get.entry', function(hdf5Structure, ...) {
    standardGeneric('get.entry')
  })

setMethod('get.entry', signature(hdf5Structure='hdf5Structure'),
  function(hdf5Structure, section) {
    if (section %in% names(hdf5Structure@data)) {
      if (typeof(hdf5Structure@data[[section]]) == "closure") {
        hdf5Structure <- .force.eval(hdf5Structure, section)
      }
      return(hdf5Structure@data[[section]])  
    } else {
      warning(paste("no entry with name '", section, "' found", sep=''))
    }
  })

# Forces evaluation of an entry.
# If the section is still a closure, it evaluates the thunk and returns the
# hdf5structure with that group evaluated. At one point this function was public
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
      warning(paste("no entry with name '", section, "' found", sep=''))  
    }
  })

# Returns the entries in the object.
# Simply returns the name of the entries in the list
setGeneric('entries',
  function(object) {
    standardGeneric('entries')
  })

setMethod('entries', signature(object='hdf5Structure'),
  function(object) {
    return(names(object@data))
})

# Updates or creates a new dataset
# This function wraps `h5write` and behaves the same
setGeneric('write.dataset',
  function(object, path, obj) {
    standardGeneric('write.dataset')
  })

setMethod('write.dataset', signature(object='hdf5Structure', path='character',
                                     obj='ANY'),
  function(object, path, obj) {
    h5write(obj, object@reader@file, path)
  })

# Custom show function
# This method is invoked when print is called on an hdf5structure object or when
# you use the REPL. Shows the filename and the groups that are in the file
setMethod("show", signature(object='hdf5Structure'),
  function(object) {
    file <- paste("file:", object@reader@file)
    entries <- paste("entries:", paste(entries(object), collapse=", "))
    cat(file, entries, sep="\n")
  })
