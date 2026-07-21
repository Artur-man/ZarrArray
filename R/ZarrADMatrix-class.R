### =========================================================================
### ZarrADMatrix objects
### -------------------------------------------------------------------------
###

setClass("ZarrADMatrix",
         contains="DelayedMatrix",
         representation(seed="ZarrADMatrixSeed")
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

setMethod("DelayedArray", "ZarrADMatrixSeed",
          function(seed) new_DelayedArray(seed, Class="ZarrADMatrix")
)

### Works directly on an ZarrADMatrixSeed derivative, in which case it must
### be called with a single argument.
ZarrADMatrix <- function(filepath, layer=NULL)
{
  if (is(filepath, "ZarrADMatrixSeed")) {
    if (!is.null(layer))
      stop(wmsg("ZarrADMatrix() must be called with a single argument ",
                "when passed an ZarrADMatrixSeed derivative"))
    seed <- filepath
  } else {
    seed <- ZarrADMatrixSeed(filepath, layer=layer)
  }
  DelayedArray(seed)
}