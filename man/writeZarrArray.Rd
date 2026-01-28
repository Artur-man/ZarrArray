\name{writeZarrArray}

\alias{class:_ZarrRealizationSink}
\alias{_ZarrRealizationSink-class}
\alias{_ZarrRealizationSink}
\alias{ZarrRealizationSink}

\alias{type,_ZarrRealizationSink-method}
\alias{chunkdim,_ZarrRealizationSink-method}
\alias{write_block,_ZarrRealizationSink-method}

\alias{coerce,_ZarrRealizationSink,_ZarrArraySeed-method}
\alias{coerce,_ZarrRealizationSink,_ZarrArray-method}
\alias{coerce,_ZarrRealizationSink,DelayedArray-method}

\alias{writeZarrArray}

\alias{coerce,ANY,_ZarrArray-method}
\alias{coerce,DelayedArray,_ZarrArray-method}
\alias{coerce,DelayedMatrix,_ZarrMatrix-method}

\title{Write an array-like object to disk in Zarr format}

\description{
  A function for writing an array-like object to disk in Zarr format.
}

\usage{
writeZarrArray(x, zarr_path=NULL, chunkdim=NULL, nchar=NULL, verbose=NA)
}

\arguments{
  \item{x}{
    The array-like object to write to disk in Zarr format.

    If \code{x} is a \link{DelayedArray} object or derivative, then
    \code{writeZarrArray()} \emph{realizes} it on disk, that is, all
    the delayed operations carried by the object are executed on the
    fly while the object is written to disk.
    See "On-disk realization of a DelayedArray object as a Zarr dataset"
    section below for more information.
  }
  \item{zarr_path}{
    \code{NULL} or the path (as a single string) to the directory where
    to write the data in Zarr format.
    If \code{NULL}, then \code{writeZarrArray()} will obtain this path
    by calling \code{\link{get_writeZarrArray_auto_path}()} internally.
    See \code{?\link{writeZarrArray_auto_args}} for more information.
  }
  \item{chunkdim}{
    The dimensions of the physical chunks to use when writing the data
    to disk. See \code{?\link{writeZarrArray_auto_args}} for how this is
    automatically determined when \code{chunkdim} is set to \code{NULL}.
  }
  \item{nchar}{
    When \code{x} is of type \code{character}, this argument
    specifies the maximum length of the stored strings. By default
    \code{writeZarrArray()} will use \code{max(nchar(x)) + 1}.
    You can override this by supplying your own value as a single
    positive integer but only if you know what you are doing.
  }
  \item{verbose}{
    Whether block processing progress should be displayed or not.
    If set to \code{NA} (the default), verbosity is controlled
    by \code{DelayedArray:::get_verbose_block_processing()}.
    Setting \code{verbose} to \code{TRUE} or \code{FALSE} overrides this.
  }
}

\details{
  Please note that, depending on the size of the data to write to disk
  and the performance of the disk, \code{writeZarrArray()} can take a
  long time to complete. Use \code{verbose=TRUE} to see its progress.
}

\value{
  A \link{_ZarrArray} object that points to the newly written Zarr dataset
  on disk.

  IMPORTANT NOTE: The dimnames on \code{x} are not propagated to the returned
  \link{_ZarrArray} object at the moment! This is a temporary situation
  that will be addressed as soon as possible in future versions of the
  \pkg{ZarrArray} package.
}

\section{On-disk realization of a DelayedArray object as a Zarr dataset}{
  When passed a \link{DelayedArray} object, \code{writeZarrArray()}
  \emph{realizes} it on disk, that is, all the delayed operations carried
  by the object are executed on the fly while the object is written to disk.
  This uses a block-processing strategy so that the full object is not
  realized at once in memory. Instead the object is processed block by block
  i.e. the blocks are realized in memory and written to disk one at a time.

  In other words, \code{writeZarrArray(x, ...)} is semantically equivalent
  to \code{writeZarrArray(as.array(x), ...)}, except that \code{as.array(x)}
  is not called because this would realize the full object at once in memory.

  See \code{?\link{DelayedArray}} for general information about
  \link{DelayedArray} objects.
}

\seealso{
  \itemize{
    \item \link{writeZarrArray_auto_args} to control \code{writeZarrArray}'s
    \emph{automatic argument values} like \code{zarr_path} and \code{chunkdim}.

    \item \link{_ZarrArray} objects.
  }
}

\examples{
## --- Write an ordinary matrix to disk in Zarr format ---

m0 <- matrix(runif(180, min=-1), ncol=9)

path <- tempfile(fileext=".zarr")
M1 <- writeZarrArray(m0, path)
M1  # _ZarrMatrix object

path(M1)
chunkdim(M1)

as(m0, "_ZarrArray")  # equivalent to writeZarrArray(m0)

## --- Write a DelayedArray object to disk in Zarr format ---

M2 <- log(t(DelayedArray(m0)) + 1)  # DelayedMatrix object

M3 <- writeZarrArray(M2)
M3  # _ZarrMatrix object

as(M2, "_ZarrArray")  # equivalent to writeZarrArray(M2)
}
\keyword{methods}
