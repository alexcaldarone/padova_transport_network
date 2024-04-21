# File preparation --------------------------------------------------------
rm(list=ls())
setwd("src/analysis")

set.seed(42)

# Library imports ---------------------------------------------------------
library(igraph)
library(intergraph)
library(ergm)
library(ergm.count)
library(tidyverse)

# Data import -------------------------------------------------------------
tab <- read.csv("../../data/clean/edge_list.csv")
tab[,2] <- trimws(tab[,2], which = "left")

g <- graph_from_data_frame(tab[, 1:2], directed = FALSE)

# urban stop
urban.stop <- ifelse(startsWith(V(g)$name, "padova"), 1, 0)

# creazione del grafo con archi pesati
E(g)$weight <- 1
g.pesato <- igraph::simplify(g, edge.attr.comb = list(weight = sum))
weighted.df <- get.data.frame(g.pesato)
weighted.df <- weighted.df %>% 
  mutate(urbanedge = ifelse(startsWith(from, "padova") & startsWith(to, "padova"), 1, 0))

# Adding attributes to network --------------------------------------------

# conversione da ogetto igraph a intergraph
g.pesato.interg <- intergraph::asNetwork(g.pesato)

# setting vertex attributes
g.pesato.interg %v% "urbano" <- urban.stop

# setting edge attributes
set.edge.attribute(g.pesato.interg, "urbanedge", weighted.df[, 4])

hist(E(g.pesato)$weight, breaks = 30)

# Modelling ---------------------------------------------------------------

control <- control.ergm(MCMLE.maxit = 1000,MCMLE.density.guard = 30)
control2 <- control.ergm(MCMLE.maxit = 1000,MCMLE.density.guard = 30,
                         main.method = "MCMLE", force.main = TRUE)

# modello di erdos-renyi
mod1 <- ergm(g.pesato.interg ~ edges)
summary(mod1)

# dalla stima, ricaviamo una probabilita' di un arco tra due nodi
plogis(mod1$coefficients)
# probabilità molto bassa
igraph::edge_density(g.pesato)
# corrisponde alla densità della rete

# modello di erdo-renyi usando la presenza o meno di un nodo nella citta'
# di padova come covariata binaria
mod2 <- ergm(g.pesato.interg ~ edges + nodefactor("urbano"))
summary(mod2)
#' La variabile relativa alla presenza o meno del nodo nella citta' di 
#' padova non sembra essere significativo.
exp(mod2$coefficients[2])
# rapporto di quote vale 1.058

# aggiungiamo il numero di triangoli come covariata
# il modello non sara' piu' dyad-independent
#mod3 <- ergm(g.pesato.interg ~ edges + triangle,
#             control = control)
# aggiungere i triangoli porta ad un modello degenere 

mod4 <- ergm(g.pesato.interg ~ edges + nodematch("urbano"))
summary(mod4)
# la variabile urbano risulta significativa quando si considera il node match 

mod5 <- ergm(g.pesato.interg ~ edges +
               nodematch("urbano") +
               edgecov(g.pesato.interg, "urbanedge"),
             control = control2)
summary(mod5)
# non si riesce a trovare la stima che massimizza la pseudo-verosimiglianza
anova(mod4, mod5)
# anche non arrivando a convergenza e con la variabile relativa
# alla covariata di arco, si nota una grande riduzione in termini
# di devianza
mcmc.diagnostics(mod5)

# aggiunge un constraint sulle diadi
mod6  <- ergm(g.pesato.interg ~ edges,
              constraints = ~ Dyads(vary = ~ nodematch("urbano")))
summary(mod6)

# modello tenendo conto del peso degli archi
pesi <- E(g.pesato)$weight
smv.pesi <- coef(glm(pesi ~ 1, family = poisson))[1]

mod7 <- ergm(g.pesato.interg ~ edges + nodematch("urbano"),
             response = "weight", reference = ~Poisson(smv.pesi))
summary(mod7)
mcmc.diagnostics(mod7)

mod8 <- ergm(g.pesato.interg ~ edges,
                  response = "weight", reference = ~Poisson(smv.pesi))
summary(mod8)
mcmc.diagnostics(mod8)
anova(mod8, mod7)

#' Il modello finale a quale arriviamo è un modello dove usiamo come covariata
#' la variabile urbano (che indica se una fermata è nella città di padova o no)
#' e modelliamo i pesi come risposta (con distribuzione di riferimento una Poisson)

#rmarkdown::render("modelling.R", "html_document")
