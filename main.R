################# Get config #################

library(config)
config <- config::get()

##############################################
############### BIGQUERY ACCESS ##############
##############################################

install.packages("bigrquery")
library(bigrquery)

bigrquery::bq_auth()

project_id <- config$default$project_id

############## String Libraries ##############

install.packages("readr")
install.packages("glue")

library(readr)
library("glue")