# File preparation --------------------------------------------------------
rm(list=ls())
setwd("src/analysis")
# cambia 

set.seed(42)

# Library imports ---------------------------------------------------------
library(igraph)
library(intergraph)
library(ergm)
library(ergm.count)
library(dplyr)
library(ggplot2)
library(pscl)

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

E(g.pesato)$urbanedge <- weighted.df[, 4]
# Adding attributes to network --------------------------------------------

# conversione da ogetto igraph a intergraph
g.pesato.interg <- intergraph::asNetwork(g.pesato)

# setting vertex attributes
g.pesato.interg %v% "urbano" <- urban.stop

# setting edge attributes
set.edge.attribute(g.pesato.interg, "urbanedge", weighted.df[, 4])

pesi <- E(g.pesato)$weight

# Helper function  --------------------------------------------------------

# somma dei gradi dei nodi incidenti ad un arco
sum_degrees_of_incident_nodes <- function(graph) {
  # Get the number of edges in the graph
  num_edges <- ecount(graph)
  
  # Initialize an empty vector to store the sum of degrees for each edge
  sum_degrees <- numeric(num_edges)
  
  # Iterate over each edge
  for (i in 1:num_edges) {
    # Get the endpoints of the current edge
    endpoints <- ends(graph, i)
    
    # Get the degrees of the incident nodes
    degree_1 <- degree(graph, v = endpoints[1])
    degree_2 <- degree(graph, v = endpoints[2])
    
    # Calculate the sum of the degrees of the incident nodes
    sum_degrees[i] <- degree_1 + degree_2
  }
  
  # Return the vector containing the sum of degrees for each edge
  return(sum_degrees)
}

# somma della closeness centrality dei nodi incidenti ad un arco
sum_centrality_of_adjacent_nodes <- function(graph) {
  # Get the number of edges in the graph
  num_edges <- ecount(graph)
  
  # Initialize an empty vector to store the sum of centrality indices for each edge
  sum_centrality <- numeric(num_edges)
  
  # Compute the centrality indices for all nodes
  centrality_values <- closeness(graph)
  
  # Iterate over each edge
  for (i in 1:num_edges) {
    # Get the endpoints of the current edge
    endpoints <- ends(graph, i)
    
    # Get the centrality indices of the adjacent nodes
    centrality_1 <- centrality_values[endpoints[1]]
    centrality_2 <- centrality_values[endpoints[2]]
    
    # Calculate the sum of the centrality indices of adjacent nodes
    sum_centrality[i] <- centrality_1 + centrality_2
  }
  
  # Return the vector containing the sum of centrality indices for each edge
  return(sum_centrality)
}

# somma della betweenness dei nodi incidenti ad un arco
sum_betweenness_of_adjacent_nodes <- function(graph) {
  # Get the number of edges in the graph
  num_edges <- ecount(graph)
  
  # Initialize an empty vector to store the sum of betweenness centralities for each edge
  sum_betweenness <- numeric(num_edges)
  
  # Compute the betweenness centrality for all nodes
  betweenness_values <- betweenness(graph)
  
  # Iterate over each edge
  for (i in 1:num_edges) {
    # Get the endpoints of the current edge
    endpoints <- ends(graph, i)
    
    # Get the betweenness centralities of the adjacent nodes
    centrality_1 <- betweenness_values[endpoints[1]]
    centrality_2 <- betweenness_values[endpoints[2]]
    
    # Calculate the sum of the betweenness centralities of adjacent nodes
    sum_betweenness[i] <- centrality_1 + centrality_2
  }
  
  # Return the vector containing the sum of betweenness centralities for each edge
  return(sum_betweenness)
}

# somma dei pesi dei nodi incidenti ad un arco
sum_weights_of_incident_edges <- function(graph) {
  # Get the number of edges in the graph
  num_edges <- ecount(graph)
  
  # Initialize an empty vector to store the sum of weights for each edge
  sum_weights <- numeric(num_edges)
  
  # Iterate over each edge
  for (i in 1:num_edges) {
    # Get the endpoints of the current edge
    endpoints <- ends(graph, i)
    
    # Get the incident edges for the first endpoint
    incident_edges_1 <- incident(graph, endpoints[1], mode = "all")
    # Exclude the current edge from the incident edges
    incident_edges_1 <- setdiff(incident_edges_1, i)
    
    # Get the incident edges for the second endpoint
    incident_edges_2 <- incident(graph, endpoints[2], mode = "all")
    # Exclude the current edge from the incident edges
    incident_edges_2 <- setdiff(incident_edges_2, i)
    
    # Sum the weights of the incident edges for each endpoint
    sum_weights[i] <- sum(E(graph)[incident_edges_1]$weight) + sum(E(graph)[incident_edges_2]$weight)
  }
  
  # Return the vector containing the sum of weights for each edge
  return(sum_weights)
}

# variabile categoriale che indica quanti dei due nodi incidenti ad un arco sono hub
# hubs: vettore di hub da passare come argomento
edge_in_hubs <- function(graph, hubs) {
  # Get the number of edges in the graph
  num_edges <- ecount(graph)
  
  # Initialize a numeric vector to store the result for each edge
  edge_in_hub <- numeric(num_edges)
  
  # Iterate over each edge
  for (i in 1:num_edges) {
    # Get the endpoints of the current edge
    endpoints <- ends(graph, i)
    
    # Check if both endpoints are in the 'hubs' vector
    if (endpoints[1] %in% hubs && endpoints[2] %in% hubs) {
      edge_in_hub[i] <- 2  # Both endpoints are in 'hubs'
    } else if (endpoints[1] %in% hubs || endpoints[2] %in% hubs) {
      edge_in_hub[i] <- 1  # One endpoint is in 'hubs'
    } else {
      edge_in_hub[i] <- 0  # Neither endpoint is in 'hubs'
    }
  }
  
  # Return the numeric vector indicating if each edge has one or both endpoints in 'hubs'
  return(edge_in_hub)
}

# Modelling ---------------------------------------------------------------

# Modello senza tenere conto dei pesi -------------------------------------

# control parameters for ergm
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
# rapporto di quote vale 1.058

mod4 <- ergm(g.pesato.interg ~ edges + nodematch("urbano"))
summary(mod4)
# la variabile urbano risulta significativa quando si considera il node match 

#mod5 <- ergm(g.pesato.interg ~ edges +
#               nodematch("urbano") +
#               edgecov(g.pesato.interg, "urbanedge"),
#             control = control2)
#summary(mod5)
# non si riesce a trovare la stima che massimizza la pseudo-verosimiglianza
#anova(mod4, mod5)
# anche non arrivando a convergenza e con la variabile relativa
# alla covariata di arco, si nota una grande riduzione in termini
# di devianza

# modello markoviano con 1- e 2-stelle
mod.stelle <- ergm(g.pesato.interg ~ kstar(1:2) + nodematch("urbano"))
summary(mod.stelle)

mod.stelle.alt <- ergm(g.pesato.interg ~ altkstar(lambda = 1, fixed = TRUE) + nodematch("urbano"))
summary(mod.stelle.alt)

pchisq(deviance(mod.stelle)[1] - deviance(mod.stelle.alt)[1],
       df = 1,
       lower.tail = FALSE)

# Modelli tenendo conto del peso deli archi -------------------------------
ggplot() +
  aes(pesi) +
  geom_histogram(fill = "light blue", col = "black", binwidth = 1) + 
  ggtitle("Istogramma dei pesi degli archi") +
  xlab("Peso") +
  ylab("Frequenza") +
  theme_bw() +
  png("../../images/eda/weight_hist.png")

mod7 <- ergm(g.pesato.interg ~ sum,
             response = "weight", reference = ~Poisson)
summary(mod7)

mod8 <- ergm(g.pesato.interg ~ sum + nodematch("urbano"),
             response = "weight", reference = ~Poisson)
summary(mod8)

#' Il modello finale a quale arriviamo è un modello dove usiamo come covariata
#' la variabile urbano (che indica se una fermata è nella città di padova o no)
#' e modelliamo i pesi come risposta (con distribuzione di riferimento una Poisson)

mod9 <- ergm(g.pesato.interg ~ sum +
               edges + 
               nodematch("urbano"),
             response = "weight", reference = ~Poisson)
summary(mod9)

# interessante
# https://cran.r-project.org/web/packages/ergm.count/vignettes/valued.html

hubs <- c("padova autostazione",
          "padova piazzale boschetti",
          "padova stazione fs",
          "padova bassanello",
          "padova prato della valle",
          "padova ospedale",
          "monselice autostazione")

somma.pesi <- sum_weights_of_incident_edges(g.pesato)
somma.centralita <- sum_centrality_of_adjacent_nodes(g.pesato)
somma.gradi <- sum_degrees_of_incident_nodes(g.pesato)
somma.bet <- sum_betweenness_of_adjacent_nodes(g.pesato)
in.hub <- as.factor(edge_in_hubs(g.pesato, hubs))

zero.inf.mod <- zeroinfl(I(pesi - 1) ~ E(g.pesato)$urbanedge + log(somma.bet + 1) + somma.pesi + in.hub |  1,
                     dist = "poisson")

co <- coef(zero.inf.mod)
X <- model.matrix(zero.inf.mod)
p <- NCOL(X)
# vettore dei valori attesi
mu.hat <- as.vector(exp(X %*% co[1:6]))
cphi.hat <- plogis(co[p+1]) # 1 - phi cappello
phi.hat <- 1 - cphi.hat # phi_i stimati

zip.exp <- sapply(0:20, function(n) {
  if (n == 0) {
    mean(cphi.hat) + mean(phi.hat * dpois(n, mu.hat))
  }
  else {
    mean(phi.hat * dpois(n, mu.hat))
  }
})
table(pesi - 1)
pesi.complete <- c(751, 119, 34, 17, 6, 4, 6, 7, 2, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1)

mat <- cbind(pesi.complete, 951* round(zip.exp, 2))
rownames(mat) <- 1:21
colnames(mat) <- c("pesi", "stime")

mat