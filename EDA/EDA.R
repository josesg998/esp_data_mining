require("data.table")
require("ggplot2")
require("sf")
require("dplyr")

# Load data
df <- fread('data/vdem_coup_EDA.csv')

# get third position of column number

df$decade <- floor(df$year/10)%%10
df$decade <- paste0(df$decade,'0s')
df$decade <- factor(df$decade,levels=c('40s','50s','60s','70s','80s','90s','00s','10s','20s'))

mapamundi <- read_sf('data/world.json')
codebook <- vdemdata::codebook

df[df$country_name=='Türkiye','country_name'] <- 'Turkey'
df[df$country_name=='Burma/Myanmar','country_name'] <- 'Myanmar'
df[df$country_name=='Tanzania','country_name'] <- "United Republic of Tanzania"

mapamundi[mapamundi$geounit=='Falkland islands','sovereignt'] <- 'Argentina'

df |> 
  group_by(country_name) |> 
  summarise(coup=sum(coup)) |> 
  mutate(coup=ifelse(coup==0,NA,coup)) |> 
  select(country_name,coup) |> 
  merge(mapamundi,by.x='country_name',by.y='sovereignt',all.y=TRUE) |> 
  sf::st_as_sf() |> 
  filter(!name %in% c('Antarctica')) |> 
  ggplot()+
    geom_sf(aes(fill=cut(coup,breaks=c(0,1,5,10,15,17))))+
    theme_void()+
    scale_fill_viridis_d()+
    # change legend title
    labs(fill='Cantidad\nde golpes')+
    theme(plot.background = element_rect(color='black'),legend.position='bottom')
# save image
ggsave('EDA/imagenes/1_golpes.png',width=10,height=5,)


df |> 
  group_by(decade,country_name) |> 
  summarise(coup=sum(coup)) |> 
  merge(mapamundi,by.x='country_name',by.y='sovereignt') |> 
  mutate(coup=ifelse(coup==0,NA,coup)) |> 
  sf::st_as_sf() |> 
  filter(name!='Antarctica') |> 
  ggplot()+
    geom_sf(aes(fill=coup))+
    facet_wrap(~decade)+
    theme_minimal()+
    scale_fill_viridis_c()
  
# TODO idear mejor visualizacion
df |> 
  group_by(country_name) |> 
  summarise(coup=sum(coup)) |> 
  select(country_name,coup) |> 
  filter(coup>0) |> 
  ggplot()+
    geom_bar(aes(y=reorder(country_name,coup),x=coup),stat='identity')
  
# count number of nas in df
cols <- names(df)[!grepl("_sd|_code(high|low)|_nr|_ord|_osp",df)]
nas <- df[,cols]

nas|> 
  summarise_all(~sum(is.na(.))) |> 
  tidyr::gather() |> 
  filter(value>0) |> 
  ggplot(aes(x=key,y=value))+
    geom_col()+
    coord_flip()+
    labs(title='Number of NAs in each column')

###### 
#line plots
lines_countries <- function(df,country,column){
  
  df[country_name %in% country,] |> 
    ggplot(aes(x=year,y={{column}},group=country_name,color=country_name))+
    geom_line()+
    labs(title=codebook[codebook$tag==column,'name'],
         x='Year',
         y='Polyarchy Index')
}


lines_countries(df,c('USA','Canada','Mexico'),v2x_polyarchy)