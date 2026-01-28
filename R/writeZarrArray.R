### =========================================================================
### writeZarrArray()
### -------------------------------------------------------------------------
###


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrRealizationSink objects
###
### The ZarrRealizationSink class is a concrete RealizationSink subclass that
### implements a realization sink for Zarr datasets. It must comply with
### the "sink contract". See R/RealizationSink-class.R in the DelayedArray
### package for the details of the "sink contract".
###

### TEMPORARY HACK: We temporarily prefix our class names with an underscore
### to avoid conflicts with the classes defined in the Rarr package!
### TODO: Remove the underscore after the classes in Rarr are gone.
setClass("_ZarrRealizationSink",
    contains="RealizationSink",
    representation(
        ## Slots that support the RealizationSink constructor contract.
        dim="integer",          # Naming this slot "dim" makes dim() work
                                # out of the box.
        type="character",       # Single string.

        ## Other slots.
        zarr_path="character",  # Single string.
        chunkdim="integer"      # An integer vector parallel to the 'dim' slot.
    )
)

setMethod("type", "_ZarrRealizationSink", function(x) x@type)

setMethod("chunkdim", "_ZarrRealizationSink", function(x) x@chunkdim)

.normarg_dim <- function(dim)
{
    if (!is.numeric(dim))
        stop(wmsg("'dim' must be an integer vector"))
    if (length(dim) == 0L)
        stop(wmsg("'dim' cannot be an empty vector"))
    if (!is.integer(dim))
        dim <- as.integer(dim)
    if (S4Vectors:::anyMissingOrOutside(dim, 0L))
        stop(wmsg("'dim' cannot contain negative or NA values"))
    dim
}

.normarg_chunkdim <- function(chunkdim, dim)
{
    if (!(is.numeric(chunkdim) || is.logical(chunkdim) && all(is.na(chunkdim))))
        stop(wmsg("'chunkdim' must be NULL or an integer vector"))
    if (!is.integer(chunkdim))
        chunkdim <- as.integer(chunkdim)
    if (length(chunkdim) != length(dim))
        stop(wmsg("'chunkdim' must be an integer vector of length ",
                  "the number of dimensions of the object to write"))
    if (any(chunkdim < 0L, na.rm=TRUE))
        stop(wmsg("'chunkdim' cannot contain negative values"))
    if (!all(chunkdim <= dim, na.rm=TRUE))
        stop(wmsg("the chunk dimensions specified in 'chunkdim' exceed ",
                  "the dimensions of the object to write"))
    if (any(chunkdim == 0L & dim != 0L, na.rm=TRUE))
        stop(wmsg("'chunkdim' must contain nonzero values unless ",
                  "the zero values correspond to dimensions in the ",
                  "object to write that are also zero"))
    na_idx <- which(is.na(chunkdim))
    chunkdim[na_idx] <- dim[na_idx]
    if (prod(chunkdim) > .Machine$integer.max)
        stop(wmsg("The chunk dimensions in 'chunkdim' are too big. The ",
                  "product of the chunk dimensions should always be <= ",
                  ".Machine$integer.max"))
    chunkdim
}

### According to the "sink contract", the first 3 arguments must be 'dim',
### 'dimnames', and 'type'.
### Based on Rarr::create_empty_zarr_array() which only supports creation
### of Zarr v2 datasets at the moment (Rarr 1.11.24).
ZarrRealizationSink <- function(dim, dimnames=NULL, type="double",
                                zarr_path=NULL, chunkdim=NULL, nchar=NULL)
{
    dim <- .normarg_dim(dim)
    if (!is.null(dimnames))
        warning(wmsg("'dimnames' is not supported and will be ignored"),
                immediate.=TRUE)
    if (is.null(zarr_path)) {
        zarr_path <- get_writeZarrArray_auto_path()
    } else {
        zarr_path <- Rarr:::.normalize_array_path(zarr_path)
    }
    if (is.null(chunkdim)) {
        chunkdim <- get_writeZarrArray_auto_chunkdim(dim)
    } else {
        chunkdim <- .normarg_chunkdim(chunkdim, dim)
    }
    Rarr::create_empty_zarr_array(zarr_path, dim, chunkdim, type, nchar=nchar)

    new2("_ZarrRealizationSink", dim=dim, type=type,
                                 zarr_path=zarr_path, chunkdim=chunkdim)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Writing data to a ZarrRealizationSink object
###

setMethod("write_block", "_ZarrRealizationSink",
    function(sink, viewport, block)
    {
        if (!is.array(block))
            block <- as.array(block)
        starts <- start(viewport) - 1L
        index <- lapply(width(viewport), seq_len)
        # nolint next: undesirable_function_linter.
        index <- mapply(FUN="+", starts, index, SIMPLIFY=FALSE)
        Rarr::update_zarr_array(sink@zarr_path, x=block, index=index)
        sink
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercing a ZarrRealizationSink object
###

setAs("_ZarrRealizationSink", "_ZarrArraySeed",
    function(from) ZarrArraySeed(from@zarr_path)
)

setAs("_ZarrRealizationSink", "_ZarrArray",
    function(from) DelayedArray(as(from, "_ZarrArraySeed"))
)

setAs("_ZarrRealizationSink", "DelayedArray",
    function(from) DelayedArray(as(from, "_ZarrArraySeed"))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### writeZarrArray()
###

### Does NOT write dimnames(x) to disk at the moment!
### TODO: writeZarrArray() needs to write the array dimnames to disk.
### Does the Zarr format support this?
writeZarrArray <- function(x, zarr_path=NULL, chunkdim=NULL, nchar=NULL,
                              verbose=NA)
{
    x_dim <- dim(x)
    if (is.null(x_dim))
        stop(wmsg("'x' must be an array-like object ",
                  "(i.e. it must have dimensions)"))
    if (is.null(nchar) && type(x) == "character") {
        ## +1 to add NUL terminator.
        nchar <- max(base::nchar(x)) + 1L
    }
    verbose <- DelayedArray:::normarg_verbose(verbose)
    if (is.null(chunkdim))
        chunkdim <- chunkdim(x)
    sink <- ZarrRealizationSink(x_dim, NULL, type(x),
                                zarr_path=zarr_path, chunkdim=chunkdim,
                                nchar=nchar)
    sink <- BLOCK_write_to_sink(sink, x, verbose=verbose)
    as(sink, "_ZarrArray")
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion to ZarrArray
###
### The methods below write the array data to disk. Note that coercion from
### ZarrRealizationSink to ZarrArray is already taken care of by the specific
### method above and doesn't write anything to disk. So coercing to ZarrArray
### in general writes the array data to disk *except* when the object to
### coerce is a ZarrRealizationSink object.
###

### Writes to the ZarrArray realization dump by default.
### Unfortunately, the dimnames are NOT propagated because writeZarrArray()
### does NOT propagate them either. See TODO above.
.as_ZarrArray <- function(from) writeZarrArray(from)

setAs("ANY", "_ZarrArray", .as_ZarrArray)

### Automatic coercion methods from DelayedArray to ZarrArray and from
### DelayedMatrix to ZarrMatrix silently return broken objects (unfortunately
### these dummy automatic coercion methods don't bother to validate the object
### they return). So we overwrite them.
setAs("DelayedArray", "_ZarrArray", .as_ZarrArray)
setAs("DelayedMatrix", "_ZarrMatrix", .as_ZarrArray)

