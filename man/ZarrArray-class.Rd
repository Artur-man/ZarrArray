\name{ZarrArray-class}
\docType{class}

\alias{class:_ZarrArray}
\alias{_ZarrArray-class}
\alias{_ZarrArray}
\alias{ZarrArray}

\alias{DelayedArray,_ZarrArraySeed-method}

\alias{class:_ZarrMatrix}
\alias{_ZarrMatrix-class}
\alias{_ZarrMatrix}
\alias{ZarrMatrix}

\alias{matrixClass,_ZarrArray-method}
\alias{coerce,_ZarrArray,_ZarrMatrix-method}
\alias{coerce,_ZarrMatrix,_ZarrArray-method}

\title{Zarr datasets as DelayedArray objects}

\description{
  The _ZarrArray class is a \link[DelayedArray]{DelayedArray} extension
  for representing and operating on a Zarr dataset.

  All the operations available for \link[DelayedArray]{DelayedArray}
  objects work on _ZarrArray objects.

  IMPORTANT NOTE: The names of the classes defined in the \pkg{ZarrArray}
  package are \emph{temporarily} prefixed with an underscore to avoid
  conflicts with the classes that are currently defined in the \pkg{Rarr}
  package. This prefix will be dropped in the very near future, once the
  classes in \pkg{Rarr} are removed.
}

\usage{
## Constructor function:
ZarrArray(zarr_path)
}

\arguments{
  \item{zarr_path}{
    The path (as a single string) to the Zarr dataset.
  }
}

\value{
  A _ZarrArray (or _ZarrMatrix) object. (Note that _ZarrMatrix extends
  _ZarrArray.)
}

\seealso{
  \itemize{
    \item \link[DelayedArray]{DelayedArray} objects in the \pkg{DelayedArray}
          package.

    \item \code{\link{writeZarrArray}} for writing an array-like object
          to disk in Zarr format.

    \item The \link{_ZarrArraySeed} helper class.
  }
}

\examples{
zarr_path <- system.file(package="Rarr", "extdata",
                         "zarr_examples", "column-first", "int32.zarr")
A <- ZarrArray(zarr_path)
A  # 3D _ZarrArray object

path(A)
dim(A)
type(A)
chunkdim(A)

aperm(A)  # multidimensional transposition
chunkdim(aperm(A))

A[ , , 1]
log1p(t(A[ , , 1]))
rowSums(log1p(t(A[ , , 1])))

## Sanity check:
stopifnot(
  identical(dim(aperm(A)), rev(dim(A))),
  identical(chunkdim(aperm(A)), rev(chunkdim(A))),
  identical(rowSums(log1p(t(A[ , , 1]))),
            rowSums(log1p(t(as.array(A)[ , , 1]))))
)
}
\keyword{classes}
\keyword{methods}
