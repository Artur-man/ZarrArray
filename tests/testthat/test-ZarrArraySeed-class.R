
test_that("ZarrArraySeed() works on (most) Zarr examples in Rarr", {
    zarr_examples <- system.file(package="Rarr", "extdata", "zarr_examples")
    dirs <- list.dirs(zarr_examples, recursive=FALSE)
    dirs <- dirs[!(basename(dirs) %in% c("metadata", "structured"))]
    ## Some Zarr datasets are not supported yet. For example
    ## Rarr::zarr_overview() fails on <zarr_examples>/row-first/string_v3.zarr
    ## and <zarr_examples>/column-first/string_v3.zarr at the moment, with:
    ##   Error: Only base data types (not extensions) are supported for
    ##   Zarr v3 arrays for now
    EXCLUDE_LIST <- c("string_v3.zarr", "Unicode_v3.zarr")
    for (dir in dirs) {
        zarr_paths <- list.dirs(dir, recursive=FALSE)
        zarr_paths <- zarr_paths[!(basename(zarr_paths) %in% EXCLUDE_LIST)]
        for (zarr_path in zarr_paths) {
            seed <- ZarrArraySeed(zarr_path)
            path(seed)
            dim(seed)
            type(seed)
            chunkdim(seed)
        }
    }
})

