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

