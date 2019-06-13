test_that("download works", {
  unlink(factbook_cfg()$dest)
  expect_true(factbook_download())
})
