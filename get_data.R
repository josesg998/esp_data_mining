# First, you need to have the devtools package installed
#install.packages("devtools")
# now, install the vdemdata package directly from GitHub
#devtools::install_github("vdeminstitute/vdemdata")

require("data.table")
require("vdemdata")
#create directory called data
dir.create("data")

vdem <- vdemdata::vdem

## Powell and Thyne coup dataset
powell_and_thyne <- fread("http://www.uky.edu/~clthyn2/coup_data/powell_thyne_coups_final.txt")

## Filter year
vdem_post_1945 <- vdem[vdem$year >= 1950,]

## remove duplicates by country and year in powell and thyne
powell_and_thyne <- powell_and_thyne[!duplicated(powell_and_thyne[,c("country", "year")]),]


#check <- data.frame("country"=sort(unique(powell_and_thyne$country)), 
#                    "check"=sort(unique(powell_and_thyne$country)) %in% unique(vdem_post_1945$country_name))
#check <- check[!check$check,]

## arreglo paises
mod_country <- list("Congo"                             = "Republic of the Congo",
                    # dominica
                    "Gambia"                            = "The Gambia",
                    # grenada
                    "Myanmar"                           = "Burma/Myanmar",
                    "Swaziland"                         = "Eswatini",
                    "Turkey"                            = "Türkiye",
                    "Yemen People's Republic; S. Yemen" = "South Yemen",
                    "Yemen Arab Republic; N. Yemen"     = "North Yemen")

# modify country column in powell_and_thyne using mod_country
powell_and_thyne$country <- ifelse(powell_and_thyne$country %in% names(mod_country), 
                                       sapply(powell_and_thyne$country, function(x) mod_country[[x]]), 
                                       powell_and_thyne$country)


vdem_post_1945$coup <- 0
vdem_post_1945[which(paste(vdem_post_1945$country_name, vdem_post_1945$year) 
                %in% paste(powell_and_thyne$country, powell_and_thyne$year)),]$coup <- 1

# write csv file
# fwrite(vdem_post_1945, "data/vdem_coup_EDA.csv")
# para azure
fwrite(vdem_post_1945, "data/vdem_coup_EDA.csv")