#' @title Consistent anonymization
#' @description Uses HMAC (hashed message authentication code) hashing with the
#'   name of the machine as the key, enabling consistent username anonymization
#'   within the lifetime of the machine running the code. This means the output
#'   from several talk pages that have authors in common will have hashes in
#'   common as well.
#' @param x character vector
#' @seealso [openssl::hashing]
#' @export
anonymize <- function(x) {
  return(openssl::md5(x, key = Sys.info()["nodename"]))
}
