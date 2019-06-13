#'Config used internally
#'
#'This config holds the remote World Factbook database download url
#'and the corresponding local destination on disk
#'
#'@return list with two slots, one with the base_url of the sqlite
#'db release of the World Factbook and
#'one with the dest file where the download ends up locally
#'@importFrom rappdirs app_dir
#'@export
factbook_cfg <- function() {
  list(
    base_url = "https://github.com/factbook/factbook.sql/releases/download/v0.1/factbook.db",
    dest = file.path(rappdirs::app_dir("factbook")$config(), "factbook.db")
  )
}

#' Download the World Factbook as a sqlite3 database
#'
#'@param overwrite logical indicating if local db should be overwritten
#'@return logical indicating if the factbook exists locally, invisibly
#'@importFrom utils download.file
#'@export
factbook_download <- function(overwrite = FALSE) {

  stopifnot(is.logical(overwrite))

  cfg <- factbook_cfg()

  if (!dir.exists(dirname(cfg$dest)))
    dir.create(dirname(cfg$dest), recursive = TRUE)

  if (overwrite || !file.exists(cfg$dest))
    download.file(
      cfg$base_url, destfile = cfg$dest,
      mode = "wb", quiet = TRUE
    )

  # extends the data by adding FTS capabilities through sqlite
  add_fts_table()

  invisible(file.exists(cfg$dest))
}

#' World Factbook Database SQLite database connection
#' @importFrom dplyr src_sqlite
#' @importFrom RSQLite dbConnect SQLite
#' @noRd
src_sqlite_factbook <- function() {

  cfg <- factbook_cfg()

  if (!file.exists(cfg$dest))
    stop("No database available at ", cfg$dest,
         " please use factbook_download() first")

  RSQLite::dbConnect(RSQLite::SQLite(), cfg$dest)
}


#' Run a custom SQL query
#' @param sql_query the query
#' @param ... other arguments to be passed to the sql() fcn
#' @importFrom dplyr sql tbl collect
#' @importFrom RSQLite dbDisconnect
#' @noRd
factbook_query <- function(sql_query, ...){

  src <- src_sqlite_factbook()

  res <-
    src %>%
    tbl(sql(sql_query, ...)) %>%
    collect()

  RSQLite::dbDisconnect(src)

  res
}

#' World Factbook data as a tibble
#'
#' A dataset with population, birth_rate and
#' other attributes for countries around the world.
#' @format A tibble with 261 rows and 13 variables:
#' \describe{
#'   \item{id}{row id}
#'   \item{code}{country code}
#'   \item{name}{country name}
#'   \item{area}{total land area}
#'   \item{area_land}{land area}
#'   \item{area_water}{water area}
#'   \item{population}{population}
#'   \item{population_growth}{population growth}
#'   \item{birth_rate}{birth rate}
#'   \item{death_rate}{death rate}
#'   \item{migration_rate}{migration rate}
#'   \item{created_at}{created at timestamp}
#'   \item{updated_at}{updated at timestamp}
#' }
#' @source \url{https://github.com/factbook/factbook.sql/releases/download/v0.1/factbook.db}
#' @export
factbook_tibble <- function() {
  factbook_query("select * from facts")
}

#' @importFrom RSQLite dbListTables
#' @noRd
add_fts_table <- function() {

  con <- src_sqlite_factbook()

  if (!"fts" %in% RSQLite::dbListTables(con)) {
    RSQLite::dbSendQuery(con, statement =
      "create virtual table fts using fts5(country);")

    RSQLite::dbSendQuery(con, statement = paste0(
      "insert into fts select name as country from facts;"))
  }

  RSQLite::dbDisconnect(con)

}

#' Full text search for country names
#' @param search_term token query, phrase query or NEAR query (see http://www.sqlite.org/fts5.html)
#' @return tibble with matching results
#' @examples
#'  factbook_search_country("vatican")
#'  factbook_search_country("new")
#' @importFrom tibble tibble
#' @importFrom dplyr %>% inner_join
#' @export
factbook_search_country <- function(search_term) {
  query <- paste("select country as name from fts",
    sprintf("where country match '%s'", search_term))
  res <- factbook_query(query)
  if (nrow(res) < 1) return (tibble())
  res %>% inner_join(factbook_tibble(), by = "name")
}

