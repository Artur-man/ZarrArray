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
        zarr_array_path="character",  # path must be absolute

        ## ------------ automatically populated slots ------------
        dim="integer",
        chunkdim="integer"
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
setMethod("path", "_ZarrArraySeed", function(object) object@zarr_array_path)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### dim() getter
###

### Does NOT access the file.
setMethod("dim", "_ZarrArraySeed", function(x) x@dim)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### extract_array()
###

setMethod("extract_array", "_ZarrArraySeed",
    function(x, index)
        read_zarr_array(zarr_array_path=x@zarr_array_path, index=index)
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### chunkdim() getter
###

### Does NOT access the file.
setMethod("chunkdim", "_ZarrArraySeed", function(x) x@chunkdim)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

ZarrArraySeed <- function(zarr_array_path)
{
    ## Normalize path. Can be file path or S3 url.
    zarr_array_path <- Rarr:::.normalize_array_path(zarr_array_path)

    ## Get array dimensions from the metadata.
    metadata <- Rarr::zarr_overview(zarr_array_path, as_data_frame=TRUE)
    dim <- unlist(metadata$dim)
    chunkdim <- unlist(metadata$chunk_dim)

    new2("_ZarrArraySeed", zarr_array_path=zarr_array_path,
                           dim=dim,
                           chunkdim=chunkdim)
}

