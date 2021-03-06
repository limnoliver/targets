#' @title Produce a data frame of information about your targets.
#' @export
#' @description Along with [tar_visnetwork()] and [tar_glimpse()],
#'   `tar_manifest()` helps check that you constructed your pipeline correctly.
#' @return A data frame of information about the targets in the pipeline.
#' @inheritParams tar_validate
#' @param names Names of the targets to show. Set to `NULL` to
#'   show all the targets (default). Otherwise, you can supply
#'   symbols, a character vector, or `tidyselect` helpers like [starts_with()].
#' @param fields Names of the fields, or columns, to show. Set to `NULL` to
#'   show all the fields (default). Otherwise, you can supply
#'   symbols, a character vector, or `tidyselect` helpers like [starts_with()].
#'   Set to `NULL` to print all the fields.
#'   The name of the target is always included as the first column
#'   regardless of the selection.
#'   Possible fields are below. All of them can be set in [tar_target()],
#'   [tar_target_raw()], or [tar_option_set()].
#'   * `name`: Name of the target.
#'   * `command`: the R command that runs when the target builds.
#'   * `pattern`: branching pattern of the target, if applicable.
#'   * `format`: Storage format.
#'   * `iteration`: Iteration mode for branching.
#'   * `error`: Error mode, what to do when the target fails.
#'   * `memory`: Memory mode, when to keep targets in memory.
#'   * `storage`: Storage mode for high-performance computing scenarios.
#'   * `retrieval`: Retrieval mode for high-performance computing scenarios.
#'   * `deployment`: Where/whether to deploy the target in high-performance
#'     computing scenarios.
#'   * `resources`: A list of target-specific resource requirements for
#'     [tar_make_future()].
#'   * `cue_mode`: Cue mode from [tar_cue()].
#'   * `cue_depend`: Depend cue from [tar_cue()].
#'   * `cue_expr`: Command cue from [tar_cue()].
#'   * `cue_file`: File cue from [tar_cue()].
#'   * `cue_format`: Format cue from [tar_cue()].
#'   * `cue_iteration`: Iteration cue from [tar_cue()].
#'   * `packages`: List columns of packages loaded before building the target.
#'   * `library`: List column of library paths to load the packages.
#' @examples
#' if (identical(Sys.getenv("TARGETS_LONG_EXAMPLES"), "true")) {
#' tar_dir({
#' tar_script({
#'   tar_option_set()
#'   tar_pipeline(
#'     tar_target(y1, 1 + 1),
#'     tar_target(y2, 1 + 1),
#'     tar_target(z, y1 + y2),
#'     tar_target(m, z, pattern = map(z)),
#'     tar_target(c, z, pattern = cross(z))
#'   )
#' })
#' tar_manifest()
#' tar_manifest(fields = c("name", "command"))
#' tar_manifest(fields = "command")
#' tar_manifest(fields = starts_with("cue"))
#' })
#' }
tar_manifest <- function(
  names = NULL,
  fields = c("name", "command", "pattern"),
  callr_function = callr::r,
  callr_arguments = list()
) {
  assert_target_script()
  assert_callr_function(callr_function)
  assert_list(callr_arguments, "callr_arguments mut be a list.")
  targets_arguments <- list(
    names_quosure = rlang::enquo(names),
    fields_quosure = rlang::enquo(fields)
  )
  callr_outer(
    targets_function = tar_manifest_inner,
    targets_arguments = targets_arguments,
    callr_function = callr_function,
    callr_arguments = callr_arguments
  )
}

tar_manifest_inner <- function(
  pipeline,
  names_quosure,
  fields_quosure
) {
  pipeline_validate_lite(pipeline)
  all_names <- pipeline_get_names(pipeline)
  names <- eval_tidyselect(names_quosure, all_names) %||% all_names
  out <- map(names, ~tar_manifest_target(pipeline_get_target(pipeline, .x)))
  out <- do.call(rbind, out)
  fields <- eval_tidyselect(fields_quosure, colnames(out)) %||% colnames(out)
  out[, base::union("name", fields), drop = FALSE]
}

tar_manifest_target <- function(target) {
  out <- list(
    name = target_get_name(target),
    command = tar_manifest_command(target$command$expr),
    pattern = tar_manifest_pattern(target$settings$pattern),
    format = target$settings$format,
    iteration = target$settings$iteration,
    error = target$settings$error,
    memory = target$settings$memory,
    storage = target$settings$storage,
    retrieval = target$settings$retrieval,
    deployment = target$settings$deployment,
    resources = list(target$settings$resources),
    cue_mode = target$cue$mode,
    cue_command = target$cue$command,
    cue_depend = target$cue$depend,
    cue_file = target$cue$file,
    cue_format = target$cue$format,
    cue_iteration = target$cue$iteration,
    packages = list(target$command$packages),
    library = list(target$command$library)
  )
  tibble::as_tibble(out)
}

tar_manifest_command <- function(expr) {
  out <- deparse_safe(expr, collapse = " \\n ")
  out <- mask_pointers(out)
  string_sub_expression(out)
}

tar_manifest_pattern <- function(pattern) {
  trn(
    is.null(pattern),
    NA_character_,
    string_sub_expression(deparse_safe(pattern, collapse = " "))
  )
}
