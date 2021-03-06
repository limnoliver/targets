tar_test("aws_fst_tbl packages", {
  target <- tar_target(x, "x_value", format = "aws_fst_tbl")
  out <- sort(store_get_packages(target$store))
  exp <- sort(c("aws.s3", "fst", "tibble"))
  expect_equal(out, exp)
})

tar_test("validate aws_fst_tbl", {
  skip_if_not_installed("aws.s3")
  skip_if_not_installed("fst")
  skip_if_not_installed("tibble")
  tar_script(tar_pipeline(tar_target(x, "x_value", format = "aws_fst_tbl")))
  expect_silent(tar_validate(callr_function = NULL))
})
