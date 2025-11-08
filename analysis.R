library(ggplot2)
library(tidyr)
library(data.table)
library(dplyr)

googColor <- "#34a853"
basePoint <- "white"
bgFill <- "black"
#basePoint <- "black"
#bgFill <- "white"
vpnTrue <- "#4285f4"
vpnFalse <- "#ea4335"
hiOrange <- "#E37151"
shareColor <- "#ffa700"
#vpnColor <- "vpnColor"
vpnColor <- "purple"

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
  pivot_longer(names_to = "quantile",cols = q05|q25|q50|q75|q95) %>%
    transform(quantile=paste0(as.numeric(substr(quantile,2,3)),"%")) -> newDat
  
  
  
  ggplot(data=newDat) + geom_line(aes(x=tick,y=value,color=quantile)) + 
    theme(
      panel.background = element_rect(fill = bgFill),
      plot.title = element_text(color =basePoint,hjust = 0.5),
      plot.background = element_rect(fill = bgFill),
      panel.grid = element_blank(),
      axis.text = element_text(color =basePoint),
      axis.title = element_text(color =basePoint),
      legend.background = element_rect(fill = bgFill),
      axis.ticks = element_line(color = "white"), 
      legend.title = element_text(color = "white"),
      legend.text = element_text(color =basePoint)) + labs(x="Tick",y="Log Price",color="Percentile") +
    ggtitle(paste0("House Price Quantiles (High Rate)")) + ylim(6,22)
ggsave(paste0("../housingPlots/plot",cKey,".png"))
}


# find all sales associated with the house with problematic loans

loanList <- list()
for (fi in list.files()[grepl("loanGen",list.files())]){
  read.csv(fi,header=FALSE) -> loanList[[length(loanList)+1]]
}
rbindlist(loanList) -> loanDat
names(loanDat) <- c("key","idx","origTick","rate","initialBalance","monthlyPayment","collateral")
table(loanDat$initialBalance < loanDat$monthlyPayment)


loanList <- list()
for (fi in list.files()[grepl("loanFull",list.files())]){
  read.csv(fi,header=FALSE) -> loanList[[length(loanList)+1]]
}
rbindlist(loanList) -> loanPaidDat
names(loanPaidDat) <- c("key","paidTick","rate","collateral")

loanList <- list()
for (fi in list.files()[grepl("loanPre",list.files())]){
  read.csv(fi,header=FALSE) -> loanList[[length(loanList)+1]]
}
rbindlist(loanList) -> loanPrePaidDat
names(loanPrePaidDat) <- c("key","idx","prePaidTick","rate","collateral")

merge(loanDat,loanPrePaidDat,by=c("key","idx")) -> jointLoan

jointLoan %>% group_by(key,idx) -> jointLoan

jointLoan %>% group_by(key,idx) %>% summarise(cnt=n()) -> smry
merge(jointLoan,smry,by=c("key","idx")) -> jointLoan
jointLoan[jointLoan$cnt >1,]


probLoans <- jointLoan[jointLoan$cnt > 1,]
names(saleDat)[[3]] <- "idx"
merge(probLoans,saleDat,by=c("key","idx")) -> saleLoan

