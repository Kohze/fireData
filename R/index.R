#' @title The firebase data upload function:
#' @author Robin Kohze
#' @description The function allows to upload data objects, such as variables,lists and data.frames
#' @param x A data.frame or data.table {object}
#' @param projectURL The Firebase project URL {string}
#' @param directory The optimal Firebase subdirectory {string}
#' @param token The user access token that can be retrieved with the auth() function. Required when if the database rules specify the need for user authentications. {string}
#' @return returns http request answer which includes the random key.
#' @export
upload <- function(x, projectURL, directory = "main", token = "none"){
 output = fileConversion(x)
 if (token == "none") {
  Response = httr::POST(paste0(projectURL,"/",directory,".json"), body = jsonlite::toJSON(output, auto_unbox = TRUE))
 } else {
   Response = httr::POST(paste0(projectURL,"/",directory,".json?auth=",token), body = jsonlite::toJSON(output, auto_unbox = TRUE))
 }
  return(paste0(directory,"/",httr::content(Response)$name))
}

#' @title Data conversion function
#' @description The internal data conversion function to bring data in the right json format. In case the uploaded file is a s4 class object, the object is converted to a binary s4 object.
#' @param x the input file.
#' @return returns optionally reformatted data.
fileConversion <- function(x){
  if (isS4(x)) {
    output = classConversion(x)
  } else {
    output = x
  }
}

#' @title Data conversion function
#' @description The internal data conversion function to bring data in the right json format. In case the uploaded file is a s4 class object, the object is converted to a binary s4 object.
#' @param projectURL The firebase database url. {string}
#' @param fileName The filename or subdirectory. {string}
#' @param secretKey The optional database secret key for admin access. {string}
#' @param token The user access token that can be retrieved with the auth() function. Required when if the database rules specify the need for user authentications. {string}
#' @param isClass In case a s4 class object is downloaded, fireData expects a isClass=TRUE
#' @return returns optionally reformatted data.
#' @export
download <- function(projectURL, fileName, secretKey = "none", token = "none", isClass = FALSE) {

   if (secretKey == "none" && token == "none") {
     urlPath = paste0(projectURL,"/",fileName,".json")
   } else if (token != "none") {
     urlPath = paste0(projectURL,"/",fileName,".json?auth=",token)
   } else {
     urlPath = paste0(projectURL,"/",fileName,".json?auth=",secretKey)
   }

   data = httr::GET(urlPath)

   if (is.null(jsonlite::fromJSON(httr::content(data,"text")))) warning("No data found at database location.")
   if (isClass) {
     retrievedData = httr::content(data,"text")
     tempPath = tempfile()
     writeBin(jsonlite::base64_dec(jsonlite::fromJSON(retrievedData)), tempPath)
     return(readRDS(tempPath))
   } else {
     return(jsonlite::fromJSON(httr::content(data,"text")))
   }
}

#' @title The firebase database backup function:
#' @param projectURL The Firebase Project Url {string}
#' @param secretKey The firebase secret key, which can be found in the Config/ Service Accounts/ Database secrets firebase page. {string}
#' @param fileName The output file name. Can be any string with .json format {string}
#' @description The backup functionality allows to download the whole database into a .json file (which can later be uploaded in the firebase console to do a restore of the DB). Generally this function may allow to save costs by not relying on the Firebase automatic backup function that is only available with the Firebase Blaze premium payment contract.
#' @return Returns either a warning or the backup file name.
#' @export
dataBackup <- function(projectURL, secretKey="prompt", fileName){
  if (secretKey == "prompt") {
    secretKey <- readline(prompt = "secretKey: ")
    print("Connecting to SpatialMaps:")
  }
  print("Fetching Data")
  urlPath = paste0(projectURL,"/.json?auth=",secretKey)
  curl::curl_download(url = urlPath,
                destfile = fileName,
                quiet = FALSE)
  print(paste0("Backup created in ", fileName))
}

#' @title The user authentication function:
#' @description fireData::auth checks the validity of a login and returns the temporary JWT user token. FireData_auth can be used to store individual user data in specified directories that are only accessible to that specific user.
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @param password The user password {string}
#' @return Returns the content of the firebase API request, such as the state of registration, idToken, and validity of the user password.
#' @export
auth <- function(projectAPI, email="prompt", password="prompt"){
  if (password == "prompt" && email == "prompt") {
        email <- readline(prompt = "Email: ")
        password <- readline(prompt = "Password: ")
        print("Connecting to SpatialMaps:")
  }
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=", projectAPI)
  userData = httr::POST(url = AuthUrl, body = list("email" = email, "password" = password, "returnSecureToken" = "True"), encode = "json")
  return(httr::content(userData))
}

#' @title Firebase user creation function
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @param password The user password {string}
#' @description Creates a new firebase user account. All user accounts can accessed at the firebase.com project console. One of the advantages of firebase accounts in R is the ability to access a website and analyse the data of the website with the very same login.
#' @return Registers a new user and returns the status.
#' @export
createUser <- function(projectAPI, email="prompt", password="prompt"){
  if (password == "prompt" && email == "prompt") {
    email <- readline(prompt = "Email: ")
    password <- readline(prompt = "Password: ")
    print("Connecting to SpatialMaps:")
  }
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=", projectAPI)
  userData = httr::POST(url = AuthUrl, body = list("email" = email, "password" = password), encode = "json")
  return(httr::content(userData))
}

#' @title Password resett function:
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @description Resets the user password and sends an email to the user account.
#' @return Success or warning message.
#' @export
resetPassword <- function(projectAPI, email){
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/getOobConfirmationCode?key=", projectAPI)
  userData = httr::POST(url = AuthUrl, body = list("email" = email, "requestType" = "PASSWORD_RESET"), encode = "json")
  if ("error" %in% names(httr::content(userData))) {
    warning(paste0("User email ", email, " was not found in the database"))
  } else {
    print(paste0("Password reset email was send to ", email))
  }
}

#' @title Internal class to binary conversion:
#' @param x is the S4 class object
#' @description The internal conversion is needed to conserve all class information
#' @return returns base64 encoded binary value of class object
classConversion <- function(x){
  #convert object to base64
  tempPath = tempfile()
  saveRDS(x, file = tempPath)
  binarySet = readBin(tempPath, what = "raw", n = 50000000)
  base64Set = jsonlite::base64_enc(binarySet)
  #adding key by assigning to data.frame
  pRolocList = list("base64Set" =  base64Set)
  return(pRolocList)
}

#' @title Path key replacement function:
#' @description replaces all disallowed path symbols with a "-"
#' @param path is the db path {string}
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

