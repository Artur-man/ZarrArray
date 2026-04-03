
test_that("ZarrRealizationSink()", {
    for (zarr_version in 3:2) {
        sink <- ZarrRealizationSink(c(85, 20, 300), zarr_version=zarr_version)
        expect_true(is(sink, "_ZarrRealizationSink"))
        expect_true(is(sink, "RealizationSink"))
        version <- ZarrArray:::get_zarr_format(paste0(sink@zarr_path, "/"))
        expect_identical(version, zarr_version)
        seed <- as(sink, "_ZarrArraySeed")
        expect_true(is(seed, "_ZarrArraySeed"))
        expect_identical(dim(seed), c(85L, 20L, 300L))
    }

    expect_error(ZarrRealizationSink(letters))
    expect_error(ZarrRealizationSink(integer(0)))
    expect_error(ZarrRealizationSink(c(10, -1)))
    expect_error(ZarrRealizationSink(c(10, NA)))
    expect_error(ZarrRealizationSink(c(85, 90), chunkdim=c(50, 50, 50)))
    expect_error(ZarrRealizationSink(c(85, 20, 300), chunkdim=c(50, 50, 50)))
    expect_error(ZarrRealizationSink(c(85, 20, 300), chunkdim=c(50, 0, 50)))
})

test_that("ZarrRealizationSink methods", {
    sink <- ZarrRealizationSink(c(85, 20, 300), type="integer",
                                chunkdim=c(10, 10, 50))
    expect_identical(type(sink), "integer")
    expect_identical(chunkdim(sink), c(10L, 10L, 50L))

    sink <- ZarrRealizationSink(c(85, 20, 300), chunkdim=c(50, NA, 50))
    expect_identical(chunkdim(sink), c(50L, 20L, 50L))

    sink <- ZarrRealizationSink(c(85, 20, 300), chunkdim=c(NA, NA, NA))
    expect_identical(chunkdim(sink), c(85L, 20L, 300L))
})

.check_written_ZarrArray <-
    function(object, expected_class, expected_format, expected_chunkdim, a)
{
    expect_true(is(object, expected_class))
    expect_identical(ZarrArray:::get_zarr_format(path(object)), expected_format)
    expect_identical(chunkdim(object), expected_chunkdim)
    expect_identical(dim(object), dim(a))
    expect_identical(type(object), type(a))
    expect_identical(as.array(object), a)
}

test_that("writeZarrArray()", {
    for (zarr_version in 3:2) {
        set.seed(123)

        ## --- 3D array ---

        ## type() is "integer"
        a3 <- array(c(5:-5, NA, 13:1200), dim=c(4, 100, 3))

        chunkdims <- list(dim(a3), c(2L, 20L, 3L), c(1L, 10L, 1L))
        for (chunkdim in chunkdims) {
            A <- writeZarrArray(a3, chunkdim=chunkdim,
                                zarr_version=zarr_version)
            .check_written_ZarrArray(A, "_ZarrArray",
                                     zarr_version, chunkdim, a3)
            index <- list(1L, 15:11, NULL)
            expect_identical(extract_array(A, index),
                             a3[1, 15:11, , drop=FALSE])
            index <- list(NULL, 15:11, NULL)
            expect_identical(extract_array(A, index),
                             a3[ , 15:11, ])
        }

        ## --- 2D arrays ---

        ## type() is "double"
        m1 <- matrix(runif(2e5), ncol=200)
        m1[1, 3:6] <- c(NA, NaN, Inf, -Inf)

        chunkdim <- c(50L, 50L)
        M <- writeZarrArray(m1, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "_ZarrMatrix", zarr_version, chunkdim, m1)
        index <- list(15:11, NULL)
        expect_identical(extract_array(M, index), m1[15:11, ])
        index <- list(integer(0), 5:9)
        expect_identical(extract_array(M, index), m1[0, 5:9])

        chunkdim <- c(500L, 60L)
        M <- writeZarrArray(m1, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "_ZarrMatrix", zarr_version, chunkdim, m1)
        index <- list(15:11, NULL)
        expect_identical(extract_array(M, index), m1[15:11, ])
        index <- list(integer(0), 5:9)
        expect_identical(extract_array(M, index), m1[0, 5:9])

        ## type() is "character"
        # Note that NAs in Zarr datasets of type "character" are causing
        # problems at the moment. See
        # https://github.com/Huber-group-EMBL/Rarr/issues/138
        #data <- c(strrep(letters, sample(0:8, 26, replace=TRUE)), NA)
        #m2 <- matrix(data, ncol=3)
        data <- strrep(letters, sample(0:8, 26, replace=TRUE))
        m2 <- matrix(data, ncol=2)

        chunkdim <- c(4L, 2L)
        M <- writeZarrArray(m2, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "_ZarrMatrix", zarr_version, chunkdim, m2)
        index <- list(c(13:8, 9L), NULL)
        expect_identical(extract_array(M, index), m2[c(13:8, 9L), ])
        index <- list(5:9, integer(0))
        expect_identical(extract_array(M, index), m2[5:9, 0])

        ## type() is "logical"
        # Note that NAs in Zarr datasets of type "character" are not handled
        # properly at the moment. See
        # https://github.com/Huber-group-EMBL/Rarr/issues/138
        #m3 <- matrix(c(TRUE, NA, FALSE, TRUE, TRUE), nrow=11, ncol=60)
        m3 <- matrix(c(TRUE, FALSE, FALSE, TRUE, TRUE), nrow=11, ncol=60)

        chunkdim <- c(2L, 20L)
        M <- writeZarrArray(m3, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "_ZarrMatrix", zarr_version, chunkdim, m3)
        index <- list(9L, c(8:5, 7L))
        expect_identical(extract_array(M, index), m3[9, c(8:5, 7), drop=FALSE])
        index <- list(5:9, c(60, 8:5, 1:10))
        expect_identical(extract_array(M, index), m3[5:9, c(60, 8:5, 1:10)])
        index <- list(5:9, integer(0))
        expect_identical(extract_array(M, index), m3[5:9, 0])

        ## --- 1D array ---

        ## type() is "integer"
        a1 <- array(11:-11, dim=23)

        chunkdims <- list(dim(a1), 10L, 1L)
        for (chunkdim in chunkdims) {
            A <- writeZarrArray(a1, chunkdim=chunkdim,
                                zarr_version=zarr_version)
            .check_written_ZarrArray(A, "_ZarrArray",
                                     zarr_version, chunkdim, a1)
            index <- list(15:11)
            expect_identical(extract_array(A, index), a1[15:11])
            index <- list(integer(0))
            expect_identical(extract_array(A, index), array(0L, dim=0))
        }
    }
})

