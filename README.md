#### FireData

---

FireData integrates R Datascience with the abilities and possibilities of the Google Firebase Framework. 

Firebase makes it possible to exchange in realtime information in the Cloud and thereby opening the R language to IoT hardware/data processing. Other than that it is also imensly usefull for shiny application to integrate Social Authentications and persistent data & uploads. 

---

The first step is now a proov of concept, that we can save data.frames/vectors in the Firebase DB (as JSON) and retrive them again in a speedwise meaningful way. 


List do to as proof of concept:

- [X] Adding Firebase to a shiny application to integrate Social Authentication
- [ ] writing function to quickly communicate data between the local application and the firebase DB
- [ ] allowing R to compare User IDs registered in firebase with a given UserID pair (from shiny) to get a server side protection