![fireData](http://frapbot.kohze.com/fireData/topImage6.jpg)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/paulsp94/fireData/master/LICENSE.txt)
[![Build Status](https://travis-ci.org/Kohze/fireData.svg?branch=master)](https://travis-ci.org/paulsp94/fireData)
[![codecov](https://codecov.io/gh/Kohze/fireData/branch/master/graph/badge.svg)](https://codecov.io/gh/paulsp94/fireData)

**Adding Web Functionalities for Shiny and enabling RMarkdown and HTMLWidget hosting on firebase**

--- 

FireData integrates R Datascience with the abilities and possibilities of the Google Firebase Framework.

Firebase makes it possible to exchange in real-time information in the Cloud and thereby opening the R language to IoT hardware/data processing. Other than that it is also immensely useful for shiny application to integrate Social Authentications and persistent data & uploads.

This project implements various authentification methods, multiple functions to handle files in the firebase (google) storage, a deployment operation for RMarkdown files and a shiny integration for the authentification methods. All commits made during this project can be found [here](https://github.com/paulsp94/fireData/commits?author=paulsp94).

These improvements were created within the framework of Google Summer of Code 2018. 

**Things to be done in the future**

- test coverage for OAuth based methods

- improve shiny_auth_server UI with CSS/HTML

![fireData](http://frapbot.kohze.com/fireData/setup2.jpg)

**Firebase Setup:**
- visit at [https://firebase.google.com/](https://firebase.google.com/)
- login and enter the "console"
- add new project
- find the API keys and projectID at the "overview" page clicking on add firebase to web-app
- certain functions requires OAuth 2.0 access which needed client_id and client_secret, these can be found from the [google developer console](https://console.developers.google.com/apis/credentials)

**R Package Setup:**

```
if (!require("devtools")) install.packages("devtools")
devtools::install_github("paulsp94/fireData")

library(fireData)
```

![examples](http://frapbot.kohze.com/fireData/examples2.jpg)

**Authentification**

- using anonymous login

```r
token <- anonymous_login(project_api = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc")

token$idToken
```

- using Google OAuth login

```r
token <- google_login(project_api = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc", 
                      request_uri = "https://firedata-b0e54.firebaseio.com/")
                      
token$oauthIdToken
```

- getting access token for Google Firestore

```r
token <- google_firestore()

token$credentials$access_token
```

**Storage**

- upload a file to firebase (google) storage

```r
metadata <- upload_storage(bucket_name = "firedata-b0e54.appspot.com",
                           object_name = "myObject", 
                           file_path =  "./index.html")
                           
metadata$url
```

holds the URL of the uploaded file, to view it in the browser.

It is also possible to integrate a folder structure in the object_name:

```r
upload_storage(bucket_name = "firedata-b0e54.appspot.com",
               object_name = "test/myObject", 
               file_path =  "./index.html")
```

- delete a file from firebase (google) storage

```r
delete_storage(bucket_name = "firedata-b0e54.appspot.com",
               object_name = "myObject")
```

- list all files on firebase (google) storage

```r
files <- list_storage(bucket_name = "firedata-b0e54.appspot.com")
```

- get a files metadata from firebase (google) storage

```r
object_metadata <- get_storage(bucket_name = "firedata-b0e54.appspot.com",
                               object_name = "myObject")
```

- upload a folder structure with all files to firebase (google) storage

```r
upload_folder(bucket_name = "firedata-b0e54.appspot.com",
              folder_path =  "./myPage/")
```

**Hosting**

- deploy an RMarkdown file to firebase

```r
metadata <- deploy_rmarkdown(rmarkdown_path = "./index.Rmd",
                             bucket_name = "firedata-b0e54.appspot.com",
                             object_name = "rmarkdown")

metadata$url
```

return the URL to the html page on firebase.

- get a dynamic link for a given link

```r
get_dynamic_link(project_api = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc", 
                 link = "https://firebasestorage.googleapis.com/v0/b/fir-abf00.appspot.com/o/interactive?alt=media&token=74c8f4cf-6299-4d92-9179-e778f0c40b1b", 
                 domain = "rdashboard.page.link")
```

setting the flag *short* to FALSE in the parameters will result in an UNGUESSABLE , which consists out of the domain and a 17 characters path component. By default this functions returns a short link, where the path components only contains 4 characters.

Additionally it is possible to define the social media meta tags using *social_title*, *social_description* and *social_image_link*.

Before you can use this function you have to configure firebase for dynamic links. Have a look at https://firebase.google.com/docs/dynamic-links/rest#create_a_short_link_from_parameters on the section **Before you begin**.

**Shiny integration**

With the shiny_auth_server function it is possible to secure a shiny app with various authentification methods like username/password combination, Google OAuth or anonymous login. The following example shows how to implement a authentification process for your shiny app.

```r  
library(shiny)
library(fireData)

## app.R ##
server <- function(input, output) {
  USER <- reactiveValues(Logged = FALSE)

  output$app = renderUI(if (!isTRUE(USER$Logged)) {
    shiny_auth_server(
      USER,
      input,
      output,
      project_api = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc",
      web_client_id = WEBCLIENTID,
      web_client_secret = WEBCLIENTSECRET,
      request_uri = "https://firedata-b0e54.firebaseapp.com/"
    )
  } else {
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          sliderInput("obs", "Number of observations:", min = 10, max = 500, value = 100)
        ),
        mainPanel(plotOutput("distPlot"))
      )
    )
  })

  output$distPlot <- renderPlot({
    hist(rnorm(input$obs), col = 'darkgray', border = 'white')
  })
}

ui <- fluidPage(
    titlePanel("Password protected Shiny app"),

    uiOutput("app")
)

shinyApp(ui = ui, server = server)
```

![fireData](http://frapbot.kohze.com/fireData/related2.jpg)

fireData is already integrated into a several projects. 

- SpatialMaps: A spatial proteomics platform that utilizes firebase as cross platform database.

- Cryptotrade-hq bot: A simple data collector (with shiny) that uses firebase for secure storage of API keys.


![fireData](http://frapbot.kohze.com/fireData/development2.jpg)

**Acknowledgements:**

I hereby want to thank my GSOC mentors S. Schmidt, L. Gatto, B. Jehoul for their project support and especially Robin Kohze for his continuous guidance and insights into the problems and possible solutions to make this project a reality. I also want to thank my collegue Jiasheng Zhu for the good teamwork. 
