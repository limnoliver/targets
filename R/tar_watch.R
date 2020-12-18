# nocov start # Tested in tests/interactive/test-tar_watch.R
#' @title Shiny app to watch the dependency graph.
#' @export
#' @description Launches a background process with a Shiny app
#'   that calls [tar_visnetwork()] every few seconds.
#'   To embed this app in other apps, use the Shiny module
#'   in [tar_watch_ui()] and [tar_watch_server()].
#' @details The controls of the app are in the left panel.
#'   The `seconds` control is the number of seconds between
#'   refreshes of the graph, and the other settings match
#'   the arguments of [`tar_visnetwork()`].
#' @return A handle to `callr::r_bg()` background process running the app.
#' @inheritParams tar_watch_ui
#' @param background Logical, whether to run the app in a background process
#'   so you can still use the R console while the app is running.
#' @param host Character of length 1, IPv4 address to listen on.
#'   Ignored if `background` is `FALSE`.
#' @param port Positive integer of length 1, TCP port to listen on.
#'   Ignored if `background` is `FALSE`.
#' @param ... Named arguments to `callr::r_bg()`.
#' @examples
#' if (FALSE) { # Only run interactively.
#' tar_dir({
#' tar_script({
#'   sleep_run <- function(...) {
#'     Sys.sleep(10)
#'   }
#'   tar_pipeline(
#'     tar_target(settings, sleep_run()),
#'     tar_target(data1, sleep_run(settings)),
#'     tar_target(data2, sleep_run(settings)),
#'     tar_target(data3, sleep_run(settings)),
#'     tar_target(model1, sleep_run(data1)),
#'     tar_target(model2, sleep_run(data2)),
#'     tar_target(model3, sleep_run(data3)),
#'     tar_target(figure1, sleep_run(model1)),
#'     tar_target(figure2, sleep_run(model2)),
#'     tar_target(figure3, sleep_run(model3)),
#'     tar_target(conclusions, sleep_run(c(figure1, figure2, figure3)))
#'   )
#' })
#' # Launch the app in a background process.
#' tar_watch(seconds = 10, outdated = FALSE, targets_only = TRUE)
#' # Run the pipeline.
#' tar_make()
#' })
#' }
tar_watch <- function(
  seconds = 5,
  seconds_min = 1,
  seconds_max = 100,
  seconds_step = 1,
  targets_only = FALSE,
  outdated = TRUE,
  label = NULL,
  level_separation = 150,
  height = "700px",
  background = TRUE,
  host = getOption("shiny.host", "127.0.0.1"),
  port = getOption("shiny.port", targets::tar_watch_port()),
  ...
) {
  assert_package("bs4Dash")
  assert_package("shiny")
  assert_package("shinycssloaders")
  assert_package("visNetwork")
  assert_target_script()
  assert_dbl(seconds, "seconds must be numeric.")
  assert_dbl(seconds_min, "seconds_min must be numeric.")
  assert_dbl(seconds_max, "seconds_max must be numeric.")
  assert_dbl(seconds_step, "seconds_step must be numeric.")
  assert_scalar(seconds, "seconds must have length 1.")
  assert_scalar(seconds_min, "seconds_min must have length 1.")
  assert_scalar(seconds_max, "seconds_max must have length 1.")
  assert_scalar(seconds_step, "seconds_step must have length 1.")
  seconds_min <- min(seconds_min, seconds)
  seconds_max <- max(seconds_max, seconds)
  seconds_step <- min(seconds_step, seconds_max)
  args <- list(
    dir = getwd(),
    seconds = seconds,
    seconds_min = seconds_min,
    seconds_max = seconds_max,
    seconds_step = seconds_step,
    targets_only = targets_only,
    outdated = outdated,
    label = label,
    level_separation = level_separation,
    height = height
  )
  call <- as.call(c(quote(targets::tar_watch_app), args))
  if (!background) {
    return(eval(call))
  }
  text <- deparse_safe(call, collapse = " ")
  dir <- tempfile()
  dir_create(dir)
  app <- file.path(dir, "app.R")
  writeLines(text, app)
  args <- list(
    appDir = dir,
    host = host,
    port = port,
    launch.browser = TRUE,
    quiet = FALSE
  )
  args <- list(dir = dir, port = port, host = host)
  px <- callr::r_bg(func = tar_watch_process, args = args, ...)
  utils::browseURL(paste0("http://", host, ":", port))
  px
}

tar_watch_process <- function(dir, port, host) {
  on.exit(unlink(dir, recursive = TRUE))
  shiny::runApp(
    appDir = dir,
    host = host,
    port = port,
    launch.browser = FALSE,
    quiet = FALSE
  )
}

#' @title Random port for [tar_watch()]
#' @export
#' @keywords internal
#' @description Required for [tar_watch()]. Not a user-side function.
#' @return A random port not likely to be used by another process.
#' @param lower Integer of length 1, lowest possible port.
#' @param upper Integer of length 1, highest possible port.
#' @examples
#' tar_watch_port()
tar_watch_port <- function(lower = 49152L, upper = 65355L) {
  sample(seq.int(from = lower, to = upper, by = 1L), size = 1L)
}

#' @title Shiny app to watch the dependency graph (process version).
#' @export
#' @keywords internal
#' @description User should directly call [tar_watch()] instead
#'   of `tar_watch_app()`. The latter is an internal utility
#'   that blocks the main process.
#' @return A Shiny app.
#' @inheritParams tar_watch_ui
tar_watch_app <- function(
  dir = NULL,
  seconds = 5,
  seconds_min = 1,
  seconds_max = 100,
  seconds_step = 1,
  targets_only = FALSE,
  outdated = TRUE,
  label = NULL,
  level_separation = 150,
  height = "700px"
) {
  if (!is.null(dir)) {
    # We really do need to restore the working directory because
    # the app is in a tempfile. The app needs to be in a tempfile
    # so we can call shiny::runApp(). That is the only way to
    # run a non-blocking app.
    setwd(dir) # nolint
  }
  ui <- tar_watch_app_ui(
    seconds = seconds,
    seconds_min = seconds_min,
    seconds_max = seconds_max,
    seconds_step = seconds_step,
    targets_only = targets_only,
    outdated = outdated,
    label_tar_visnetwork = label,
    level_separation = level_separation,
    height = height
  )
  server <- function(input, output, session) {
    tar_watch_server("tar_watch_id", height = height)
  }
  shiny::shinyApp(ui = ui, server = server)
}

tar_watch_app_ui <- function(
  seconds,
  seconds_min,
  seconds_max,
  seconds_step,
  targets_only,
  outdated,
  label_tar_visnetwork,
  level_separation,
  height
) {
  body <- bs4Dash::bs4DashBody(
    tar_watch_ui(
      id = "tar_watch_id",
      label = "tar_watch_label",
      seconds = seconds,
      seconds_min = seconds_min,
      seconds_max = seconds_max,
      seconds_step = seconds_step,
      targets_only = targets_only,
      outdated = outdated,
      label_tar_visnetwork = label_tar_visnetwork,
      level_separation = level_separation,
      height = height
    )
  )
  bs4Dash::bs4DashPage(
    title = "",
    body = body,
    navbar = bs4Dash::bs4DashNavbar(controlbarIcon = NULL),
    sidebar = bs4Dash::bs4DashSidebar(disable = TRUE)
  )
}

#' @title Shiny module UI for tar_watch()
#' @export
#' @description Use `tar_watch_ui()` and [tar_watch_server()]
#'   to include [tar_watch()] as a Shiny module in an app.
#' @examples
#' str(tar_watch_ui("my_id"))
#' @return A Shiny module UI.
#' @inheritParams shiny::moduleServer
#' @inheritParams tar_watch_server
#' @inheritParams tar_visnetwork
#' @param label Label for the module.
#' @param seconds Numeric of length 1,
#'   default number of seconds between refreshes of the graph.
#'   Can be changed in the app controls.
#' @param seconds_min Numeric of length 1, lower bound of `seconds`
#'   in the app controls.
#' @param seconds_max Numeric of length 1, upper bound of `seconds`
#'   in the app controls.
#' @param seconds_step Numeric of length 1, step size of `seconds`
#'   in the app controls.
#' @param label_tar_visnetwork Character vector, `label` argument to
#'   [tar_visnetwork()].
tar_watch_ui <- function(
  id,
  label = "tar_watch_label",
  seconds = 5,
  seconds_min = 1,
  seconds_max = 60,
  seconds_step = 1,
  targets_only = FALSE,
  outdated = TRUE,
  label_tar_visnetwork = NULL,
  level_separation = 150,
  height = "700px"
) {
  ns <- shiny::NS(id)
  shiny::fluidRow(
    shiny::column(
      width = 4,
      bs4Dash::bs4Card(
        inputID = ns("control"),
        title = "Control",
        status = "primary",
        closable = FALSE,
        width = 12,
        shiny::sliderInput(
          ns("seconds"),
          "seconds",
          value = seconds,
          min = seconds_min,
          max = seconds_max,
          step = seconds_step
        ),
        shiny::selectInput(
          ns("targets_only"),
          "targets_only",
          choices = c("TRUE", "FALSE"),
          selected = as.character(targets_only)
        ),
        shiny::selectInput(
          ns("outdated"),
          "outdated",
          choices = c("TRUE", "FALSE"),
          selected = as.character(outdated)
        ),
        shiny::selectInput(
          ns("label"),
          "label",
          choices = c("time", "size", "branches"),
          selected = as.character(label_tar_visnetwork),
          multiple = TRUE
        ),
        shiny::sliderInput(
          ns("level_separation"),
          "level_separation",
          value = as.numeric(level_separation),
          min = 0,
          max = 1000,
          step = 10
        )
      )
    ),
    shiny::column(
      width = 8,
      bs4Dash::bs4Card(
        inputID = ns("graph"),
        title = "Graph",
        status = "primary",
        closable = FALSE,
        width = 12,
        shinycssloaders::withSpinner(
          visNetwork::visNetworkOutput(ns("graph"), height = height)
        )
      )
    )
  )
}

#' @title Shiny module server for tar_watch()
#' @export
#' @description Use [tar_watch_ui()] and `tar_watch_server()`
#'   to include [tar_watch()] as a Shiny module in an app.
#' @return A Shiny module server.
#' @inheritParams shiny::moduleServer
#' @param height Character of length 1,
#'   height of the `visNetwork` widget.
#' @examples
#' # tar_watch_server("my_id") # Only call inside an app.
tar_watch_server <- function(id, height = "700px") {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      output$graph <- visNetwork::renderVisNetwork({
        shiny::invalidateLater(millis = 1000 * as.numeric(input$seconds))
        tar_visnetwork(
          targets_only = as.logical(input$targets_only),
          outdated = as.logical(input$outdated),
          label = as.character(input$label),
          level_separation = as.numeric(input$level_separation)
        )
      })
    }
  )
}
# nocov end