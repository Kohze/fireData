#' @title fireData_upload()
#' @author Robin Kohze
#' @description The function allows to upload data objects, such as variables,lists and data.frames
#' @param x A data.frame or data.table {object}
#' @param projectURL The Firebase project URL {string}
#' @param directory The optimal Firebase subdirectory {string}
#' @return returns http request return. Includes the key.
#' @export
fireData_upload <- function(x, projectURL, directory = "main"){
 Response = POST(paste0(projectURL,"/","directory",".json"), body = toJSON(x, auto_unbox = TRUE))
 return(content(Response))
}

#' @title FireData_Backup()
#' @param x A data.frame or data.table
#' @return showing shapiro.test output of the data.frame
#' @export
fireData_download <- function(x, projectURL, directory){
  print("works")
}


#' @title path_check()
#' @description replaces all disallowed path symbols with a "-"
#' @param x the path {string}
#' @return the approved and cleaned path_string
#' @export
path_check <- function(path){
  path_replaced = gsub("\\$","-", path)
  path_replaced = gsub("\\#","-", path_replaced)
  path_replaced = gsub("\\]","-", path_replaced)
  path_replaced = gsub("\\[","-", path_replaced)
  path_replaced = gsub("\\/","-", path_replaced)
  path_replaced = gsub("\\.","-", path_replaced)
  if (path_replaced != path) warning(paste0("path changed to ", path_replaced))
  return(path)
}
