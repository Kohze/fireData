#' @title fireData_upload()
#' @author Robin Kohze
#' @description The function allows to upload data objects, such as variables,lists and data.frames
#' @param x A data.frame or data.table {object}
#' @param projectURL The Firebase project URL {string}
#' @param directory The optimal Firebase subdirectory {string}
#' @return returns http request return. Includes the key.
#' @export
fireData_upload <- function(x, projectURL, directory = "main"){
 if (isS4(x)) {
    output = fireData_classConversion(x)
 } else {
    output = x
 }
  Response = POST(paste0(projectURL,"/","directory",".json"), body = toJSON(output, auto_unbox = TRUE))
  return(httr::content(Response))
}

#' @title FireData_download()
#' @param x A data.frame or data.table
#' @return showing shapiro.test output of the data.frame
#' @export
fireData_download <- function(x, projectURL, directory){
  print("works")
}

#' @title fireData_classConversion()
#' @param x A data.frame or data.table
#' @return showing shapiro.test output of the data.frame
#' @export
fireData_classConversion <- function(x){
  #convert object to base64
  tempPath = tempfile()
  saveRDS(x, file = tempPath)
  binarySet = readBin(tempPath, what = "raw", n = 50000000)
  base64Set = jsonlite::base64_enc(binarySet)
  #adding key by assigning to data.frame
  pRolocList = list("base64Set" =  base64Set)
  return(pRolocList)
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

