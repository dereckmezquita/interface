% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/enum.R
\name{$<-.enum}
\alias{$<-.enum}
\title{Set value of enum object}
\usage{
\method{$}{enum}(x, name) <- value
}
\arguments{
\item{x}{An enum object}

\item{name}{The name of the field to set (should be "value")}

\item{value}{The new value to set}
}
\value{
The updated enum object
}
\description{
Sets the value of an enum object. The new value must be one of the valid enum values.
}
