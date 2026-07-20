
test_that("ZarrSparseMatrixSeed objects", {
    for (zarr_version in 3:2) {
        adzarr_basename <- paste0("example_v", zarr_version, ".zarr")
        adzarr_zip <- paste0(adzarr_basename, ".zip")
        adzarr_zip_path <- system.file(package="anndataR", "extdata",
                                       adzarr_zip)
        td <- tempdir()
        unzip(adzarr_zip_path, exdir=td)
        adzarr_path <- file.path(td, adzarr_basename)

        ## Groups "layers/counts" and "X" contain sparse matrices with
        ## the same geometries (100 x 50) and layouts (csr_matrix).
        ## Note that the csr_matrix layout at the Zarr level becomes
        ## CSC in R.

        X <- ZarrSparseMatrixSeed(adzarr_path, "X")
        counts <- ZarrSparseMatrixSeed(adzarr_path, "layers/counts")

        for (seed in list(X, counts)) {
            expect_true(is(seed, "CSC_ZarrSparseMatrixSeed"))
            expect_identical(dim(seed), c(100L, 50L))
            expect_identical(chunkdim(seed), c(100L, 1L))
            expect_true(is_sparse(seed))
            expect_true(nzcount(seed) == 4317)

            svt0 <- extract_sparse_array(seed, list(NULL, NULL))
            expect_true(is(svt0, "SVT_SparseMatrix"))
            expect_identical(dim(svt0), dim(seed))
            svt <- extract_sparse_array(seed, list(99:100, 48:50))
            expect_true(is(svt, "SVT_SparseMatrix"))
            expect_identical(dim(svt), c(2L, 3L))
            expect_identical(svt, svt0[99:100, 48:50])

            tseed <- t(seed)
            expect_true(is(tseed, "CSR_ZarrSparseMatrixSeed"))
            expect_identical(dim(tseed), c(50L, 100L))
            expect_identical(chunkdim(tseed), c(1L, 100L))
            expect_true(is_sparse(tseed))
            expect_true(nzcount(tseed) == 4317)
            expect_identical(t(tseed), seed)

            tsvt0 <- extract_sparse_array(tseed, list(NULL, NULL))
            expect_true(is(tsvt0, "SVT_SparseMatrix"))
            expect_identical(dim(tsvt0), dim(tseed))
            expect_identical(tsvt0, t(svt0))
            tsvt <- extract_sparse_array(tseed, list(48:50, 99:100))
            expect_true(is(tsvt, "SVT_SparseMatrix"))
            expect_identical(dim(tsvt), c(3L, 2L))
            expect_identical(tsvt, t(svt))
        }

        ## Group "layers/csc_counts" contains a sparse matrix:

        csc_counts <- ZarrSparseMatrixSeed(adzarr_path, "layers/csc_counts")
        expect_true(is(csc_counts, "CSR_ZarrSparseMatrixSeed"))
        expect_identical(dim(csc_counts), c(100L, 50L))
        expect_identical(chunkdim(csc_counts), c(1L, 50L))
        expect_true(is_sparse(csc_counts))
        expect_true(nzcount(csc_counts) == 4317)

        tseed <- t(csc_counts)
        expect_true(is(tseed, "CSC_ZarrSparseMatrixSeed"))
        expect_identical(dim(tseed), c(50L, 100L))
        expect_identical(chunkdim(tseed), c(50L, 1L))
        expect_true(is_sparse(tseed))
        expect_true(nzcount(tseed) == 4317)
        expect_identical(t(tseed), csc_counts)

        ## 'counts' and 'csc_counts' contain the same data:

        index <- list(NULL, NULL)
        svt1 <- extract_sparse_array(counts, index)
        svt2 <- extract_sparse_array(csc_counts, index)
        expect_identical(svt1, svt2)
        index <- list(99:100, 48:50)
        svt1 <- extract_sparse_array(counts, index)
        svt2 <- extract_sparse_array(csc_counts, index)
        expect_identical(svt1, svt2)
    }
})

