
.onLoad <- function(libname, pkgname)
{
    if (!ZarrArray_option_is_set("realization.dump.dir"))
        set_writeZarrArray_dump_dir()
    if (!ZarrArray_option_is_set("realization.chunk.maxlen"))
        set_writeZarrArray_chunk_maxlen()
    if (!ZarrArray_option_is_set("realization.chunk.shape"))
        set_writeZarrArray_chunk_shape()
    #file.create(get_Zarr_dump_logfile())
}

