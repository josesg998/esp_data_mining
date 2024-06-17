require("data.table")
require("vdemdata")
require("reticulate")

df <- fread("data/vdem_coup_EDA.csv")
codebook <- vdemdata::codebook |> setDT()

# sufijos de variables que vamos a quitar
sufijos <- "_sd|_code(high|low)|_nr|_ord|_osp|_mean"
df <- df[, grep(sufijos, names(df), invert = TRUE), with = FALSE]

# drop e_region_geo, e_regionpol, e_regionpol_6C
df[,c("e_regiongeo", "e_regionpol", "e_regionpol_6C") := NULL]

fuentes_ext_y_encuestas <- "^(((e|eb)[0-9])|hist|partysystems|ws)"
drop_vars <- codebook[grepl(fuentes_ext_y_encuestas,cb_section),tag]
ids <- codebook[cb_section== "id" & !tag %in% c("year", "country_id"),tag]
#filter df with columns that match with drop_vars
df <- df[, !names(df) %in% drop_vars, with = FALSE]
df <- df[,!names(df) %in% ids, with = FALSE]

df <- df[,sapply(df,is.numeric),with=F]

# order df by year and country_id
df <- df[order(country_id,year)]

cols <- names(df)[!names(df) %in% c("year","country_id")]

for (lag in c(1,5,10)){
    cat('lag:',lag,'\n')
    df[, paste((cols),"lag",lag,sep="_") := lapply(.SD, 
        function(x) shift(x, type = "lag", n = lag)), 
        by = country_id, .SDcols = cols]
}

one_hot_encoding <- function(df,col,pref){
    df[, id := .I]  # Create an id column
    long_df <- melt(df, id.vars = "id", measure.vars = col)
    wide_df <- dcast(long_df, id ~ value, fun.aggregate = length)
    names(wide_df) <- sapply(names(wide_df), function(x) paste0(pref,x))
    df <- merge.data.table(df, wide_df, 
    by.x = "id", by.y=paste0(pref,"id"), all.x = TRUE)
    df <- df[, id := NULL]
    return(df)
}

df <- one_hot_encoding(df,"e_regionpol_7C","region_")

fwrite(df, "data/vdem_coup_ML.csv")

file.remove('data/vdem_coup_EDA.csv')