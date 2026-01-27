### =========================================================================
### Handle ZarrArray options
### -------------------------------------------------------------------------
###
### Nothing in this file is exported.
###

### Must return a named list.
.get_ZarrArray_options <- function()
{
    ZarrArray_options <- getOption("ZarrArray")
    if (is.null(ZarrArray_options))
        return(setNames(list(), character(0)))
    if (!is.list(ZarrArray_options) || is.null(names(ZarrArray_options)))
        stop(wmsg("invalid 'getOption(\"ZarrArray\")' ",
                  "(should be a named list)"))
    ZarrArray_options
}

get_ZarrArray_option <- function(name, default=NULL)
{
    stopifnot(isSingleString(name))
    ZarrArray_options <- .get_ZarrArray_options()
    if (name %in% names(ZarrArray_options))
        return(ZarrArray_options[[name]])
    default
}

set_ZarrArray_option <- function(name, value)
{
    stopifnot(isSingleString(name))
    ZarrArray_options <- .get_ZarrArray_options()
    prev_value <- ZarrArray_options[[name]]
    ZarrArray_options[name] <- list(value)
    options(ZarrArray=ZarrArray_options)
    invisible(prev_value)
}

ZarrArray_option_is_set <- function(name)
{
    stopifnot(isSingleString(name))
    ZarrArray_options <- .get_ZarrArray_options()
    name %in% names(ZarrArray_options)
}

