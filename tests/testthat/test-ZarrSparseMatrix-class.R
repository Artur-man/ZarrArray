
test_that("ZarrSparseMatrix objects", {
    for (zarr_version in 3:2) {
        zad_basename <- paste0("example_v", zarr_version, ".zarr")
        zad_zip <- paste0(zad_basename, ".zip")
        zad_zip_path <- system.file(package="anndataR", "extdata", zad_zip)
        exdir <- tempdir()
        unzip(zad_zip_path, exdir=exdir)
        zad_store <- file.path(exdir, zad_basename)

        ## Groups "/X" and "/layers/counts" contain sparse matrices with
        ## the same geometries (100 x 50) and layouts (csr_matrix).
        ## Note that the csr_matrix layout at the Zarr level becomes
        ## CSC in R.

        X <- ZarrSparseMatrix(zad_store, "/X")
        counts <- ZarrSparseMatrix(zad_store, "/layers/counts")

        for (ZSM in list(X, counts)) {
            expect_true(is(ZSM, "ZarrSparseMatrix"))
            expect_true(is(seed(ZSM), "CSC_ZarrSparseMatrixSeed"))
            expect_identical(dim(ZSM), c(100L, 50L))
            expect_identical(chunkdim(ZSM), c(100L, 1L))
            expect_true(is_sparse(ZSM))
            expect_true(nzcount(ZSM) == 4317)

            svt0 <- as(ZSM, "SVT_SparseMatrix")
            expect_true(is(svt0, "SVT_SparseMatrix"))
            expect_identical(dim(svt0), dim(ZSM))
            svt <- as(ZSM[99:100, 48:50], "SVT_SparseMatrix")
            expect_true(is(svt, "SVT_SparseMatrix"))
            expect_identical(dim(svt), c(2L, 3L))
            expect_identical(svt, svt0[99:100, 48:50])
        }

        ## Group "/layers/csc_counts" contains a sparse matrix:

        csc_counts <- ZarrSparseMatrix(zad_store, "/layers/csc_counts")
        expect_true(is(csc_counts, "ZarrSparseMatrix"))
        expect_true(is(seed(csc_counts), "CSR_ZarrSparseMatrixSeed"))
        expect_identical(dim(csc_counts), c(100L, 50L))
        expect_identical(chunkdim(csc_counts), c(1L, 50L))
        expect_true(is_sparse(csc_counts))
        expect_true(nzcount(csc_counts) == 4317)

        ## 'counts' and 'csc_counts' contain the same data:

        expect_identical(as.matrix(counts), as.matrix(csc_counts))
    }
})

