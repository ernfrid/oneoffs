library(dplyr)
library(ggplot2)

read_output <- function(file) {
    x <- read.table(file, sep="\t", header=F)
    colnames(x) <- c('Filter', 'AF', 'AC', 'VQSLOD', 'Type')
    x[x$VQSLOD< (-15),]$VQSLOD <- -15
    x[x$VQSLOD> (15),]$VQSLOD <- 15
    x$VQSLOD <- round(x$VQSLOD, 1)
    x$AFClass <- NA
    x[x$AF<0.01,]$AFClass <- "Rare"
    x[x$AF>=0.01&x$AF<0.05,]$AFClass <- "Low Frequency"
    x[x$AF>=0.05,]$AFClass <- "Common"
    x[x$AC==1,]$AFClass <- "Singleton"
    x[x$AC==2,]$AFClass <- "Doubleton"
    x$AFClass <- factor(x$AFClass, levels=c("Common", "Low Frequency", "Rare", "Doubleton", "Singleton"))
    return(x)
}

summarize_titv <- function(y) {
    y %>% group_by(Filter, AFClass, VQSLOD) %>% summarize(Ti=sum(Type=="Transition"), Tv=sum(Type=="Transversion")) %>% mutate(Ti=ifelse(is.na(Ti),0,Ti), Tv=ifelse(is.na(Tv),0,Tv)) %>% mutate(TiTv=Ti/Tv) -> z
    return(z)
}

plot_titv_summary <- function(z) {
    g <- ggplot(z, aes(VQSLOD, TiTv, col=AFClass)) + facet_wrap(~ Filter) + geom_point(aes(size=Ti+Tv))
    print(g)
}

