tar_test("tar_manifest() with default settings", {
  tar_script({
    tar_option_set()
    tar_pipeline(
      tar_target(y1, 1 + 1),
      tar_target(y2, 1 + 1),
      tar_target(z, y1 + y2),
      tar_target(m, z, pattern = map(z)),
      tar_target(c, z, pattern = cross(z))
    )
  })
  out <- tar_manifest()
  expect_equal(colnames(out), c("name", "command", "pattern"))
  expect_equal(nrow(out), 5L)
})

tar_test("tar_manifest() tidyselect on names", {
  tar_script({
    tar_option_set()
    tar_pipeline(
      tar_target(y1, 1 + 1),
      tar_target(y2, 1 + 1),
      tar_target(z, y1 + y2),
      tar_target(m, z, pattern = map(z)),
      tar_target(c, z, pattern = cross(z))
    )
  })
  out <- tar_manifest(names = starts_with("y"), callr_function = NULL)
  expect_equal(nrow(out), 2L)
})

tar_test("tar_manifest() shows patterns correctly", {
  tar_script({
    tar_option_set()
    tar_pipeline(
      tar_target(y1, 1 + 1),
      tar_target(y2, 1 + 1),
      tar_target(z, y1 + y2),
      tar_target(m, z, pattern = map(z)),
      tar_target(c, z, pattern = cross(z))
    )
  })
  out <- tar_manifest(
    names = c,
    fields = "pattern",
    callr_function = NULL
  )
  expect_equal(out$pattern, "cross(z)")
  out <- tar_manifest(
    names = m,
    fields = "pattern",
    callr_function = NULL
  )
  expect_equal(out$pattern, "map(z)")
})

tar_test("tar_manifest() shows cues correctly", {
  tar_script({
    tar_option_set()
    tar_pipeline(
      tar_target(y1, 1 + 1),
      tar_target(y2, 1 + 1),
      tar_target(z, y1 + y2),
      tar_target(m, z, pattern = map(z)),
      tar_target(c, z, pattern = cross(z))
    )
  })
  out <- tar_manifest(fields = starts_with("cue"), callr_function = NULL)
  cols <- c(
    "name",
    "cue_mode",
    "cue_command",
    "cue_depend",
    "cue_file",
    "cue_format",
    "cue_iteration"
  )
  expect_equal(colnames(out), cols)
  expect_true(is.character(out$cue_mode))
  expect_true(is.logical(out$cue_command))
  expect_true(is.logical(out$cue_depend))
  expect_true(is.logical(out$cue_file))
  expect_true(is.logical(out$cue_format))
  expect_true(is.logical(out$cue_iteration))
})

tar_test("tar_manifest() shows all fields if the fields arg is NULL", {
  tar_script({
    tar_option_set()
    tar_pipeline(
      tar_target(y1, 1 + 1),
      tar_target(y2, 1 + 1),
      tar_target(z, y1 + y2),
      tar_target(m, z, pattern = map(z)),
      tar_target(c, z, pattern = cross(z))
    )
  })
  out <- tar_manifest(fields = NULL, callr_function = NULL)
  expect_equal(dim(out), c(5L, 19L))
})
