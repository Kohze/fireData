#' @title FireData_push()
#' @author Robin Kohze
#' @param x A data.frame or data.table
#' @return returns http request return. Includes the key.
#' @export
FireData_upload <- function(x, projectURL, directory){
 Response = POST(paste0(projectURL,"/","directory",".json"), body = toJSON(x, auto_unbox = TRUE))
 return(content(Response))
}

#' @title FireData_Backup()
#' @param x A data.frame or data.table
#' @return showing shapiro.test output of the data.frame
#' @export
FireData_upload <- function(x, projectURL, directory){
  print("works")
}
