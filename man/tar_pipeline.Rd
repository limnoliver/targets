% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_pipeline.R
\name{tar_pipeline}
\alias{tar_pipeline}
\title{Declare a pipeline of targets.}
\usage{
tar_pipeline(...)
}
\arguments{
\item{...}{Targets or lists of targets defined with \code{\link[=tar_target]{tar_target()}}.}
}
\value{
A pipeline object. The \verb{_targets.R} file of a project must
end with a call \code{tar_pipeline()}.
Otherwise, users do not work pipeline objects directly.
}
\description{
A pipeline is similar to a \code{Makefile} or a \code{drake} plan.
It is a collection of targets, or skippable steps,
in an automated reproducible workflow.
}
\examples{
file <- tar_target(data_file, "data.csv", format = "file")
object <- tar_target(data_object, read.csv(data_file))
analysis <- tar_target(analysis, analyze(data_object))
pipeline <- tar_pipeline(file, object, analysis)
print(pipeline)
# Equivalent:
target_list <- list(
  tar_target(data_file, "data.csv", format = "file"),
  tar_target(data_object, read.csv(data_file)),
  tar_target(analysis, analyze(data_object))
)
pipeline <- tar_pipeline(target_list)
}
