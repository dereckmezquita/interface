#' @keywords internal
.onLoad <- function(libname, pkgname) {
    registerS3method("$", "validated_list", `$.validated_list`)
    registerS3method("$<-", "validated_list", `$<-.validated_list`)
}
