library(dplyr)
library(grid)
library(ggplot2)

summarize_samples <- function(raw_counts) {
  per_genotype_counts = raw_counts %>% group_by(Cohort, Sample, Type) %>% summarize(Number=n(), Het=sum(Genotype=="0/1"), Hom=sum(Genotype=="1/1"), HetHomRatio=Het/Hom)
  per_genotype_counts$Sample <- factor(per_genotype_counts$Sample, levels=unique(as.character(per_genotype_counts$Sample)) )
  return(per_genotype_counts)
}

summarize_lengths_10kb <- function(raw_counts) {
  per_length_counts = raw_counts %>% filter(abs(Length) < 10000) %>% mutate(Length=as.factor(signif(abs(Length),2))) %>% group_by(Cohort, Sample, Type, Length) %>% summarize(Count=n())
  per_length_counts$Sample <- factor(per_length_counts$Sample, levels=unique(as.character(sample(per_length_counts$Sample))) )
  return(per_length_counts)
}

plot_by_sample_counts <- function(count_data, title_string="Number of SVs per sample by type") {
  # set colors
  col.list=c("#e41a1c", "#377eb8", "#4daf4a", "#999999")
  
  g <- ggplot(data=count_data, aes(x=Sample, y=Number, fill=Type)) + facet_grid(~ Cohort, scales="free_x", space="free") + geom_bar(stat="identity", width=1, colour = "black", size=0.1) + scale_fill_manual(values = col.list) + theme(panel.margin=unit(0.0, "lines"), axis.text=element_text(colour="black"), axis.text.x=element_blank(),  axis.ticks.x=element_blank(), panel.grid.major=element_blank(), panel.grid.minor=element_blank(), panel.background=element_blank(), strip.text.x=element_text(size=10, angle=90)) + labs(x = "Sample", y = "Number of SVs") + ggtitle(title_string) + scale_y_continuous(limits = c(0,7500), expand = c(0,0)) + scale_x_discrete(expand = c(0.01, 0.0)) + guides(fill = guide_legend(override.aes = list(colour = NULL)))
  print(g)
}

plot_by_sample_counts_by_type <- function(count_data, title_string="Number of SVs per sample by type") {
  # set colors
  col.list=c("#e41a1c", "#377eb8", "#4daf4a", "#999999")
  
  g <- ggplot(data=count_data, aes(x=Sample, y=Number, fill=Type)) + facet_grid(Type ~ Cohort, scales="free", space="free_x") + geom_bar(stat="identity", width=1, colour = "black", size=0.1) + scale_fill_manual(values = col.list) + theme(panel.margin=unit(0.0, "lines"), axis.text=element_text(colour="black"), axis.text.x=element_blank(),  axis.ticks.x=element_blank(), panel.grid.major=element_blank(), panel.grid.minor=element_blank(), panel.background=element_blank(), strip.text.x=element_text(size=10, angle=90)) + labs(x = "Sample", y = "Number of SVs") + ggtitle(title_string) + scale_x_discrete(expand = c(0.01,0)) + guides(fill = guide_legend(override.aes = list(colour = NULL)))
  print(g)
}

plot_by_sample_hethom_by_type <- function(count_data, title_string="Number of SVs per sample by type") {
  # set colors
  col.list=c("#e41a1c", "#377eb8", "#4daf4a", "#999999")
  
  g <- ggplot(data=count_data, aes(x=Sample, y=HetHomRatio, fill=Type)) + facet_grid(Type ~ Cohort, scales="free", space="free_x") + geom_bar(stat="identity", width=1, colour = "black", size=0.1) + scale_fill_manual(values = col.list) + theme(panel.margin=unit(0.0, "lines"), axis.text=element_text(colour="black"), axis.text.x=element_blank(),  axis.ticks.x=element_blank(), panel.grid.major=element_blank(), panel.grid.minor=element_blank(), panel.background=element_blank(), strip.text.x=element_text(size=10, angle=90)) + labs(x = "Sample", y = "Het:Hom Ratio") + ggtitle(title_string) + scale_x_discrete(expand = c(0.01,0)) + guides(fill = guide_legend(override.aes = list(colour = NULL)))
  print(g)
}

plot_10kb_size_fingerprint <- function(count_data) {
  g <- ggplot(count_data, aes(Sample, Length, fill=log10(Count))) + geom_raster() + 
    facet_grid(Type ~ ., scales="free_x", space="free_x") + 
    scale_y_discrete(breaks=c(0, 100, 300, 1000, 10000)) + 
    scale_x_discrete(breaks=NULL)
  print(g)
}
