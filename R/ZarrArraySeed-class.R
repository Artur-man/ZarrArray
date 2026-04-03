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
        type="character",
        dim="integer",
        chunkdim="integer",
        fill_value="ANY"     # Not used for anything at the moment. Maybe
                             # drop it? Note that the fill_value slot can
                             # be set to NULL if the "fill value" could
                             # not be determined.
    )
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

### TODO


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Getters path(), type(), dim(), and chunkdim()
###
### Note that none of these getters actually needs to access the disk.
###

setMethod("path", "_ZarrArraySeed", function(object) object@zarr_path)
setMethod("type", "_ZarrArraySeed", function(x) x@type)
setMethod("dim", "_ZarrArraySeed", function(x) x@dim)
setMethod("chunkdim", "_ZarrArraySeed", function(x) x@chunkdim)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### extract_array()
###

setMethod("extract_array", "_ZarrArraySeed",
    function(x, index)
    {
        ans <- Rarr::read_zarr_array(x@zarr_path, index)
        ## Temporary fix.
        ## See https://github.com/Huber-group-EMBL/Rarr/issues/137
        if (typeof(ans) != x@type)
            storage.mode(ans) <- x@type
        ans
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

.normarg_zarr_path <- function(zarr_path)
{
    if (!isSingleString(zarr_path))
        stop(wmsg("'zarr_path' must be a single string"))
    if (!dir.exists(zarr_path)) {
        msg <- "the supplied path must be the path to an existing directory"
        if (file.exists(zarr_path))
            msg <- paste0(msg, ", not a file")
        stop(wmsg(msg))
    }
    Rarr:::.normalize_array_path(zarr_path)
}

.extract_Rtype_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata), !is.null(names(metadata)))
    zarrtype2Rtype(metadata$datatype$base_type)
}

### Where to find the chunk dim information depends on whether the
### metadata comes from a Zarr v2 or v3 dataset, hence the gymnastics
### below. Note that this could be avoided by modifying get_zarr_metadata()
### so that it **always** return the metadata in Zarr v3 format.
### See IMPORTANT NOTE in R/utils.R.
.extract_chunkdim_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata), !is.null(names(metadata)))
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

### Returns a NULL if the "fill value" cannot be determined. But can
### this ever happen? Also can be of the wrong type: see
### https://github.com/Huber-group-EMBL/Rarr/issues/137
.extract_fill_value_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata), !is.null(names(metadata)))
    ans <- metadata$fill_value
    if (is.null(ans))
        warning(wmsg("unable to determine the \"fill value\" ",
                     "for this Zarr dataset"))
    ans
}

ZarrArraySeed <- function(zarr_path)
{
    zarr_path <- .normarg_zarr_path(zarr_path)
    metadata <- get_zarr_metadata(zarr_path)
    Rtype <- .extract_Rtype_from_metadata(metadata)
    dim <- as.integer(unlist(metadata$shape), use.names=FALSE)
    chunkdim <- .extract_chunkdim_from_metadata(metadata)
    fill_value <- .extract_fill_value_from_metadata(metadata)
    new2("_ZarrArraySeed", zarr_path=zarr_path, type=Rtype,
                           dim=dim, chunkdim=chunkdim, fill_value=fill_value)
}

