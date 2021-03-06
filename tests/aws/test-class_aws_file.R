# Use sparingly. We do not want to max out any AWS quotas.
tar_test("aws_file format file gets stored", {
  skip_if_no_aws()
  bucket_name <- random_bucket_name()
  on.exit({
    aws.s3::delete_object(object = "_targets/objects/x", bucket = bucket_name)
    aws.s3::delete_object(object = "_targets/objects/y", bucket = bucket_name)
    aws.s3::delete_object(object = "_targets/objects", bucket = bucket_name)
    aws.s3::delete_object(object = "_targets", bucket = bucket_name)
    aws.s3::delete_bucket(bucket = bucket_name)
    expect_false(aws.s3::bucket_exists(bucket = bucket_name))
  })
  aws.s3::put_bucket(bucket = bucket_name)
  expr <- quote({
    tar_option_set(resources = list(bucket = !!bucket_name))
    write_tempfile <- function(lines) {
      tmp <- tempfile()
      writeLines(lines, tmp)
      tmp
    }
    tar_pipeline(
      tar_target(x, write_tempfile("x_lines"), format = "aws_file"),
      tar_target(y, readLines(x))
    )
  })
  expr <- tidy_eval(expr, environment(), TRUE)
  eval(as.call(list(`tar_script`, expr, ask = FALSE)))
  tar_make(callr_function = NULL)
  expect_true(
    aws.s3::object_exists(bucket = bucket_name, object = "_targets/objects/x")
  )
  expect_equal(tar_read(y), "x_lines")
  expect_equal(length(list.files("_targets/scratch/")), 0L)
  path <- tar_read(x)
  expect_equal(length(list.files("_targets/scratch/")), 1L)
  expect_equal(readLines(path), "x_lines")
  tmp <- tempfile()
  aws.s3::save_object(
    object = "_targets/objects/x",
    bucket = bucket_name,
    file = tmp
  )
  expect_equal(readLines(tmp), "x_lines")
})

# Run once with debug(store_unload.tar_aws_file) # nolint
# to make sure scratch file gets unloaded according to
# the `memory` setting. Should run more twice for persistent
# and then four times for transient.
tar_test("aws_file format invalidation", {
  skip_if_no_aws()
  for (memory in c("persistent", "transient")) {
    # print(memory) # Uncomment for debug() test. # nolint
    bucket_name <- random_bucket_name()
    aws.s3::put_bucket(bucket = bucket_name)
    expr <- quote({
      tar_option_set(
        resources = list(bucket = !!bucket_name),
        memory = !!memory
      )
      write_tempfile <- function(lines) {
        tmp <- tempfile()
        writeLines(lines, tmp)
        tmp
      }
      tar_pipeline(
        tar_target(x, write_tempfile("x_lines"), format = "aws_file"),
        tar_target(y, readLines(x))
      )
    })
    expr <- tidy_eval(expr, environment(), TRUE)
    eval(as.call(list(`tar_script`, expr, ask = FALSE)))
    tar_make(callr_function = NULL)
    expect_equal(tar_progress(x)$progress, "built")
    expect_equal(tar_progress(y)$progress, "built")
    tar_make(callr_function = NULL)
    expect_equal(nrow(tar_progress()), 0L)
    expr <- quote({
      tar_option_set(
        resources = list(bucket = !!bucket_name),
        memory = !!memory
      )
      write_tempfile <- function(lines) {
        tmp <- tempfile()
        writeLines(lines, tmp)
        tmp
      }
      tar_pipeline(
        tar_target(x, write_tempfile("x_lines2"), format = "aws_file"),
        tar_target(y, readLines(x))
      )
    })
    expr <- tidy_eval(expr, environment(), TRUE)
    eval(as.call(list(`tar_script`, expr, ask = FALSE)))
    tar_make(callr_function = NULL)
    expect_equal(tar_progress(x)$progress, "built")
    expect_equal(tar_progress(y)$progress, "built")
    expect_equal(tar_read(y), "x_lines2")
    aws.s3::delete_object(object = "_targets/objects/x", bucket = bucket_name)
    aws.s3::delete_object(object = "_targets/objects/y", bucket = bucket_name)
    aws.s3::delete_object(object = "_targets/objects", bucket = bucket_name)
    aws.s3::delete_object(object = "_targets", bucket = bucket_name)
    aws.s3::delete_bucket(bucket = bucket_name)
    expect_false(aws.s3::bucket_exists(bucket = bucket_name))
  }
})
