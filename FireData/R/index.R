#' @title fireData_upload()
#' @author Robin Kohze
#' @description The function allows to upload data objects, such as variables,lists and data.frames
#' @param x A data.frame or data.table {object}
#' @param projectURL The Firebase project URL {string}
#' @param directory The optimal Firebase subdirectory {string}
#' @return returns http request answer which includes the random key.
#' @export
fireData_upload <- function(x, projectURL, directory = "main"){
 if (isS4(x)) {
    output = fireData_classConversion(x)
 } else {
    output = x
 }
  Response = POST(paste0(projectURL,"/","directory",".json"), body = jsonlite::toJSON(output, auto_unbox = TRUE))
  return(httr::content(Response))
}

#' @title FireData_download()
#' @param x A data.frame or data.table
#' @return showing shapiro.test output of the data.frame
#' @export
fireData_download <- function(x, projectURL, directory){
  print("works")
}

#' @title FireData_backup()
#' @param projectUrl The Firebase Project Url
#' @param secretKey The firebase secret key, which can be found in the Config/ Service Accounts/ Database secrets firebase page.
#' @param fileName The output file name. Can be any string with .json format
#' @return Returns either a warning or the backup file name.
#' @export
fireData_backup <- function(projectURL, secretKey, fileName){
  print("Fetching Data")
  urlPath = paste0(projectURL,"/.json?auth=",secretKey)
  curl_download(url = urlPath,
                destfile=fileName,
                quiet = FALSE)
  print(paste0("Backup created in ", fileName))
}

#' @title FireData_auth()
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @param password The user password {string}
#' @return Returns the content of the firebase API request, such as the state of registration, idToken, and validity of the user password.
#' @export
FireData_auth <- function(projectAPI, email, password){
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=", projectAPI)
  userData = POST(url = AuthUrl, body=list("email" = email, "password" = password), encode = "json")
  return(content(userData))
}

#' @title FireData_createUser()
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @param password The user password {string}
#' @return Registers a new user and returns the status.
#' @export
FireData_createUser <- function(projectAPI, email, password){
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=", projectAPI)
  userData = POST(url = AuthUrl, body=list("email" = email, "password" = password), encode = "json")
  return(content(userData))
}


#' @title fireData_classConversion()
#' @param x is the S4 class object
#' @return returns base64 encoded binary value of class object
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

