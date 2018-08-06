#' @title The firebase data upload function:
#' @author Robin Kohze
#' @description The function allows to upload data objects, such as variables,lists and data.frames
#' @param x A data.frame or data.table {object}
#' @param projectURL The Firebase project URL {string}
#' @param directory The optimal Firebase subdirectory {string}
#' @param token The user access token that can be retrieved with the auth() function. Required when if the database rules specify the need for user authentications. {string}
#' @return returns http request answer which includes the random key.
#' @export
#' @examples
#' \dontrun{
#' upload(x = mtcars, projectURL = "https://firedata-b0e54.firebaseio.com/", directory = "main")
#' }
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
#' @examples
#' \dontrun{
#' download(projectURL = "https://firedata-b0e54.firebaseio.com/", fileName = "main/-KxwWNTVdplXFRZwGMkH")
#' }
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
#' @examples
#' \dontrun{
#' dataBackup(projectURL = "https://firedata-efa5a.firebaseio.com", secretKey = "2bYA6k72wKna90MqPGa6yuMG7jAysoDJZwJqYXsm", "test.json")
#' }

dataBackup <- function(projectURL, secretKey="prompt", fileName){
  if (secretKey == "prompt") {
    secretKey <- readline(prompt = "secretKey: ")
    print(paste0("Connecting to",  project_api, ":"))
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
#' @examples
#' \dontrun{
#' auth(projectAPI = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc", email = "robin@kohze.com", password = "12341234")
#' }
auth <- function(projectAPI, email="prompt", password="prompt"){
  if (password == "prompt" && email == "prompt") {
        email <- readline(prompt = "Email: ")
        password <- readline(prompt = "Password: ")
        print(paste0("Connecting to",  project_api, ":"))
  }
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=", projectAPI)
  userData = httr::POST(url = AuthUrl, body = list("email" = email, "password" = password, "returnSecureToken" = "True"), encode = "json")
  return(httr::content(userData))
}

#' @title The anonymous login function:
#' @author Paul Spende
#' @description fireData::anonymous_login signs in a user anonymously.
#' @param project_api The Firebase Project API {string}
#' @return Returns the content of the firebase API request, such as the idToken, the refreshToken, and the localId.
#' @export
#' @examples
#' \dontrun{
#' anonymous_login(project_api = AIzaSyAYX_RxenP08jWpHExzsZIaO3CXeZhUSW8)
#' }
anonymous_login <- function(project_api) {
  anonymous_login_url <- paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=", project_api)
  anonymous_login_data <- httr::POST(url = anonymous_login_url, body = list("returnSecureToken" = "True"), encode = "json")
  return(httr::content(anonymous_login_data))
}

#' @title The OAuth login function:
#' @author Paul Spende
#' @description fireData::o_auth_login signs in a user with OAuth credentials.
#' @param project_api The Firebase Project API {string}
#' @param request_uri The URI to which the IDP redirects the user back. {string}
#' @param post_body Contains the OAuth credential (an ID token or access token) and provider ID which issues the credential. {string}
#' @param return_idp_credential Whether to force the return of the OAuth credential on the following errors: FEDERATED_USER_ID_ALREADY_LINKED and EMAIL_EXISTS. {boolean}
#' @return Returns the content of the firebase API request, such as the idToken, the refreshToken, and the localId.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
o_auth_login <- function(project_api, request_uri, post_body, return_idp_credential){
  o_auth_login_url <- paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyAssertion?key=", project_api)
  o_auth_login_data <- httr::POST(url = o_auth_login_url, body = list("requestUri" = request_uri, "postBody" = post_body, "returnSecureToken" = "True", "returnIdpCredential" = return_idp_credential), encode = "json")
  httr::content(o_auth_login_data)
}

#' @title The OAuth login function for google:
#' @author Paul Spende
#' @description fireData::google_login signs in a user with OAuth credentials.
#' @param project_api The Firebase Project API {string}
#' @param request_uri The URI to which the IDP redirects the user back. {string}
#' @param redirect_uri The URI to be redirected after the authentification. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @param return_idp_credential Whether to force the return of the OAuth credential on the following errors: FEDERATED_USER_ID_ALREADY_LINKED and EMAIL_EXISTS. {boolean}
#' @param cache Cache the tokens in the .httr-oauth file or not. {boolean}
#' @return Returns the content of the firebase API request, such as the idToken, the refreshToken, and the localId.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
google_login <- function(project_api, web_client_id = "prompt", web_client_secret = "prompt", request_uri, redirect_uri = oauth_callback(), return_idp_credential=TRUE, cache = FALSE){
  if (web_client_id == "prompt" && web_client_secret == "prompt") {
    web_client_id <- readline(prompt = "Web Client ID: ")
    web_client_secret <- readline(prompt = "Web Client Secret: ")
    print(paste0("Connecting to",  project_api, ":"))
  }

  myapp <- httr::oauth_app("google",
                     key = web_client_id,
                     secret = web_client_secret,
                     redirect_uri = redirect_uri)

  google_token <- oauth2.0_token(oauth_endpoints("google"), myapp,
                                 scope = "https://www.googleapis.com/auth/userinfo.profile",
                                 cache = cache)

  pbody <- paste0("id_token=", google_token$credentials$id_token, "&providerId=google.com")

  o_auth_login(project_api = project_api, request_uri = request_uri, post_body = pbody, return_idp_credential = return_idp_credential)
}

#' @title The OAuth function to get read/write access to the storage:
#' @author Paul Spende
#' @description fireData::google_devstorage_read_write retrieves a token with read/write access to the storage.
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns the token data.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
google_devstorage_read_write <- function(web_client_id = "prompt", web_client_secret = "prompt") {
  if (web_client_id == "prompt" && web_client_secret == "prompt") {
    web_client_id <- readline(prompt = "Web Client ID: ")
    web_client_secret <- readline(prompt = "Web Client Secret: ")
  }

  myapp <- oauth_app("google",
                     key = web_client_id,
                     secret = web_client_secret)

  oauth2.0_token(oauth_endpoints("google"), myapp,
                 scope = "https://www.googleapis.com/auth/devstorage.read_write")
}

#' @title The OAuth function to get read access to the storage:
#' @author Paul Spende
#' @description fireData::google_devstorage_read_only retrieves a token with read access to the storage.
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns the token data.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
google_devstorage_read_only <- function(web_client_id = "prompt", web_client_secret = "prompt") {
  if (web_client_id == "prompt" && web_client_secret == "prompt") {
    web_client_id <- readline(prompt = "Web Client ID: ")
    web_client_secret <- readline(prompt = "Web Client Secret: ")
  }

  myapp <- oauth_app("google",
                     key = web_client_id,
                     secret = web_client_secret)

  oauth2.0_token(oauth_endpoints("google"), myapp,
                 scope = "https://www.googleapis.com/auth/devstorage.read_only")
}

#' @title The OAuth function to get access to the cloud firestore:
#' @author Paul Spende
#' @description fireData::google_firestore retrieves a token with read access to the cloud firestore
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns the token data.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
google_firestore <- function(web_client_id = "prompt", web_client_secret = "prompt") {
  if (web_client_id == "prompt" && web_client_secret == "prompt") {
    web_client_id <- readline(prompt = "Web Client ID: ")
    web_client_secret <- readline(prompt = "Web Client Secret: ")
  }

  myapp <- oauth_app("google",
                     key = web_client_id,
                     secret = web_client_secret)

  oauth2.0_token(oauth_endpoints("google"), myapp,
                 scope = "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/cloud-platform")
}

#' @title Firebase user creation function
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @param password The user password {string}
#' @description Creates a new firebase user account. All user accounts can accessed at the firebase.com project console. One of the advantages of firebase accounts in R is the ability to access a website and analyse the data of the website with the very same login.
#' @return Registers a new user and returns the status.
#' @export
#' @examples
#' \dontrun{
#' createUser(projectAPI = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc", email = "your@email.com", password = "12341234" )
#' }
createUser <- function(projectAPI, email="prompt", password="prompt"){
  if (password == "prompt" && email == "prompt") {
    email <- readline(prompt = "Email: ")
    password <- readline(prompt = "Password: ")
    print(paste0("Connecting to",  project_api, ":"))
  }
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=", projectAPI)
  userData = httr::POST(url = AuthUrl, body = list("email" = email, "password" = password), encode = "json")
  httr::content(userData)
}

#' @title Password resett function:
#' @param projectAPI The Firebase Project API {string}
#' @param email The user email {string}
#' @description Resets the user password and sends an email to the user account.
#' @return Success or warning message.
#' @export
#' @examples
#' \dontrun{
#' resetPassword(projectAPI = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc", email = "useYourOwn@email.com")
#' }
resetPassword <- function(projectAPI, email){
  AuthUrl = paste0("https://www.googleapis.com/identitytoolkit/v3/relyingparty/getOobConfirmationCode?key=", projectAPI)
  userData = httr::POST(url = AuthUrl, body = list("email" = email, "requestType" = "PASSWORD_RESET"), encode = "json")
  if ("error" %in% names(httr::content(userData))) {
    warning(paste0("User email ", email, " was not found in the database"))
  } else {
    print(paste0("Password reset email was send to ", email))
  }
}

#' @title The upload function for firebase storage:
#' @author Paul Spende
#' @description fireData::upload_storage uploads a file to the firebase storage.
#' @param bucket_name The name of your storage bucket. {string}
#' @param object_name The name you want to give your file in the storage. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @param file_path The path of the file you want to upload, leave this empty to create a folder. {string}
#' @param predefined_acl The predefined set of access controls. (authenticatedRead, bucketOwnerFullControl, bucketOwnerRead, private, projectPrivate, publicRead) {string}
#' @return Returns the storage object informations.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
upload_storage <-
  function(bucket_name,
           object_name,
           web_client_id = "prompt",
           web_client_secret = "prompt",
           file_path = NULL,
           predefined_acl = "publicRead") {
    google_token <-
      google_devstorage_read_write(web_client_id, web_client_secret)

    upload_url <-
      paste0(
        'https://www.googleapis.com/upload/storage/v1/b/',
        bucket_name,
        '/o?uploadType=media&name=',
        object_name,
        '&predefinedAcl=',
        predefined_acl
      )

    headers <- c("Authorization" = paste("Bearer", google_token$credentials$access_token))

    if (is.null(file_path)) {
      response <- httr::POST(url = upload_url,
                             add_headers(
                               headers
                             ))
    } else {
      response <- httr::POST(
        url = upload_url,
        body = upload_file(file_path),
        add_headers(
          headers
        )
      )
    }

    data <- httr::content(response)
    data['url'] <- paste('https://storage.cloud.google.com', bucket_name, object_name, sep = '/')

    data
  }

#' @title The delete function for firebase storage:
#' @author Paul Spende
#' @description fireData::delete_storage deletes the file in the firebase storage bucket.
#' @param bucket_name The name of your storage bucket. {string}
#' @param object_name The name of the file that you want to delete from the bucket. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns NULL when successful.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
delete_storage <- function(bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt"){
  google_token <- google_devstorage_read_write(web_client_id, web_client_secret)

  upload_url <- paste0('https://www.googleapis.com/storage/v1/b/', bucket_name,
                       '/o/', object_name)

  response <- httr::DELETE(url = upload_url,
                           add_headers("Authorization" = paste("Bearer", google_token$credentials$access_token)))

  httr::content(response)
}

#' @title The list function for firebase storage:
#' @author Paul Spende
#' @description fireData::list_storage lists all files in the firebase storage bucket.
#' @param bucket_name The name of your storage bucket. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns the storage object informations for all files in the bucket.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
list_storage <- function(bucket_name, web_client_id = "prompt", web_client_secret = "prompt"){
  google_token <- google_devstorage_read_only(web_client_id, web_client_secret)

  upload_url <- paste0('https://www.googleapis.com/storage/v1/b/', bucket_name, '/o')

  response <- httr::GET(url = upload_url,
                        add_headers("Authorization" = paste("Bearer", google_token$credentials$access_token)))

  httr::content(response)
}

#' @title The get function for firebase storage:
#' @author Paul Spende
#' @description fireData::get_storage lists all files in the firebase storage bucket.
#' @param bucket_name The name of your storage bucket. {string}
#' @param object_name The name of the file that you want to get from the bucket. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns the storage object ressource for the file in the bucket.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
get_storage <- function(bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt"){
  google_token <- google_devstorage_read_only(web_client_id, web_client_secret)

  upload_url <- paste0('https://www.googleapis.com/storage/v1/b/', bucket_name,
                       '/o/', object_name)

  response <- httr::GET(url = upload_url,
                        add_headers("Authorization" = paste("Bearer", google_token$credentials$access_token)))

  httr::content(response)
}

#' @title The get the url for an object in storage (e.g. an htmk file):
#' @author Paul Spende
#' @description fireData::get_url outputs the url to access the object in storage.
#' @param bucket_name The name of your storage bucket. {string}
#' @param object_name The name of the file that you want to get from the bucket. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns the url for the storage object.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
get_url <- function(bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt"){
  object_ressources <- get_storage(bucket_name, object_name, web_client_id, web_client_secret)

  paste0(
    "https://firebasestorage.googleapis.com/v0/b/",
    bucket_name,
    "/o/",
    object_name,
    "?alt=media&token=",
    object_ressources$metadata$firebaseStorageDownloadTokens
  )
}

#' @title This function uploads a local folder to the storage bucket::
#' @author Paul Spende
#' @description fireData::upload_folder uploads all files in the folder to the firebase storage bucket.
#' @param bucket_name The name of your storage bucket. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @param folder_path The path to the folder on the local machine. {string}
#' @return Returns list of storage object ressources of all the files uploaded in the bucket.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
upload_folder <- function(bucket_name, web_client_id = "prompt", web_client_secret = "prompt", folder_path) {
  files <- list.files(path = folder_path, full.names = FALSE, recursive = TRUE)

  google_token <- google_devstorage_read_write(web_client_id, web_client_secret)

  responses <- list()

  for (file in files) {
    object_name <- paste0(folder_path, "/", file)

    print(object_name)

    upload_url <- paste0('https://www.googleapis.com/upload/storage/v1/b/', bucket_name,
                         '/o?uploadType=media&name=', file)

    response <- httr::POST(url = upload_url,
                           body = upload_file(paste0(folder_path, "/", file)),
                           add_headers("Authorization" = paste("Bearer", google_token$credentials$access_token)))

    list.append(responses, response)
  }

  responses
}

#' @title This function complies a rmarkdown file to html and uploads it to the storage bucket::
#' @author Paul Spende
#' @description fireData::deploy_rmarkdown deploys rmarkdown file to the firebase storage bucket.
#' @param rmarkdown_path The path to the rmarkdown files. {string}
#' @param bucket_name The name of your storage bucket. {string}
#' @param object_name The name of the file that you want to get from the bucket. {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @return Returns list of storage object ressources of all the files uploaded in the bucket.
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
deploy_rmarkdown <- function(rmarkdown_path, bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt") {
  html_file <-
    render(input = rmarkdown_path, output_format = "html_document")

  upload_storage(
    bucket_name = bucket_name,
    web_client_id = web_client_id,
    web_client_secret = web_client_secret,
    object_name = object_name,
    file_path = html_file
  )
}

#' @title This function creates short dynamic links::
#' @author Paul Spende
#' @description fireData::get_dynamic_link creates a short link for a longer one.
#' @return Returns json object with short url and further information.
#' @param project_api The Firebase Project API {string}
#' @param domain The Firebase dynamic link domain {string}
#' @param link The URL you want to shorten {string}
#' @param short Flag to generate a short url (TRUE) or an unguessable url (FALSE). {boolean}
#' @param social_title The title of the link preview. {string}
#' @param social_description The description of the link preview. {string}
#' @param social_image_link The URL to the image shown in the preview of the link. {string}
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
get_dynamic_link <-
  function(project_api,
           domain,
           link,
           short = TRUE,
           social_title = "",
           social_description = "",
           social_image_link = "") {
    option <- ifelse(short, "SHORT", "UNGUESSABLE")
    url <-
      paste0('https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=',
             project_api)
    response <-
      httr::POST(
        url = url,
        body = list(
          "dynamicLinkInfo" = list(
            "dynamicLinkDomain" = domain,
            "link" = link,
            "socialMetaTagInfo" = list(
              "socialTitle" = social_title,
              "socialDescription" = social_description,
              "socialImageLink" = social_image_link
            )
          ),
          "suffix" = list("option" = option)
        ),
        encode = "json"
      )
    httr::content(response)
  }

#' @title This function creates a login overlay for a shiny application::
#' @author Paul Spende
#' @description fireData::shiny_auth creates a short link for a longer one.
#' @return Returns a functional login overlay.
#' @param user A flag if user is logged in or not. E.g.   USER <- reactiveValues(Logged = FALSE) {reactiveValues}
#' @param input The input to the shiny server. {input}
#' @param credentials If the email and password login should be available. {boolean}
#' @param goauth If google OAuth login should be available. {boolean}
#' @param anonymous If the anonymous login should be available. {boolean}
#' @param project_api The Firebase Project API {string}
#' @param web_client_id The Web Client ID of your Google OAuth in your Firebase. {string}
#' @param web_client_secret The Web Client Secret of your Google OAuth in your Firebase. {string}
#' @param request_uri The URI to which the IDP redirects the user back. {string}
#' @export
#' @examples
#' \dontrun{
#' TODO:
#' }
shiny_auth_server <-
  function(user,
           input,
           credentials = TRUE,
           goauth = TRUE,
           anonymous = TRUE,
           project_api = NULL,
           web_client_id= NULL,
           web_client_secret = NULL,
           request_uri = NULL) {

    if(anonymous) {
      observeEvent(input$.anonymous, {
        token <-
          anonymous_login(project_api = project_api)
        if (exists("idToken", where = token)) {
          user$Logged <- TRUE
        } else {
          show("message")
          output$message = renderText("Invalid user name or password")
          delay(2000, hide("message", anim = TRUE, animType = "fade"))
        }
      })
      insertUI(
        selector = "#login",
        where = "afterBegin",
        ui = div(actionButton(".anonymous", "Anonymous login"), style =
              "text-align: center;")
      )
    }

    if(goauth) {
      observeEvent(input$.goauth, {
        token <-
          google_login(
            project_api = project_api,
            web_client_id = web_client_id,
            web_client_secret = web_client_secret,
            request_uri = request_uri
          )
        if (exists("oauthIdToken", where = token)) {
          user$Logged <- TRUE
        } else {
          show("message")
          output$message = renderText("Invalid user name or password")
          delay(2000, hide("message", anim = TRUE, animType = "fade"))
        }
      })
      insertUI(
        selector = "#login",
        where = "afterBegin",
        ui = div(actionButton(".goauth", "Google login"), style =
                   "text-align: center;")
      )
    }

    if(credentials) {
      observeEvent(input$.login, {
        token <-
          auth(
            projectAPI = project_api,
            email = input$.username,
            password = input$.password
          )
        if (exists("idToken", where = token)) {
          user$Logged <- TRUE
        } else {
          show("message")
          output$message = renderText("Invalid user name or password")
          delay(2000, hide("message", anim = TRUE, animType = "fade"))
        }
      })
      insertUI(
        selector = "#login",
        where = "afterBegin",
        ui = tagList(
          textInput(".username", "Username:"),
          passwordInput(".password", "Password:"),
          div(actionButton(".login", "Login"), style =
                "text-align: center;")
        )
      )
    }

  fluidRow(column(
    width = 4,
    offset = 4,
    wellPanel(
      id = "login"
    ),
    textOutput("message")
  ))
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

