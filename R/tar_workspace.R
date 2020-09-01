#' @title Load a saved workspace and seed for debugging.
#' @export
#' @description Load the workspace and random number generator seed
#'   of an errored target attempted with `error = "save"`.
#' @details If you set `error = "save"` in [tar_option_set()]
#'   or [tar_target()], then if that target throws an error
#'   in [tar_make()], it will save its workspace to a compressed file
#'   in `_targets/workspaces/`. The workspace includes the
#'   global objects at the time [tar_make()] was called, the
#'   dependency targets, the random number generator seed
#'   (assigned to `.tar_seed` and set with `set.seed()`)
#'   and the traceback of the error (assigned to `.tar_traceback`).
#'
#'   Although useful, this behavior does not perfectly replicate
#'   what [tar_make()] does to set up the runtime environment
#'   for a target. [tar_make()] creates a formal hierarchy of
#'   environments that inherit from one another in order to
#'   organize data and contain side effects.
#'
#'   In addition, sometimes, you may not be able to debug with
#'   `error = "save"`. Workspace files are saved with `qs::qsave()`,
#'   so if one of your dependencies cannot be properly serialized this way
#'   (e.g. Keras models you store with `format = "keras"`)
#'   then the workspace cannot be saved properly. If this happens to you,
#'   either avoid non-exportable objects or use interactive debugging.
#'   (See the `debug` argument of [tar_option_set()].)
#' @return the function returns no value, but it does load multiple objects
#'   into the environment (`envir` argument) in order to replicate the
#'   workspace where the error happened. These objects include
#'   the global objects at the time [tar_make()] was called, the
#'   dependency targets, the random number generator seed
#'   (assigned to `.tar_seed` and set with `set.seed()`)
#'   and the traceback of the error (assigned to `.tar_traceback`).
#' @param name Symbol, name of the target whose workspace to read.
#' @param envir Environment in which to put the objects.
#' @examples
#' \dontrun{
#' tmp <- sample(1)
#' tar_script({
#'   tar_option_set(error = "save") # Required for saving workspaces.
#'   tar_pipeline(
#'     tar_target(x, "loaded"),
#'     tar_target(y, stop(x))
#'   )
#' })
#' try(tar_make())
#' exists("x") # Should be FALSE.
#' tail(.Random.seed)
#' tar_workspace(y)
#' exists("x") # Should be TRUE.
#' print(x) # "loaded"
#' tail(.Random.seed) # Should be different.
#' tail(.tar_traceback, 1)
#' }
tar_workspace <- function(name, envir = parent.frame()) {
  force(envir)
  name <- deparse_language(substitute(name))
  path <- store_path_workspaces(name)
  assert_path(path, paste0("no workspace found for target ", name, "."))
  workspace <- qs::qread(path)
  map(names(workspace), ~assign(.x, value = workspace[[.x]], envir = envir))
  set.seed(workspace$.tar_seed)
  invisible()
}