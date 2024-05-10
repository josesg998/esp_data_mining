require("data.table")
require("ggplot2")
require("sf")
require("dplyr")
require("ggforce")
require("vdemdata")

# Load data
df <- fread("data/vdem_coup_EDA.csv")
codebook <- vdemdata::codebook |> setDT()

# get third position of column number

df$decade <- floor(df$year/10)%%10
df$decade <- paste0(df$decade,"0s")
df$decade <- factor(df$decade,
levels=c("40s","50s","60s","70s","80s","90s","00s","10s","20s"))

mapamundi <- read_sf("data/world.json")
codebook <- vdemdata::codebook

df[df$country_name=="Türkiye","country_name"] <- "Turkey"
df[df$country_name=="Burma/Myanmar","country_name"] <- "Myanmar"
df[df$country_name=="Tanzania","country_name"] <- "United Republic of Tanzania"

mapamundi[mapamundi$geounit=="Falkland islands","sovereignt"] <- "Argentina"

sections <- list(
  "ca"    =  "Espacio cívico y académico",
  "cl"    =  "Libertad civil",
  "dd"    =  "Democracia directa",
  "de"    =  "Demografía",
  "dl"    =  "Deliberación",
  "el"    =  "Elecciones",
  "ex"    =  "Ejecutivo",
  "exl"   =  "Legitimación",
  "ju"    =  "Poder judicial",
  "lg"    =  "Legislatura",
  "me"    =  "Medios de comunicación",
  "pe"    =  "Igualdad política",
  "ps"    =  "Partidos políticos",
  "sv/st" =  "Soberanía/Estado",
  "x"     =  "Índice",
  "zz"    =  "Cuestionario posterior a la encuesta",
  'ws'    =  'Encuesta internet'
)


# filter columns without suffixes
df_nas <- df[,grep("_sd|_code(high|low)|_nr|_ord|_osp",
                   names(df),invert=TRUE),with=F]

df_nas <- df_nas[, lapply(.SD, function(x) sum(is.na(x))), by = year] |> 
  melt.data.table(id.vars = "year",variable.name = "columna") |> 
  merge(codebook[,c("tag","cb_section","metasection")],
        by.x="columna",by.y="tag")

rep_list <- list(
  'ca_' = 'ca',  'cl' = 'cl',  'dd' = 'dd',  'de' = 'de',
  'dl' = 'dl',  'el' = 'el',  'ex' = 'ex',  'exl' = 'exl',
  'ju' = 'ju',  'lg' = 'lg',  'me' = 'me',  'pe' = 'pe',
  'ps' = 'ps',  'sv' = 'sv',  'x' = 'x',  'e' = 'e'
)

detectar_y_reemplazar <- function(columna,lista) {
  resultado <- sapply(columna, function(x) {
    for (clave in names(lista)) {
      if (grepl(paste0("^", clave), x)) {
        return(lista[[clave]])
      }
    }
    return(x)
  })
  return(resultado)
}

df_nas[, seccion := detectar_y_reemplazar(cb_section,rep_list)]
df_nas[, label := detectar_y_reemplazar(cb_section,sections)]

codebook$section_new <- detectar_y_reemplazar(codebook$cb_section,rep_list)
codebook$cb_section <- tolower(codebook$cb_section)
codebook$label <- detectar_y_reemplazar(codebook$cb_section,sections)

# analisis de nulos
# p_1 <- df_nas |> #[columna %in% sin_nulos] |> 
#   ggplot(aes(y=columna,x=year,fill=value))+
#     geom_tile()+
#     facet_wrap(~cb_section,scales = "free_y",strip.position = "left",ncol = 5)+
#     labs(x=element_blank(),y=element_blank(),fill="cantidad\nde nulos")+
#     theme(axis.text.y=element_blank(),
#           axis.ticks.y = element_blank(),
#           # reduce facet title size
#           strip.text = element_text(size = 7),
#           plot.background = element_rect(color="black"))
# ggsave("entregas/imagenes/1_nas.png",plot = p_1,width=10,height=14)

p_1 <- df_nas |> #[columna %in% sin_nulos] |> 
  ggplot(aes(y=columna,x=year,fill=value))+
    geom_tile()+
    facet_wrap(~label,scales = "free_y",strip.position = "left",ncol=6)+
    labs(x=element_blank(),y=element_blank(),fill="cantidad\nde nulos")+
    theme(axis.text.y=element_blank(),
          axis.ticks.y = element_blank(),
          # reduce facet title size
          strip.text = element_text(size = 7),
          plot.background = element_rect(color="black"))
ggsave("entregas/imagenes/1_nas.png",plot = p_1,width=10,height=10)

#mapa mundial con golpes
p_2 <- df |> 
  group_by(country_name) |> 
  summarise(coup=sum(coup)) |> 
  #mutate(coup=ifelse(coup==0,NA,coup)) |> 
  select(country_name,coup) |> 
  merge(mapamundi,by.x="country_name",by.y="sovereignt",all.y=TRUE) |> 
  sf::st_as_sf() |> 
  filter(!name %in% c("Antarctica")) |> 
  ggplot()+
    geom_sf(aes(fill=cut(coup,breaks=c(0,1,5,10,15,17))))+
    theme_void()+
    scale_fill_viridis_d()+
    # change legend title
    labs(fill="Cantidad\nde golpes")+
    theme(plot.background = element_rect(color="black",fill="white"),
    legend.position="bottom",
    # add space between legend and bottom of plot
    legend.margin = margin(t = 0, r = 0, b = 0.2, l = 0, unit = "cm"))
# save image
ggsave("entregas/imagenes/2_golpes.png",p_2,width=10,height=5)


p_3 <- df |> 
  group_by(decade,country_name) |> 
  summarise(coup=sum(coup)) |> 
  #mutate(coup=ifelse(coup==0,NA,coup)) |> 
  select(country_name,coup,decade) |> 
  merge(mapamundi,by.x="country_name",by.y="sovereignt",all.y=TRUE) |> 
  sf::st_as_sf() |> 
  filter(!name %in% c("Antarctica") & !is.na(decade)) |> 
  ggplot()+
    geom_sf(aes(fill=cut(coup,breaks=c(0,1,5,10))))+
    theme_void()+
    scale_fill_viridis_d()+
    labs(fill="Cantidad\nde golpes")+    # change legend title
    facet_wrap(~decade)+
    theme(plot.background = element_rect(color="black",fill="white"),
          legend.position="bottom",
          legend.margin = margin(t = 0, r = 0, b = 0.2, l = 0, unit = "cm"))

ggsave("entregas/imagenes/3_golpes_decadas.png",p_3,width=9,height=5)

p_4 <- df |> 
  group_by(country_name,year) |> 
  summarise(coup=sum(coup)) |> 
  merge(mapamundi[,c("admin","region_wb","name_es")],
        by.x="country_name",by.y="admin") |> 
  mutate(coup=ifelse(coup==0,"no","si"),
         region_wb=ifelse(region_wb %in% c("North America","Latin America & Caribbean"),
                          "America",region_wb),
          name_es=gsub("República Democrática","RD",name_es),
          name_es=gsub("República","Rep",name_es)) |>
  ggplot(aes(x=year,fill=coup,y=name_es))+
    geom_tile()+
    scale_fill_viridis_d()+
    facet_col(vars(region_wb), scales="free_y", space = "free",strip.position="left")+
    labs(x=element_blank(),y=element_blank(),fill="Golpe")+
    # fix the height of facets according to the amount of countries
    # reduce space between axis y and plot
    theme(
          strip.text = element_text(size = 7),
          plot.background = element_rect(color="black"),
          strip.background = element_rect(color="black"),
          strip.placement = "outside")

ggsave("entregas/imagenes/4_golpes_anios.png",plot = p_4,width=10,height=15)


# plot correlation matrix
require("Hmisc")
require("ggpubr")

# p_5 <- df[,grep("_sd|_code(high|low)|_nr|_ord|_osp", names(df),invert=TRUE),
#           with=F]|>   
#   select(-coup,-country_text_id,-historical_date,-histname,-codingstart,
#          -codingend,-codingstart_contemp,-codingend_contemp,-codingstart_hist,
#          -codingend_hist,-country_name,-country_id)|>  
#   select_if(is.numeric)|>
#   cor(use='pairwise.complete.obs') |> reshape2::melt() |>setDT()|>
#   merge.data.table(codebook[,c("tag","name",'section_new','label')],
#   by.x="Var1",by.y="tag")|>
#   # reorder by section_new
#   arrange(label)|>
#   filter(!is.na(value))|>
#   filter(Var1!=Var2)|>
#   #positivize correlation
#   mutate(value=ifelse(value<0,-value,value))|>
#   ggplot()+
#     geom_tile(aes(x=Var1,y=Var2,fill=cut(value,breaks=seq(-1,1,.25))))+
#     scale_fill_viridis_d()+
#     labs(fill='corr',x=element_blank(),y=element_blank())+
#     # facet_grid(~label,scales="free")+
#     theme(plot.background = element_rect(color="black"),
#           # rotate x axis labels
#           axis.text.x = element_text(angle = 90, hjust = 1),
#           legend.position = 'top')
# ggsave("entregas/imagenes/5_correlacion.png",plot = p_5)

# voy plotear la correlacion enter

# cor <- df[,grep("_sd|_code(high|low)|_nr|_ord|_osp|_mean", names(df),invert=TRUE),
#           with=F]|>   
#   select(-country_text_id,-historical_date,-histname,-codingstart,
#          -codingend,-codingstart_contemp,-codingend_contemp,-codingstart_hist,
#          -codingend_hist,-country_name,-country_id)|>  
#   select_if(is.numeric)|>
#   cor(use='pairwise.complete.obs') |> reshape2::melt() |>
#   merge(codebook[,c("tag","name",'section_new','label')],
#         by.x="Var2",by.y="tag")|>
#   mutate(pair=paste(Var1,Var2,sep=" + "))|>
#   filter(abs(value)>.75)


# ggsave("entregas/imagenes/5_correlacion.png",plot = p_5)


# probamos agrupando en grupos de variables
cor_group <- df[,grep("_sd|_code(high|low)|_nr|_ord|_osp|_mean", names(df),invert=TRUE),
          with=F]|>
  select_if(is.numeric)|>
  reshape2::melt(id.vars=c("year",'country_id'))|>
  merge.data.table(codebook[,c("tag",'label')],
        by.x="variable",by.y="tag")|>setDT()

cor_group[cor_group$variable=='coup','label'] <- 'TARGET'

p_5 <- cor_group[!is.na(value),mean(value,na.rm=T),by=list(country_id,year,label)]|>
  filter(!grepl('((e|eb[0-9])|hist)',label))|>
  # filter(!label%in% c('id','year'))|>
  reshape2::dcast(country_id+year~label,value.var="V1")|>
  cor(use='pairwise.complete.obs')|> reshape2::melt() |>  
  ggplot()+
    geom_tile(aes(x=Var1,y=Var2,fill=cut(value,breaks=seq(-1,1,.25))))+
    scale_fill_viridis_d()+
    labs(fill='corr',x=element_blank(),y=element_blank())+
    theme(plot.background = element_rect(color="black"),
          # rotate x axis labels
          axis.text.x = element_text(angle = 90, hjust = 1),
          legend.position = 'top')
ggsave("entregas/imagenes/5_correlacion_grupos.png",plot = p_5)

#get columns that has more than 50% of missing values without using df_nas
sin_nulos <- df[,grep("_sd|_code(high|low)|_nr|_ord|_osp|_mean", 
                 names(df),invert=TRUE),with=F] |>
  lapply(function(x) sum(is.na(x))/length(x))|> unlist()

sin_nulos[sin_nulos>.5] |> 
  names()

#line plots
lines_countries <- function(df,country,column){
  
  df[country_name %in% country,] |> 
    ggplot(aes(x=year,y={{column}},group=country_name,color=country_name))+
    geom_line()+
    labs(title=codebook[codebook$tag==column,"name"],
         x="Year",
         y="Polyarchy Index")
}


lines_countries(df,c("USA","Canada","Mexico"),v2x_polyarchy)