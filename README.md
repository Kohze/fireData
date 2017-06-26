#### FireData

[![Build Status](https://travis-ci.org/Kohze/FireData.svg?branch=master)](https://travis-ci.org/Kohze/FireData)

Milestone 1 (25-06-2017):

[x] user authentication
[x] general API functionality (upload, download)
[x] user registration/pw resett
[x] token generation

---

FireData integrates R Datascience with the abilities and possibilities of the Google Firebase Framework.

Firebase makes it possible to exchange in real-time information in the Cloud and thereby opening the R language to IoT hardware/data processing. Other than that it is also immensely useful for shiny application to integrate Social Authentications and persistent data & uploads.

---

**Project Title:** FireData: Connecting R to Google Firebase

**short title:** Creating a Firebase API

##### Background

Persistent Data Storage and transfer with R can be complicated and time consuming. While there are great packages to connect R to DBs like mySQL/sqlLite/postgreSQL those databases itself need to be hosted and maintained. To implement a DB based login system in Shiny now probably takes 2 weeks of work to get it done in a secure way, and a IoT project for data collection requires a 24/7 running server. 

The Google team took that common problem (not only of R) and created Firebase. Firebase is a online database that is not only intuitive to integrate into Apps & Web applications, but can also be used to build user registration/login systems with persistent data storage (thinking about shiny) or to transfer data between IoT devices via Firebase directly to a R environment. Writing a intuitive R to Firebase connector enables R to be used in new "cross platform" realtime applications. Thats why we strongly believe the "FireData" package will improve the R open source environment. 

##### Related work

The R universe offers with the ```httr``` package to apply PUT/POST commands to servers (including Firebase). In combination with a JSON library like ```jsonlite``` it is possible to send & retrieve data from Firebase.

Google Firebase on the contrary is more sophisticated than simple PUT/POST requests and allows JWT tokenizations, registrations & logins and even file uploads. Firebase brings all functionality and ease to be the to-go Database for R IoT or Shiny related projects. 

##### Details of your coding project

With the experience of GSOC 2016 we will start with a larger team (other open source developers signaled it would help to improve their own DB experience working with R and Shiny) to get the FireData package CRAN ready before the September deadline.

 - Now - April : Adding prove of concepts of the Firebase integration into Shiny and IoT applications. 
 - April - June : Writing and implementing (including unit test) the various firebase connecting functions
 - June - July : Adding the s4 classes/functions to the FireData package & writing Vignettes/Documentation
 - July - August : Finishing up the FireData package with focus on OS compatibility testing and identifiying and possible fixing weakpoints of the package. 

##### Expected impact

R is one of the strongest players in data science. The aim is to connect its strength in data analysis with the actual data. By making it easier to directly connect R to the inputs of IoT devices or other applications such as websites/shiny it will open new possibilities for open source developers around the world. 

The final product, the FireData package, will connect two great environments with each other. When we succeed to make it stable & intuitive alot of projects will be build ontop of it. 

##### Management of Coding Project

Daily submits to the github repo. The project will be started in a test-driven fashion by writing "testhat" tests for every method implemented. For the Firebase testing we will accordingly create a test database (firebase allows to upload xml database mirrors which correspond to real db environments). 

##### Risks/Challenges & opportunities:

Implementing the 3rd party Firebase API can always bear the challenge of sudden new features or changes to its functionality. Due to the large userbase of firebase and the versioning we are pretty sure to complete the task staying at the same firebase version (firebase 2/firebase3 had breaking changes). One opportunity is that a recent change added firebase function calls which are especially interesting for our project as it allows firebase to trigger on certain data events to send data to R applications.  

##### Required Skills

Knowledge of noSQL databases (Google Firebase is a noSQL database), experience with package development (roxygen2) including unit testing (testhat) and S4 Classes. In addition a general understanding of APIs & server architecture is required.  

##### Proof of concept / Test for the student: 

 - A tutorial on Shiny & Google Firebase Logins written by the student https://r.codes/ItemPreview/-KaLAwn-zqMgARFUnxpo
 - proof that student can create R packages with roxygen2 and devtools: https://github.com/Kohze/Discovr
 - proof that student can create unit tests (testhat package) https://github.com/Kohze/misc/tree/master/unitTesting

##### Mentors

Samuel Schmidt, Ph.D . (has GSOC Mentor experience). | samuelschmidt218@gmail.com

Lindolfo Pedraza, MA. (Database and API specialist) | lindolfo.pedraza@gmail.com


##### Student

Robin Kohze | pi2robin@gmail.com

https://github.com/Kohze | Project leader of https://R.Codes | GSOC student of 2016 with the discovr package 

Student affiliation:
* Institution: Radboud University Nijmegen
* Program: Medical Epigenomics
* Stage of completion: Master | 1st year 
* Contact to verify: Can provide official documents
