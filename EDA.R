require("data.table")
require("ggplot2")
require("sf")
require("dplyr")
require("ggforce")
require("vdemdata")

# Load data
df <- fread("data/vdem_coup_EDA.csv")

df[country_name=="Türkiye","country_name"] <- "Turkey"
df[country_name=="Burma/Myanmar","country_name"] <- "Myanmar"
df[country_name=="Tanzania","country_name"] <- "United Republic of Tanzania"
df[,decade:=paste0(floor(year/10)%%10,'0s')]
df[,decade:=factor(decade,
    levels=c("40s","50s","60s","70s","80s","90s","00s","10s","20s"))]

# drop e_region_geo, e_regionpol, e_regionpol_6C
df[,c("e_regiongeo", "e_regionpol", "e_regionpol_6C") := NULL]

df[,e_regionpol_7C:=factor(
    e_regionpol_7C,levels=1:7,labels=c(
    "Europa del Este","América Latina y el Caribe",
    "Medio Oriente y África del Norte","África Subsahariana",
    "Europa Occidental y América del Norte",
    "Asia Oriental y el Pacífico","Asia del Sur y Central")
  )]

mapamundi <- read_sf("data/world.json")

mapamundi[mapamundi$geounit=="Falkland islands","sovereignt"] <- "Argentina"

sufijos <- "_sd|_code(high|low)|_nr|_ord|_osp|_mean"

# filter columns without suffixes
df_nas <- df[,grep(sufijos,
                   names(df),invert=TRUE),with=F]

df_nas <- df_nas[, lapply(.SD, function(x) sum(is.na(x))), by = year] |> 
  melt.data.table(id.vars = "year",variable.name = "columna") |> 
  merge(codebook[,c("tag","cb_section","metasection")],
        by.x="columna",by.y="tag")

sections <- list(
  "ca_" = "Espacio cívico\ny académico",
  "cl"  = "Libertad civil",
  "cs"  = "Sociedad civil",
  "dd"  = "Democracia\ndirecta",
  "de"  = "Demografía",
  "dl"  = "Deliberación",
  "el"  = "Elecciones",
  "ex"  = "Ejecutivo",
  "exl" = "Legitimación",
  "ju"  = "Poder judicial",
  "leg" = "Legitimación",
  "lg"  = "Legislatura",
  "me"  = "Medios de\ncomunicación",
  "pe"  = "Igualdad política",
  "ps"  = "Partidos políticos",
  "sv"  = "Soberanía",
  "st"  = "Estado",
  "x"   = "Índice",
  "zz"  = "Cuestionario posterior\na la encuesta",
  "ws"  = "Encuesta de\nsociedad digital",
  "partysystems" = "Encuesta de sistemas\nde partidos políticos"
)

detectar <- function(x){
  for (clave in names(sections)) {
    if (grepl(paste0("^", clave), x)) {
      x <- sections[[clave]]
    }
  }
  return(x)
}

df_nas[, label := sapply(cb_section,function(x) detectar(x))]

codebook <- vdemdata::codebook
codebook <- setDT(codebook)

codebook[,label := sapply(cb_section, function(x) detectar(x))]

# analisis de nulos
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
ggsave("entregas/imagenes/1_nas.png",plot = p_1,width=10,height=8.5)

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
  mutate(coup=ifelse(coup==0,"no","si")) |>
  ggplot(aes(x=year,fill=coup,y=country_text_id))+
    geom_tile()+
    scale_fill_viridis_d()+
    facet_col(vars(e_regionpol_7C), scales="free_y",
              space = "free",strip.position="left")+
    labs(x=element_blank(),y=element_blank(),fill="Golpe")+
    theme(axis.text.y=element_text(size=6),
          strip.text = element_text(size = 7),
          plot.background = element_rect(color="black"),
          strip.background = element_rect(color="black"),
          strip.placement = "outside")

ggsave("entregas/imagenes/4_golpes_anios.png",plot = p_4,width=10,height=14)


# plot correlation matrix

# probamos agrupando en grupos de variables
cor_group <- df[,grep(pattern=sufijos, names(df),invert=TRUE), with=F]|>
  select_if(is.numeric)|>
  data.table::melt.data.table(id.vars=c("year",'country_id'))|>
  merge.data.table(codebook[,c("tag",'label')],
        by.x="variable",by.y="tag")|>setDT()

cor_mtx_g <-  cor_group[,mean(value),by=list(country_id,year,label)]|>
  filter(!grepl('^(((e|eb)[0-9])|hist)',label))|>
  filter(label!='id')|>
  # mutate(label=gsub(' ','\n',label))|>
  reshape2::dcast(country_id+year~label,value.var="V1")|>  
  select(-country_id,-year)|>  
  cor(use='pairwise.complete.obs')

png("entregas/imagenes/5_correlacion_grupos.png",
    height=12,width=12,units="in",res=300)
p_5 <- corrplot.mixed(cor_mtx_g,tl.pos = 'lt')
# add black border to surround the plot
rect(par("usr")[1], par("usr")[3], 
     par("usr")[2], par("usr")[4], border = "black")
dev.off()

table(cor_mtx_g_long[,cor_d])

cor_mtx <- df[,grep(pattern=sufijos, names(df),invert=TRUE), with=F]|>
  select_if(is.numeric)|>
  cor(use='pairwise.complete.obs')|> reshape2::melt()|>
  merge.data.table(codebook[,c("tag",'label')],
        by.x="Var1",by.y="tag")|>
  merge.data.table(codebook[,c("tag",'label')],
        by.x="Var2",by.y="tag")|>setDT()|>  
  filter(!grepl('^(((e|eb)[0-9])|hist)',label.x)|
         !grepl('^(((e|eb)[0-9])|hist)',label.y))|>
  filter(label.x!='id'|label.y!='id')|>  
  filter(label.x==label.y)

p_6 <- cor_mtx |> 
  ggplot(aes(x=reorder(Var1,value),
             y=reorder(Var2,value),
             fill=cut(value,seq(-1,1,.25))))+
    geom_tile()+   
    scale_fill_viridis_d()+    
    labs(fill="Correlación",
         x = element_blank(),
         y = element_blank())+
    facet_wrap(~label.x,scales = "free",ncol=6)+
    # theme_minimal()+
    theme(plot.background = element_rect(color="black"),
          legend.position="right",
          axis.text.x = element_text(angle = 90, hjust = 1,size=4.5),
          axis.text.y = element_text(size=4.5))
ggsave("entregas/imagenes/6_correlacion.png",plot = p_6,width=20,height=20)


#get columns that has more than 50% of missing values without using df_nas
sin_nulos <- df[,grep(sufijos, 
                 names(df),invert=TRUE),with=F] |>
  lapply(function(x) sum(is.na(x))/length(x))|> unlist()

sin_nulos[sin_nulos>.75] |> 
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