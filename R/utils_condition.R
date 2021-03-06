throw_cancel <- function(...) {
  stop(condition_cancel(...))
}

throw_file <- function(...) {
  stop(condition_file(...))
}

throw_prelocal <- function(...) {
  stop(condition_prelocal(...))
}

throw_run <- function(...) {
  stop(condition_run(...))
}

throw_validate <- function(...) {
  stop(condition_validate(...))
}

warn_run <- function(...) {
  warning(warning_run(...))
}

condition_cancel <- function(...) {
  structure(
    list(message = paste0(..., collapse = ""), call = NULL),
    class = c("condition_cancel", "condition_targets", "error", "condition")
  )
}

condition_file <- function(...) {
  structure(
    list(message = paste0(..., collapse = ""), call = NULL),
    class = c("condition_file", "condition_targets", "error", "condition")
  )
}

condition_prelocal <- function(...) {
  structure(
    list(message = paste0(..., collapse = ""), call = NULL),
    class = c("condition_prelocal", "condition_targets", "error", "condition")
  )
}

condition_run <- function(...) {
  structure(
    list(message = paste0(..., collapse = ""), call = NULL),
    class = c("condition_run", "condition_targets", "error", "condition")
  )
}

condition_validate <- function(...) {
  structure(
    list(message = paste0(..., collapse = ""), call = NULL),
    class = c("condition_validate", "condition_targets", "error", "condition")
  )
}

warning_run <- function(...) {
  structure(
    list(message = paste0(..., collapse = ""), call = NULL),
    class = c("condition_run", "condition_targets", "warning", "condition")
  )
}

as_immediate_condition <- function(x) {
  x$call <- NULL
  enclass(x, "immediateCondition")
}
