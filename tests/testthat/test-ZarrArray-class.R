
test_that("ZarrArray()", {
    zarr_path <- system.file(package="Rarr", "extdata",
                             "zarr_examples", "column-first", "int32.zarr")
    A <- ZarrArray(zarr_path)
    expect_true(is(A, "ZarrArray"))
    expect_true(is(A, "DelayedArray"))
    expect_identical(tools::file_path_as_absolute(path(A)), zarr_path)
    expect_identical(dim(A), c(30L, 20L, 10L))
    expect_identical(type(A), "integer")
    expect_identical(chunkdim(A), c(10L, 10L, 5L))

    seed <- ZarrArraySeed(zarr_path)
    expect_identical(ZarrArray(seed), A)
    expect_identical(DelayedArray(seed), A)
    expect_identical(matrixClass(A), "ZarrMatrix")
    expect_identical(as(A, "ZarrMatrix"), A)  # no-op

    A2 <- writeZarrArray(sqrt(t(A[ , , 1]) + 1), chunkdim=c(5, 8))
    expect_true(is(A2, "ZarrMatrix"))
    expect_true(is(A2, "DelayedMatrix"))
    expect_identical(dim(A2), c(20L, 30L))
    expect_identical(type(A2), "double")
    expect_identical(chunkdim(A2), c(5L, 8L))

    expect_identical(as(A2, "ZarrArray"), A2)  # no-op
})

