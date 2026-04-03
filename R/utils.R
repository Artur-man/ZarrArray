### =========================================================================
### Some low-level utilities
### -------------------------------------------------------------------------
###
### Nothing in this file is exported.
###


trim_trailing_slashes <- function(x)
{
    sub("/*$", "", x)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get_zarr_format()
### get_zarr_metadata()
###

.ZARR_V2_METADATA_FILE <- ".zarray"
.ZARR_V3_METADATA_FILE <- "zarr.json"

.get_zarr_metadata_file <- function(zarr_path)
{
    stopifnot(S4Vectors:::has_suffix(zarr_path, "/"))
    metadata_files <- c(.ZARR_V2_METADATA_FILE, .ZARR_V3_METADATA_FILE)
    ok <- Rarr:::.file_or_blob_exists(zarr_path, NULL, metadata_files)
    if (!any(ok))
        stop(wmsg("No Zarr metadata file ('", .ZARR_V2_METADATA_FILE, "' ",
                  "or '", .ZARR_V3_METADATA_FILE, "') found in: ", zarr_path),
             "\n  ",
             wmsg("Are you sure this is the path to a Zarr dataset?"))
    if (all(ok))
        stop(wmsg("Invalid Zarr dataset at: ", zarr_path),
             "\n  ",
             wmsg("Directory contains Zarr metadata files ",
                   "'", .ZARR_V2_METADATA_FILE, "' and ",
                   "'", .ZARR_V3_METADATA_FILE, "'. Should contain one ",
                   "or the other, but not both."))
    names(ok)[ok]
}

get_zarr_format <- function(zarr_path)
{
    stopifnot(isSingleString(zarr_path))
    metadata_file <- .get_zarr_metadata_file(zarr_path)
    if (metadata_file == .ZARR_V3_METADATA_FILE) 3L else 2L
}

### Returns the metadata in a named list.
### IMPORTANT NOTE: The exact components of the named list and their names
### depend on the Zarr version (a.k.a. Zarr format) of the Zarr dataset,
### which can be 2 or 3. However, the Rarr package has
### Rarr:::.convert_metadata_version() for converting the metadata
### to a given version. This is something that we could use in
### get_zarr_metadata() to always return the metadata in the same
### form e.g. in the form that corresponds to Zarr v3.
get_zarr_metadata <- function(zarr_path)
{
    stopifnot(isSingleString(zarr_path))
    metadata_file <- .get_zarr_metadata_file(zarr_path)
    Rarr:::.read_array_metadata(zarr_path, metadata_file)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrtype2Rtype()
###

zarrtype2Rtype <- function(base_type)
{
    stopifnot(isSingleString(base_type))
    switch(base_type, bool="logical",
                      int=, uint="integer",
                      float="double",
                      #complex="complex",
                      string=, unicode="character",
                      stop(wmsg("unreocgnized Zarr base type: ", base_type)))
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### compute_max_string_size()
###

### Copied and adapted from HDF5Array/R/h5utils.R
compute_max_string_size <- function(x, keepNA=FALSE)
{
    ## We want this to work on any array-like object, not just ordinary
    ## arrays, so we must use type() instead of is.character().
    if (type(x) != "character")
        return(NULL)
    if (length(x) == 0L)
        return(0L)
    ## Calling nchar() on 'x' will trigger block processing if 'x' is a
    ## DelayedArray object, so it could take a while.
    max(nchar(x, type="bytes", keepNA=keepNA))
}

