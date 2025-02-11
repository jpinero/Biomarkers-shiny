library(shiny)
library(RMariaDB)
library(DT)
library(shinycssloaders)
library(dplyr)
library(bslib)
library(pool)
library(kableExtra)
pool <- dbPool(
  drv = MariaDB(),
  host = "localhost",
  username = "janet",
  password = "",
  dbname = "biomarkers_2022",
  port = 3306
)
onStop(function() {
  poolClose(pool)
})

loadData <- function(db, table) {
  data <- tbl(db, table)
  return(data)
}

createLink_Button <- function(text){
  paste0('<button type="button" style="width: 100%; display:block;"
         class="btn btn-success action-button">', text, '</button>')
}

createLink_Symbol <- function(geneid, symbol){
  sprintf('<a href="https://www.ncbi.nlm.nih.gov/gene/%s" target="_blank">%s</a>',geneid, symbol)
}

createLink_Name <- function(diseaseid, name){
  sprintf('<a href="https://meshb.nlm.nih.gov/record/ui?ui=%s" target="_blank">%s</a>',diseaseid, name)
}


createLink_NCIT <- function(nctid){
  sprintf('<a href="https://clinicaltrials.gov/ct2/show/%s" target="_blank">%s</a>',nctid, nctid)
}

createLink_PMID <- function(pmid){
  sprintf('<a href=https://pubmed.ncbi.nlm.nih.gov/%s" target="_blank">%s</a>',pmid, pmid)
}