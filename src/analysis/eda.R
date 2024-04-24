# File preparation --------------------------------------------------------
rm(list=ls())
setwd("src/analysis/")

set.seed(777)

# Library imports ---------------------------------------------------------
library(igraph)
library(ggplot2)
library(dplyr)
library(ggrepel)

# Analisi esplorativa -----------------------------------------------------

# Data import
tab <- read.csv("../../data/clean/edge_list.csv")
tab[,2] <- trimws(tab[,2], which = "left")

tab <- tab %>% 
  mutate(urbanedge = ifelse(startsWith(Source, "padova") & startsWith(Target, "padova"), 1, 0))

g <- graph_from_data_frame(tab[, 1:2], directed = FALSE)
E(g)$label <- tab[, 3] # labelling edges

# urban stop
urban.stop <- ifelse(startsWith(V(g)$name, "padova"), 1, 0)
V(g)$label <- urban.stop # labelling vertices

# Conversione multigrafo in grafo pesato ----------------------------------

E(g)$weight <- 1
g.pesato <- igraph::simplify(g,
                             edge.attr.comb = list(weight = sum))

# ------------------------------------------------------------------------

# Istogramma dei gradi
deg <- degree(g)

ggplot() +
  aes(deg) +
  geom_histogram(fill = "light blue", col = "black", binwidth = 1) + 
  ggtitle("Istogramma dei gradi dei nodi") +
  xlab("Grado") +
  ylab("Frequenza") +
  theme_bw() +
  png("../../images/eda/degree_hist.png")

# Log-log plot gradi
freq <- table(degree(g))

ggplot() +
  aes(x = log(sort(unique(deg))), 
      y = as.vector(log(freq))) +
  geom_point(colour = "black") +
  ggtitle("Log-log plot dei gradi") +
  xlab("Logaritmo del grado") +
  ylab("Log-frequenza") +
  theme_bw() +
  png("../../images/eda/loglog.png")

# grado medio dei vicini
grado.vicini <- knn(g.pesato,
                  mode = "all",
                  weights = E(g.pesato)$weight)

ggplot() +
  aes(x = degree(g.pesato), y = grado.vicini$knn) +
  geom_point(shape = 1) +
  ggtitle("Rapporto tra grado del nodo e grado dei suoi vicni") +
  xlab("Grado del nodo") +
  ylab("Grado dei vicini") +
  theme_bw() +
  png("../../images/eda/deg_deg_vicini.png")

ggplot() +
  aes(x = degree(g.pesato), y = log(grado.vicini$knn)) +
  geom_point(shape = 1) +
  ggtitle("Rapporto tra log-grado del nodo e log-grado dei suoi vicni") +
  xlab("Logaritmo del grado del nodo") +
  ylab("Logaritmo del grado dei vicini") +
  theme_bw() +
  png("../../images/eda/loglog_degvicini.png")

# Betweenness centrality dei vertici
bet <- betweenness(g)
head(sort(log(bet), decreasing = TRUE))

ggplot() +
  aes(bet) +
  geom_histogram(fill = "light blue", col = "black") +
  ggtitle("Istogramma della betweenness dei nodi") +
  xlab("Betweenness") +
  ylab("Frequenza") +
  theme_bw() +
  png("../../images/eda/hist_bet.png")

ggplot() +
  aes(x = bet, y = degree(g)) +
  geom_point(shape = 1, colour = "black") +
  ggtitle("Rapporto tra grado e betweenness dei nodi") +
  xlab("Betweenness") +
  ylab("Geado") +
  theme_bw() +
  png("../../images/eda/deg_bet.png")

ggplot() +
  aes(x = bet, y = degree(g), label = V(g)$name) +
  geom_point() +
  geom_label_repel() +
  ggtitle("Rapporto tra grado e betweenness dei nodi") +
  xlab("Betweenness") +
  ylab("Geado") +
  theme_bw() +
  png("../../images/eda/deg_bet_labelled.png")

# Closeness centrality dei vertici
cl <- sort(closeness(g), decreasing = TRUE)
head(cl)

# Coefficienti di assortatività
modularity(g, 
           membership = urban.stop + 1,
           directed = FALSE)

assortativity_nominal(g,
                      urban.stop + 1,
                      directed = FALSE)

assortativity_degree(g, directed = FALSE)

# Diametro
diameter(g, directed = FALSE)

# Lunghezza media
mean_distance(g)
log(length(V(g)))

# Transitività
transitivity(g)