
test_that("writeZarrArray()", {
    set.seed(123)

    ## --- 2D arrays ---

    m1 <- matrix(runif(2e5), ncol=200)  # type() is "double"

    chunkdim <- c(50L, 50L)
    M <- writeZarrArray(m1, chunkdim=chunkdim)
    expect_true(is(M, "_ZarrMatrix"))
    expect_identical(dim(M), dim(m1))
    expect_identical(type(M), type(m1))
    expect_identical(chunkdim(M), chunkdim)
    expect_identical(as.array(M), m1)
    expect_identical(extract_array(M, list(15:11, NULL)), m1[15:11, ])
    expect_identical(extract_array(M, list(integer(0), 5:9)), m1[0, 5:9])

    chunkdim <- c(500L, 60L)
    M <- writeZarrArray(m1, chunkdim=chunkdim)
    expect_true(is(M, "_ZarrMatrix"))
    expect_identical(dim(M), dim(m1))
    expect_identical(type(M), type(m1))
    expect_identical(chunkdim(M), chunkdim)
    expect_identical(as.array(M), m1)
    expect_identical(extract_array(M, list(15:11, NULL)), m1[15:11, ])
    expect_identical(extract_array(M, list(integer(0), 5:9)), m1[0, 5:9])

    data <- strrep(letters, sample(0:8, 26, replace=TRUE))
    m2 <- matrix(data, ncol=2)  # type() is "character"

    chunkdim <- c(13L, 2L)
    M <- writeZarrArray(m2, chunkdim=chunkdim)
    expect_true(is(M, "_ZarrMatrix"))
    expect_identical(dim(M), dim(m2))
    expect_identical(type(M), type(m2))
    expect_identical(chunkdim(M), chunkdim)
    expect_identical(as.array(M), m2)
    index <- list(c(13:8, 9L), NULL)
    expect_identical(extract_array(M, index), m2[c(13:8, 9L), ])
    index <- list(5:9, integer(0))
    expect_identical(extract_array(M, index), m2[5:9, 0])

    ## --- 1D array ---

    a1 <- array(11:-11, dim=23)  # type() is "integer"

    chunkdim <- dim(a1)
    A <- writeZarrArray(a1, chunkdim=chunkdim)
    expect_true(is(A, "_ZarrArray"))
    expect_identical(dim(A), dim(a1))
    expect_identical(type(A), type(a1))
    expect_identical(chunkdim(A), chunkdim)
    expect_identical(as.array(A), a1)
    expect_identical(extract_array(A, list(15:11)), a1[15:11])
    expect_identical(extract_array(A, list(integer(0))), array(0L, dim=0))
})

