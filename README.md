![fireData](http://frapbot.kohze.com/fireData/topImage6.jpg)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/paulsp94/fireData/master/LICENSE.txt)
[![Build Status](https://travis-ci.org/Kohze/fireData.svg?branch=master)](https://travis-ci.org/paulsp94/fireData)
[![codecov](https://codecov.io/gh/Kohze/fireData/branch/master/graph/badge.svg)](https://codecov.io/gh/paulsp94/fireData)

**Adding Web Functionalities for Shiny and enabling RMarkdown and HTMLWidget hosting on firebase**

--- 

FireData integrates R Datascience with the abilities and possibilities of the Google Firebase Framework.

Firebase makes it possible to exchange in real-time information in the Cloud and thereby opening the R language to IoT hardware/data processing. Other than that it is also immensely useful for shiny application to integrate Social Authentications and persistent data & uploads.

This package was created within the framework of Google Summer of Code 2017. 

![fireData](http://frapbot.kohze.com/fireData/setup2.jpg)

**Firebase Setup:**
- visit at https://firebase.google.com/
- login and enter the "console"
- add new project
- find the API keys and projectID at the "overview" page clicking on add firebase to web-app
- certain functions requires OAuth 2.0 access which needed client_id and client_secret, these can be found from https://console.developers.google.com/apis/credentials

**R Package Setup:**

```
if (!require("devtools")) install.packages("devtools")
devtools::install_github("paulsp94/fireData")

library(fireData)
```

![examples](http://frapbot.kohze.com/fireData/examples2.jpg)

- using Google OAuth login

```r
google_login(project_api = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc", 
request_uri = "https://firedata-b0e54.firebaseio.com/")
```



![fireData](http://frapbot.kohze.com/fireData/related2.jpg)

fireData is already integrated into a several projects. 

- SpatialMaps: A spatial proteomics platform that utilizes firebase as cross platform database.

- Cryptotrade-hq bot: A simple data collector (with shiny) that uses firebase for secure storage of API keys.


![fireData](http://frapbot.kohze.com/fireData/development2.jpg)

We are currently applying for a Google Summer of Code grant to support a student during the summer month to develop the package further. Feel free to apply. 

---

**Aknowledgements:**

I hereby want to thank my GSOC mentors L. Pedraza, S. Schmidt for their project support and especially L. Gatto for his insights and experience to make this package a reality. 
