Data packages in R using SQLite and FTS
================

## World Factbook use case

This package is an example of how you can use SQLite Database FTS
functionality in an R package. It provides data access to some (not so
well curated?) data from the [World Factbook
data](https://github.com/factbook/factbook.sql/releases/download/v0.1/factbook.db)
distributed in the SQLite database format which is initially downloaded
from a remote location.

A local SQLite db is then created based this distribution of data and
extended to support Full Text Search functionality. This data is then
exposed to R through a couple of functions returning tibbles.

The support for FTS - Full Text Search - is provided by using the
[`RSQLite` package](https://rsqlite.r-dbi.org/articles/rsqlite) which
embeds the fast and SQL-ansi-compliant sqlite database engine portably
and thereby embeds the FTS5 seach capabilities built into this database
engine.

## Rationale

The idea is to show how to provide access to data in a potentially
larger database - the database in the example is not huge but could be a
lot bigger - and show how to enable use of in-built full text search
capabilities in SQLite. The approach is to download potentially big
remote data and installing it locally using the [`rappdirs` R
package](https://rdrr.io/cran/rappdirs/), rather than bundling it
directly into the package.

This can be useful if you are considering to release a package to CRAN
that provides access to larger datasets in R and you also want to follow
the general recommendation from the CRAN checks that “package data
should be smaller than a megabyte”. With this approach you can avoid
having to argue separately with the CRAN gods for making an exception to
the 1 MB rule (see details in [Hadley Wickhams R Packages book, the
sections on data packages and CRAN
rules](http://r-pkgs.had.co.nz/data.html#data-cran)). Your package will
stay small.

There are a few minor practical drawbacks - mostly that your package
will initially not work off-line until at least one initial successfull
call to download the data has been made using `factbook_download()`
which would require a connection to the Internet.

The upside is being able to tap into things like Full Text Search for
datasets and with this approach the package can stay small and pass the
CRAN checks without requiring exceptions, while the dataset size is only
limited to 2TB (an SQLite limitation).

# Installing

``` r

devtools::install_github("mskyttner/factbook", build_vignettes = TRUE)
```

# Usage

After installing, you need to first download the data and can then
proceed to work it it:

``` r

library(factbook)
library(dplyr)

# get the data, only required to run once initially
factbook_download()

# use the data
df <- factbook_tibble()
```

This is a few of the rows and columns in the data:

``` r
knitr::kable(df %>% select(1:5) %>% slice(1:5))
```

| id | code | name        |    area | area\_land |
| -: | :--- | :---------- | ------: | ---------: |
|  1 | af   | Afghanistan |  652230 |     652230 |
|  2 | al   | Albania     |   28748 |      27398 |
|  3 | ag   | Algeria     | 2381741 |    2381741 |
|  4 | an   | Andorra     |     468 |        468 |
|  5 | ao   | Angola      | 1246700 |    1246700 |

To make a search in the database using the Full Text Search
capabilities:

``` r
# display info for any country matching the search term "vatican",
# expecting to see data related to the Vatican City
factbook_search_country("vatican")
#> # A tibble: 1 x 13
#>   name     id code   area area_land area_water population population_grow…
#>   <chr> <int> <chr> <int>     <int>      <int> <integr64>            <dbl>
#> 1 Holy…   190 vt        0         0          0 842                       0
#> # … with 5 more variables: birth_rate <dbl>, death_rate <dbl>,
#> #   migration_rate <dbl>, created_at <chr>, updated_at <chr>

# display info for countries that have "new" in their name:
factbook_search_country("new")
#> # A tibble: 3 x 13
#>   name     id code    area area_land area_water population population_grow…
#>   <chr> <int> <chr>  <int>     <int>      <int> <integr64>            <dbl>
#> 1 New …   126 nz    267710    267710         NA 4438393                0.82
#> 2 Papu…   135 pp    462840    452860       9980 6672429                1.78
#> 3 New …   211 nc     18575     18275        300  271615                1.38
#> # … with 5 more variables: birth_rate <dbl>, death_rate <dbl>,
#> #   migration_rate <dbl>, created_at <chr>, updated_at <chr>

# display info for countries that are islands:
factbook_search_country("island")
#> # A tibble: 8 x 13
#>   name     id code   area area_land area_water population population_grow…
#>   <chr> <int> <chr> <int>     <int>      <int> <integr64>            <dbl>
#> 1 Chri…   199 kt      135       135          0        15…             1.11
#> 2 Hear…   202 hm      412       412          0 -21474836…            NA   
#> 3 Norf…   203 nf       36        36          0        22…             0.01
#> 4 Clip…   208 ip        6         6          0 -21474836…            NA   
#> 5 Bouv…   222 bv       49        49          0 -21474836…            NA   
#> 6 Nava…   244 bq        5         5          0 -21474836…            NA   
#> 7 Wake…   248 wq        6         6          0 -21474836…            NA   
#> 8 Unit…   249 um       NA        NA         NA -21474836…            NA   
#> # … with 5 more variables: birth_rate <dbl>, death_rate <dbl>,
#> #   migration_rate <dbl>, created_at <chr>, updated_at <chr>
```

The database could have any number of tables and you only need to expose
the relevant parts through the functions you provide in the package.

# Data quality

This dataset appears to have many missing values and may contain some
errors:

``` r

# some records have negative population values,
# is it due to the data or something in our software stack
# converting the data to negative values?
issues_negative <- 
  df %>%
  filter(population < 0) %>%
  select(name, population)

knitr::kable(issues_negative)
```

| name                                          |   population |
| :-------------------------------------------- | -----------: |
| Ashmore and Cartier Islands                   | \-2147483648 |
| Coral Sea Islands                             | \-2147483648 |
| Heard Island and McDonald Islands             | \-2147483648 |
| Clipperton Island                             | \-2147483648 |
| French Southern and Antarctic Lands           | \-2147483648 |
| Bouvet Island                                 | \-2147483648 |
| Jan Mayen                                     | \-2147483648 |
| British Indian Ocean Territory                | \-2147483648 |
| South Georgia and South Sandwich Islands      | \-2147483648 |
| Navassa Island                                | \-2147483648 |
| Wake Island                                   | \-2147483648 |
| United States Pacific Island Wildlife Refuges | \-2147483648 |
| Paracel Islands                               | \-2147483648 |
| Spratly Islands                               | \-2147483648 |
| Arctic Ocean                                  | \-2147483648 |
| Atlantic Ocean                                | \-2147483648 |
| Indian Ocean                                  | \-2147483648 |
| Pacific Ocean                                 | \-2147483648 |
| Southern Ocean                                | \-2147483648 |

``` r

# some columns have missing values
issues_missing <- 
  df %>% 
  summarise_all(~ sum(is.na(.))) %>% 
  t() %>% as.vector() %>% tibble() %>% 
  mutate(colname = names(df)) %>% 
  select(colname, n_missing = 1)

knitr::kable(issues_missing)
```

| colname            | n\_missing |
| :----------------- | ---------: |
| id                 |          0 |
| code               |          0 |
| name               |          0 |
| area               |         12 |
| area\_land         |         15 |
| area\_water        |         18 |
| population         |          0 |
| population\_growth |         25 |
| birth\_rate        |         33 |
| death\_rate        |         33 |
| migration\_rate    |         38 |
| created\_at        |          0 |
| updated\_at        |          0 |
