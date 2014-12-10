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
  for (i in 2:length(np@contents$name)) {
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
        return(.access(object, section))
      })))
  }
}

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
  slot(np, "name") <- .name(hd)
  
  names <- slotNames(np)
  names.length <- length(names)
  
  for (i in 3:names.length) {
    # wrap the attributes in function to feign lazy evaluation
    func <- paste("function(eval=T) {
                    return(", ".", names[i], "(hd)", ") }",
                  sep="")
    slot(np, names[i]) <- eval(parse(text=func))
    
    with.param <- paste("function(object) { object@", names[i], " <- ",
                        "object@", names[i], "();", "return(object) }", sep="")
    with.param.name <- paste("with.", names[i], sep="")
    
    get.param <- paste("function(object) { ",
                          "if (typeof(object@", names[i], ") == \"closure\") {",
                            "object <- with.", names[i], "(object)} ; ",
                          "return(object@", names[i], ") }",
                       sep="")
    get.param.name <- paste("get.", names[i], sep="")
    
    # forces evaluation
    setGeneric(with.param.name, eval(parse(text=with.param)))
    setMethod(with.param.name, signature(object="noisyParameters"),
                                         eval(parse(text=with.param)))
    # gets the attribute
    setGeneric(get.param.name, eval(parse(text=get.param)))
    setMethod(get.param.name, signature(object="noisyParameters"),
                                          eval(parse(text=get.param)))
  }
  
  return(np)
}

setGeneric('with.all', function(object) {
  standardGeneric('with.all')
})

setMethod('with.all', signature(object='noisyParameters'),
  function(object) {
    object.new <- object
    slots <- slotNames(object)
    for (i in 3:length(slots)) {
      with <- paste('with.', slots[i], sep="")
      with.func <- eval(parse(text=with))
      object.new <- with.func(object.new)
    }
    return(object.new)
  })

setMethod("show", signature(object='noisyParameters'),
  function(object) {
    slots <- slotNames(object)[3:length(slotNames(object))]
    file <- paste("file:", object@reader@file)
    dataset <- paste("dataset:", object@name)
    groups <- paste("groups:", paste(slots, collapse=", "))
    cat(file, dataset, groups, sep="\n")
  })
