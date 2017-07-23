#load packages
library(httr)
library(jsonlite)
library(pRoloc)
library(pRolocdata)

#project settings
dbURL <- "https://spatialmap-1b08e.firebaseio.com"

###### manual commands for testing purposes
#delete DB
path = "/raw"
path2 = "/meta"
path3 = "/data"

PUT(paste0(dbURL,path,".json"), body = toJSON(mtcars))
PUT(paste0(dbURL,path2,".json"), body = toJSON(mtcars))
PUT(paste0(dbURL,path3,".json"), body = toJSON(mtcars))

#cleaned dataset list
# b = as.data.frame(read.csv(file.choose()))
# b = as.vector(b[[2]])

#taking pRolocData MSnSet
# data(E14TG2aS1)
# tempPath = tempfile()
# saveRDS(E14TG2aS1, tempPath)
# binarySet = readBin(tempPath, what = "raw", n = 5000000)
# base64Set = toJSON(base64_enc(binarySet),raw = "hex")
#
# #adding content
# POST(paste0(dbURL,path,".json"), body = base64Set)
#
# #retrieving data
# data = GET(paste0(dbURL,path,".json"))
# retrievedData = content(data,"text")
# tempPath2 = tempfile()
# writeBin(base64_dec(fromJSON(retrievedData)), tempPath2)
# readRDS(tempPath2)

#pRolocdata list to vector
# for (i in 1:length(a)){
#   a[i] = head(strsplit(a[i], split = " ")[[1]],1)
# }
#
# b = a[nchar(a) > 2]
###### end of manual commands

#uploading all pRolocData MSnSets
for (i in b) {
  pRolocData = pRolocUpload(dataset = i,name = i)
}

#Adding datasets via command line
pRolocUpload <- function(dataset, name){
  #pRolocMetaData
  pRolocMeta = pRolocMetaFrame(eval(as.name(dataset)), varName = name)
  Response = POST(paste0(dbURL,"/meta",".json"), body = toJSON(pRolocMeta, auto_unbox = TRUE))
  #pRolocRawData
  pRolocRaw = pRolocRawData(eval(as.name(dataset)))
  PUT(paste0(dbURL,"/raw/",httr::content(Response),".json"), body = toJSON(pRolocRaw, auto_unbox = TRUE))
  #pRolocData
  pRolocDataVar = pRolocFData(eval(as.name(dataset)))
  PUT(paste0(dbURL,"/data/",httr::content(Response),".json"), body = toJSON(pRolocDataVar, auto_unbox = TRUE))
  #generateKeys
  keyCollection(eval(as.name(dataset)), httr::content(Response))
  #success message
  print(paste0(name, " got transfered to firebase."))
}

#Retrieving datasets from firebase
# pRolocLoad <- function(dataset){
#   dbURL <- "https://spatialmap-1b08e.firebaseio.com"
#   path <- paste0("/objects/", dataset)
#   #retrieving data
#   data = GET(paste0(dbURL,path,".json"))
#   retrievedData = httr::content(data,"text")
#   tempPath2 = tempfile()
#   writeBin(base64_dec(fromJSON(retrievedData)), tempPath2)
#   x <- readRDS(tempPath2)
#   assign(toString(as.name(dataset)), x, envir = .GlobalEnv)
#   return(paste0(dataset, " was transfered"))
# }

#testing datasets functionality, b is a list of all MSnBase names
# lapply(b, function(x) tryCatch(pRolocFire(x), error = function(e) NULL))

## firebaseQuality check - give a string like "hyperLOPID2015"
# firebaseQuality <- function(dName) {
#   #pRolocData
#   data(list = dName)
#   pRolocDataSet = eval(as.name(dName))
#   tempRoloc = tempfile()
#   saveRDS(pRolocDataSet, tempRoloc)
#   #Firebase Data
#   dbURL <- "https://spatialmap-1b08e.firebaseio.com"
#   path <- paste0("/objects/", dName)
#   data = GET(paste0(dbURL,path,".json"))
#   retrievedData = httr::content(data,"text")
#   tempFire = tempfile()
#   writeBin(base64_dec(fromJSON(retrievedData)), tempFire)
#
#   #comparing both objects
#   return(identical(toString(tools::md5sum(tempRoloc)), toString(tools::md5sum(tempFire))))
# }

## testing the whole DB, b is a vector of all MSnBase names
#lapply(b, function(x) tryCatch(firebaseQuality(x), error = function(e) NULL))

#testing plot2D for all datasets
#plotTest <- function(dName){
#  data = plot2D(eval(as.name(dName)), plot=FALSE)
#  return("works")
#}

# lapply(b, function(x) tryCatch(plotTest(x), warning = function(w) return(w), error = function(e) return(e)))

## store database
# backup = system('curl "https://spatialmap-1b08e.firebaseio.com/.json?auth=xLj9QCFBxbO47WHmg9lae8Riisn1l7WG2LalyIpV"', intern = TRUE)

# test for key naming
# PUT(paste0(dbURL,path,".json"), body = toJSON(unbox(data.frame("a" = "fives"))))

createColors <- function(object){
  markers = fData(object)$markers
  uniqueMarkers = unique(markers)
  markerVec = c()
  for(i in 1:length(uniqueMarkers)){
    markerColor = ifelse(uniqueMarkers[i] == "unknown", getStockcol(), getStockcol()[i])
    markerVec = c(markerVec, markerColor)
  }
  colorTable = data.frame(uniqueMarkers, markerVec, stringsAsFactors = FALSE)

  colorAssigment=unlist(sapply(markers, function(x) colorTable$markerVec[which(colorTable$uniqueMarkers == x)]))
  return(colorAssigment)
}

#extract data from MSnSet object
pRolocRawData <-function(object){
  #convert object to base64
  tempPath = tempfile()
  saveRDS(object, file = tempPath)
  binarySet = readBin(tempPath, what = "raw", n = 50000000)
  base64Set = jsonlite::base64_enc(binarySet)
  #adding key by assigning to data.frame
  pRolocList = list("base64Set" =  base64Set)
  return(pRolocList)
}

pRolocFData <- function(object){
  pcaData = as.data.frame(plot2D(object, plot = FALSE))

  fScatter = data.frame("PCA1" = pcaData[[1]],
                        "PCA2" = pcaData[[2]],
                        "Colors" = createColors(object))
  fSetData = fData(object)

  for (i in 1:length((fSetData))){
    if (i == 1){
      p = data.frame(fSetData[[i]])
    } else {
      p = data.frame(p, fSetData[[i]])
    }
  }

  #filtering forbidden keys
  originalNames = names(fSetData)
  originalNames = gsub("\\$","-", originalNames)
  originalNames = gsub("\\#","-", originalNames)
  originalNames = gsub("\\]","-", originalNames)
  originalNames = gsub("\\[","-", originalNames)
  originalNames = gsub("\\/","-", originalNames)
  originalNames = gsub("\\.","-", originalNames)
  names(p) = originalNames

  p = cbind(p, data.frame("id" = row.names(fSetData)))
  fSet = cbind(fScatter,p)

  exprsSet = exprs(object)
  exprsSet = cbind(exprsSet, data.frame("id" = row.names(exprsSet)))
  row.names(exprsSet) = NULL

  originalNames2 = names(exprsSet)
  originalNames2 = gsub("\\$","-", originalNames2)
  originalNames2 = gsub("\\#","-", originalNames2)
  originalNames2 = gsub("\\]","-", originalNames2)
  originalNames2 = gsub("\\[","-", originalNames2)
  originalNames2 = gsub("\\/","-", originalNames2)
  originalNames2 = gsub("\\.","-", originalNames2)
  names(exprsSet) = originalNames2

  pRolocList = list("fSet" = fSet, "exprsSet" = exprsSet)
  return(pRolocList)
}

pRolocMetaFrame <- function(object, varName){
  #meta
  #varName = "varName"
  title =  object@experimentData@title
  author = object@experimentData@name
  email = object@experimentData@email
  contact = object@experimentData@contact
  dataStamp = object@experimentData@dateStamp
  abstract = object@experimentData@abstract
  lab = object@experimentData@lab
  pubMedIds = object@experimentData@pubMedIds

  tissue = object@experimentData@samples$tissue
  cellLine = object@experimentData@samples$cellLine
  species = object@experimentData@samples$species
  operator = object@experimentData@samples$operator

  markerClasses = toString(pRoloc::getMarkerClasses(object))
  featureNames = toString(featureNames(object))

  #List generation
  pRolocList = list("varName" = varName,
                    "title" = title,
                    "author" = author,
                    "email" = email,
                    "contact" = contact,
                    "dataStamp" = dataStamp,
                    "abstract" = abstract,
                    "lab" = lab,
                    "pubMedIds" = pubMedIds,
                    "tissue" = tissue,
                    "cellLine" = cellLine,
                    "species" = species,
                    "operator" = operator,
                    "markerClasses" = markerClasses,
                    "featureNames" = featureNames
  )

  return(pRolocList)
}

keyCollection <- function(dataset, rndKey){
  fSet = fData(dataset)
  idNames = row.names(fSet)
  keyPair = list("key" = rndKey)
  for (i in 1:length(idNames)) {
    POST(paste0(dbURL,"/keys/",idNames[i],".json"), body = toJSON(keyPair, auto_unbox = TRUE))
  }
}


