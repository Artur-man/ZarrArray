### =========================================================================
### ZarrArraySeed objects
### -------------------------------------------------------------------------


### TEMPORARY HACK: We temporarily prefix our class names with an underscore
### to avoid conflicts with the classes defined in the Rarr package!
### TODO: Remove the underscore after the classes in Rarr are gone.
setClass("_ZarrArraySeed",
    contains=c("Array", "OutOfMemoryObject"),
    slots=c(
        ## ----------------- user supplied slots -----------------
        zarr_path="character",  # Path must be absolute.

        ## ------------ automatically populated slots ------------
        dim="integer",
        chunkdim="integer",
        fill_value="ANY"        # Only used to infer the object type()
                                # at the moment. Can be set to NULL if
                                # the "fill value" could not be determined.
    )
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

### TODO


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### path() getter
###

### Does NOT access the file.
setMethod("path", "_ZarrArraySeed", function(object) object@zarr_path)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### dim() getter
###

### Does NOT access the file.
setMethod("dim", "_ZarrArraySeed", function(x) x@dim)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### type() getter
###

### Does NOT access the file (if 'x@fill_value' is not NULL).
setMethod("type", "_ZarrArraySeed",
    function(x)
    {
        ## If "fill value" could not be determined, use default type()
        ## method defined in the S4Arrays package.
        if (is.null(x@fill_value))
            return(callNextMethod())
        type(x@fill_value)
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### extract_array()
###

setMethod("extract_array", "_ZarrArraySeed",
    function(x, index) Rarr::read_zarr_array(x@zarr_path, index)
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### chunkdim() getter
###

### Does NOT access the file.
setMethod("chunkdim", "_ZarrArraySeed", function(x) x@chunkdim)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### .get_metadata() and related
###

.get_metadata_file <- function(zarr_path)
{
    if (!isSingleString(zarr_path))
        stop(wmsg("'zarr_path' must be a single string"))
    if (!dir.exists(zarr_path)) {
        msg <- "the supplied path must be the path to an existing directory"
        if (file.exists(zarr_path))
            msg <- paste0(msg, ", not a file")
        stop(wmsg(msg))
    }
    zarr_path <- Rarr:::.normalize_array_path(zarr_path)
    metadata_files <- Rarr:::.file_or_blob_exists(zarr_path, NULL,
                                                  c(".zarray", "zarr.json"))
    if (!any(metadata_files))
        stop(wmsg("No Zarr metadata file ('.zarray' or 'zarr.json') ",
                  "found in: ", zarr_path),
             "\n  ",
             wmsg("Are you sure this is the path to a Zarr dataset?"))
    if (all(metadata_files))
        stop(wmsg("Invalid Zarr dataset at: ", zarr_path),
             "\n  ",
             wmsg("Directory contains Zarr metadata files '.zarray' ",
                  "and 'zarr.json'. Should contain one or the other, ",
                  "but not both."))
    names(metadata_files)[metadata_files]
}

### Returns the metadata in a named list.
### IMPORTANT NOTE: The exact components of the named list and their names
### depend on the Zarr version (v2 or v3) of the Zarr dataset. However, the
### Rarr package has Rarr:::.convert_metadata_version() for converting
### the metadata to a given version. This is something that we could use
### in .get_metadata() to always return the metadata in the same format e.g.
### in Zarr v3 format.
.get_metadata <- function(zarr_path)
{
    metadata_file <- .get_metadata_file(zarr_path)
    Rarr:::.read_array_metadata(zarr_path, metadata_file)
}

.extract_chunkdim_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata))
    ## Where to find the chunk dim information depends on whether the
    ## metadata comes from a Zarr v2 or v3 dataset, hence the gymnastics
    ## below. Note that this could be avoided by modifying .get_metadata()
    ## above to have it **always** return the metadata in Zarr v3 format.
    ## See IMPORTANT NOTE above.
    chunkdim <- metadata$chunks  # only in Zarr v2
    if (is.null(chunkdim)) {
        chunk_grid <- metadata$chunk_grid  # only in Zarr v3
        if (is.null(chunk_grid))
            stop(wmsg("unable to determine the chunk dimensions ",
                      "for this Zarr dataset"))
        if (!identical(chunk_grid$name, "regular"))
            stop(wmsg("only Zarr datasets with a regular chunk ",
                      "grid are supported at the moment"))
        chunkdim <- chunk_grid$configuration$chunk_shape
        if (is.null(chunkdim))
            stop(wmsg("unable to determine the chunk dimensions ",
                      "for this Zarr dataset"))
    }
    if (!(is.list(chunkdim) || isSingleNumber(chunkdim)))
        stop(wmsg("malformed chunk dim information found ",
                  "in the metadata of this Zarr dataset"))
    chunkdim <- as.integer(unlist(chunkdim, use.names=FALSE))
    chunk_len <- prod(chunkdim)
    if (chunk_len > .Machine$integer.max)
        stop(wmsg("Each physical chunk in this Zarr dataset contains ",
                  chunk_len, " array elements, which is more than what ",
                  "ZarrArraySeed, ZarrArray, or DelayedArray objects ",
                  "can handle."),
             "\n  ",
             wmsg("DelayedArray objects and their derivatives (like ",
                  "ZarrArray objects) can only handle physical chunks ",
                  "made of less than 2^31 array elements each."))
    chunkdim
}

### Returns a NULL if the "fill value" cannot be determined.
### But can this ever happen?
.extract_fill_value_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata))
    ans <- metadata$fill_value
    if (is.null(ans))
        warning(wmsg("unable to determine the \"fill value\" ",
                     "for this Zarr dataset"))
    ans
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

ZarrArraySeed <- function(zarr_path)
{
    metadata <- .get_metadata(zarr_path)
    dim <- as.integer(unlist(metadata$shape), use.names=FALSE)
    chunkdim <- .extract_chunkdim_from_metadata(metadata)
    fill_value <- .extract_fill_value_from_metadata(metadata)  # can be NULL
    new2("_ZarrArraySeed", zarr_path=zarr_path,
                           dim=dim, chunkdim=chunkdim, fill_value=fill_value)
}

