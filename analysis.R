library(ggplot2)
library(tidyr)
library(data.table)
library(dplyr)
setwd("~/ResearchCode/housingData")

datList <- list()
for (fi in list.files()[grepl("sales",list.files())]){
  read.csv(fi,header=FALSE) -> datList[[length(datList)+1]]
}

rbindlist(datList) -> saleDat
names(saleDat) <- c("key","tick","house","price")
for (cKey in unique(saleDat$key)){
saleDat %>% filter(key==cKey) %>% group_by(tick) %>% summarise(q05=quantile(log(price),.05),
                                         q25=quantile(log(price),.25),
                                         q50=quantile(log(price),.5),
                                         q75=quantile(log(price),.75),
                                         q95=quantile(log(price),.95)) %>%
  pivot_longer(names_to = "quantile",cols = q05|q25|q50|q75|q95) -> newDat
  ggplot(data=newDat) + geom_line(aes(x=tick,y=value,color=quantile))
ggsave(paste0("../housingPlots/plot",cKey,".png"))
}

