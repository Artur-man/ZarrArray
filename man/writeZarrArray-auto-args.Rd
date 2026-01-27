\name{writeZarrArray-auto-args}

\alias{writeZarrArray-auto-args}
\alias{writeZarrArray_auto_args}

\alias{get_writeZarrArray_dump_dir}
\alias{set_writeZarrArray_dump_dir}
\alias{get_writeZarrArray_auto_path}
\alias{get_writeZarrArray_chunk_maxlen}
\alias{set_writeZarrArray_chunk_maxlen}
\alias{get_writeZarrArray_chunk_shape}
\alias{set_writeZarrArray_chunk_shape}
\alias{get_writeZarrArray_auto_chunkdim}

\title{Control writeZarrArray's automatic argument values}

\description{
  \code{get_writeZarrArray_auto_path()} and
  \code{get_writeZarrArray_auto_chunkdim()} are used internally by
  \code{\link{writeZarrArray}()} and \code{\link{ZarrRealizationSink}()}
  to obtain \emph{automatic values} for their \code{zarr_array_path}
  and \code{chunkdim} arguments when those arguments are not supplied.
}

\usage{
## Used internally to obtain "automatic values" for arguments
## 'zarr_array_path' and 'chunkdim':
get_writeZarrArray_auto_path()
get_writeZarrArray_auto_chunkdim(dim)

## Control the value returned by get_writeZarrArray_auto_path():
set_writeZarrArray_dump_dir(dir)

## Control the value returned by get_writeZarrArray_auto_chunkdim():
set_writeZarrArray_chunk_maxlen(maxlen=1000000L)
set_writeZarrArray_chunk_shape(shape="scale")

## The "get" functions that correspond to the "set" functions above:
get_writeZarrArray_dump_dir()
get_writeZarrArray_chunk_maxlen()
get_writeZarrArray_chunk_shape()
}

\arguments{
  \item{dim}{
    The dimensions (as an integer vector) of the array-like object to be
    realized to disk in Zarr format.
  }
  \item{dir}{
    The path (as a single string) to the "realization dump", that is, to
    the directory where realization of array-like objects in Zarr format
    should happen by default.
    If \code{dir} is missing, then the "realization dump" is set
    back to its default which is some directory under \code{tempdir()}.
  }
  \item{maxlen}{
    The maximum length (i.e. number of array elements) of the physical
    chunks to use by default when realizing an array-like object to disk
    in Zarr format.
  }
  \item{shape}{
    A string specifying the shape of the physical chunks to use by
    default when realizing an array-like object to disk in Zarr format.
    See \code{\link[DelayedArray]{makeCappedVolumeBox}} in the
    \pkg{DelayedArray} package for the supported shapes.
  }
}

\details{
  Here's how \code{\link{writeZarrArray}()} obtains its \emph{automatic
  argument values}:
  \itemize{
    \item The automatic value for \code{zarr_array_path} is obtained
          with \code{get_writeZarrArray_auto_path()}.
    \item The automatic value for \code{chunkdim} is obtained with
          \code{chunkdim(x)} where \code{x} is the array-like object
          passed to \code{\link{writeZarrArray}}.
          If \code{chunkdim(x)} returns \code{NULL} (which can happen if
          \code{x} is an in-memory object or if the dimensions of its
          physical chunks cannot be determined), then \code{chunkdim}
          is obtained with \code{get_writeZarrArray_auto_chunkdim(dim(x))}.
  }

  The \pkg{ZarrArray} package provides a set of utility functions to
  control the values returned by \code{get_writeZarrArray_auto_path()}
  and \code{get_writeZarrArray_auto_chunkdim()}:
  \itemize{
    \item The value returned by \code{get_writeZarrArray_auto_path()}
          is controlled by \code{set_writeZarrArray_dump_dir()}.

    \item The value returned by \code{get_writeZarrArray_auto_chunkdim()}
          is controlled by \code{set_writeZarrArray_chunk_maxlen()} and
          \code{set_writeZarrArray_chunk_shape()}.
  }

  In other words, the \code{set_writeZarrArray_*()} utility functions
  provide some control over the behavior of \code{\link{writeZarrArray}()}
  and \code{\link{ZarrRealizationSink}()} when only their first argument
  is specified, like in:
  \preformatted{    a <- array(101:160, dim=5:3)
    A <- writeZarrArray(a)}
  or in:
  \preformatted{    ZarrRealizationSink(dim(a))}

  Consequently, they also provide some control over the behavior of
  coercion of an arbitrary array-like object to \link{_ZarrArray} (i.e.
  on \code{as(a, "_ZarrArray")}), since this coercion simply calls
  \code{\link{writeZarrArray}()} on the supplied object.
}

\value{
  COMING SOON...
}

\seealso{
  \itemize{
    \item \code{\link{writeZarrArray}} for writing an array-like object
          to disk in Zarr format.

    \item \link{_ZarrArray} objects.

    \item \code{\link[DelayedArray]{makeCappedVolumeBox}} in the
          \pkg{DelayedArray} package.
  }
}

\examples{
a <- array(101:160, dim=5:3)

get_writeZarrArray_dump_dir()  # default "Zarr realization dump"
A1 <- writeZarrArray(a)
path(A1)

## Take control of where writeZarrArray() should write Zarr datasets
## by default:
my_zarr_dump <- file.path(tempdir(), "my_zarr_dump")
set_writeZarrArray_dump_dir(my_zarr_dump)
A2 <- writeZarrArray(a)
path(A2)

m <- matrix(101:140, ncol=8)
M <- as(m, "_ZarrArray")  # equivalent to writeZarrArray(m)
path(M)

## Set "Zarr realization dump" to the default:
set_writeZarrArray_dump_dir()
}
\keyword{utilities}
