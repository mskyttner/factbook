## ---- include = FALSE----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- eval=FALSE---------------------------------------------------------
#  
#  devtools::install_github("mskyttner/factbook", build_vignettes = TRUE)
#  

## ----setup, message=FALSE------------------------------------------------

library(factbook)
library(dplyr)

# get the data, only required to run once initially
factbook_download()

# use the data
df <- factbook_tibble()


## ------------------------------------------------------------------------
knitr::kable(df %>% select(1:5) %>% slice(1:5))

## ------------------------------------------------------------------------
# display info for any country matching the search term "vatican",
# expecting to see data related to the Vatican City
factbook_search_country("vatican")

# display info for countries that have "new" in their name:
factbook_search_country("new")

