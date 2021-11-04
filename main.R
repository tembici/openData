################# Get config #################

library(config)
config <- config::get()

library(lubridate)
full.date <- Sys.Date() - months(1)

initial_date <- floor_date(full.date, "month")

##############################################
############### BIGQUERY ACCESS ##############
##############################################

library(bigrquery)

bigrquery::bq_auth()

project_id <- config$project_id

############## String Libraries ##############

library("glue")

##############################################

projects <- c(
  'BikeRio',
  'BikeSampa',
  'BikeSSA',
  'BikePE',
  'BikePoa',
  'BikeVV',
  'riviera',
  'BAEcobici',
  'BikeBSB'
)

path <- config$path

makeQuery <- function(project) {
  query <- glue(
    "SELECT
      trip_id,
      duration_seconds,
      initial_station_name,
      start_time,
      final_station_name,
      end_time,
      DATE_TRUNC(c.birth_date, YEAR) birth_year,
      initial_station_latitude,
      initial_station_longitude,
      final_station_latitude,
      final_station_longitude
    FROM
      DM_BUSINESS.obt_trips t
    LEFT JOIN
      data_analytics_base.OBT_CUSTOMERS_SENSIBLE c
    ON
      t.customer_id = c.customer_id
    WHERE DATE_TRUNC(DATE(t.start_time), MONTH) = DATE_TRUNC(DATE_SUB(CURRENT_DATE('America/Sao_Paulo'), INTERVAL 1 MONTH), MONTH)
      AND t.project = '{project}'
      AND duration_seconds > 60
      AND t.active_plan_name NOT LIKE '%ood%'"
  )

  query
}

writeCSVFile <- function(path, result, project) {
  print("Busca concluída, exportando resultados...")

  if (!dir.exists(glue("{path}/Documentos/OpenData/{project}"))){
    dir.create(glue("{path}/Documentos/OpenData/{project}"))
  }

  filename <- glue("{path}/Documentos/OpenData/{project}/trips_{project}_{initial_date}.csv")

  write.csv(result, filename, row.names = FALSE)

  print(glue("{project} concluído! Salvo em {filename}"))
}

uploadToDrive <- function(filename, project) {
  folder <- switch(
    project,
    "BikeRio" = 'Rio de Janeiro',
    "BikeSampa" = 'BikeSampa',
    "BikeSSA" = 'Salvador',
    "BikePE" = 'Recife',
    "BikeBSB" = 'Brasilia',
    "BikeVV" = 'Vila Velha',
    "BikeSantiago" = 'Santiago',
    "BikePoa" = 'Porto Alegre',
    "BAEcobici" = 'Buenos Aires',
    "riviera" = 'Riviera'
  )

  print("Fazendo upload para o Google Drive...")

  folder_in_drive <- googledrive::drive_find(pattern = folder, team_drive = "OpenData", type = "folder")

  googledrive::drive_upload(media = filename, path = folder_in_drive)

  print(glue("{project} finalizado."))
}

for (project in projects) {
  query <- makeQuery(project)

  print(glue("Buscando dados de {project}..."))

  result <- bigrquery::query_exec(query, project_id, use_legacy_sql = FALSE)

  writeCSVFile(path, result, project)

  uploadToDrive(filename, project)
}
