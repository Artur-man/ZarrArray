### =========================================================================
### ZarrArray objects
### -------------------------------------------------------------------------
###
### Note that we could just wrap a ZarrArraySeed object in a DelayedArray
### object to represent and manipulate a Zarr dataset as a DelayedArray
### object. So, strictly speaking, we don't really need the ZarrArray and
### ZarrMatrix classes. However, we define these classes mostly for cosmetic
### reasons, that is, to hide the DelayedArray and DelayedMatrix classes
### from the user. So the user will see and manipulate ZarrArray and
### ZarrMatrix objects instead of DelayedArray and DelayedMatrix objects.
###


### TEMPORARY HACK: We temporarily prefix our class names with an underscore
### to avoid conflicts with the classes defined in the Rarr package!
### TODO: Remove the underscore after the classes in Rarr are gone.
setClass("_ZarrArray",
    contains="DelayedArray",
    slots=c(seed="_ZarrArraySeed")
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

setMethod("DelayedArray", "_ZarrArraySeed",
    function(seed) new_DelayedArray(seed, Class="_ZarrArray")
)

### Can take a ZarrArraySeed object.
ZarrArray <- function(zarr_path)
{
    if (is(zarr_path, "_ZarrArraySeed")) {
        seed <- zarr_path
    } else {
        seed <- ZarrArraySeed(zarr_path)
    }
    DelayedArray(seed)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrMatrix objects
###

setClass("_ZarrMatrix", contains=c("_ZarrArray", "DelayedMatrix"))

### Required for DelayedArray internal business.
setMethod("matrixClass", "_ZarrArray", function(x) "_ZarrMatrix")

### Automatic coercion method from ZarrArray to ZarrMatrix silently returns
### a broken object (unfortunately these dummy automatic coercion methods
### don't bother to validate the object they return). So we overwrite it.
setAs("_ZarrArray", "_ZarrMatrix", function(from) new("_ZarrArray", from))

### The user should not be able to degrade a ZarrMatrix object to
### a ZarrArray object so 'as(x, "ZarrArray", strict=TRUE)' should
### fail or be a no-op when 'x' is a ZarrMatrix object. Making this
### coercion a no-op seems to be the easiest (and safest) way to go.
setAs("_ZarrMatrix", "_ZarrArray", function(from) from)  # no-op

