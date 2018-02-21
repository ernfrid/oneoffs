library(dplyr)
library(ggplot2)

read_output <- function(file) {
    x <- read.table(file, sep="\t", header=F)
    colnames(x) <- c("VariantType", "Filter", "AF", "AC", "VQSLOD", "MIE", "NoMIE", "PctMIE")
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

summarize_mie <- function(y) {
    y %>% group_by(Filter, VariantType, AFClass, VQSLOD) %>% summarize(MIE=sum(MIE), NoMIE=sum(NoMIE)) %>% mutate(PctMIE=MIE/(MIE+NoMIE)) -> z
    return(z)
}


#plot_titv_summary <- function(z) {
#    g <- ggplot(z, aes(VQSLOD, TiTv, col=AFClass)) + facet_wrap(~ Filter) + geom_point(aes(size=Ti+Tv))
#    print(g)
#}

