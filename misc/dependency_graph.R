#make a graph of the relationships between the functions in my package
#https://datastorm-open.github.io/DependenciesGraphs/

devtools::install_github("datastorm-open/DependenciesGraphs")
library(DependenciesGraphs)
library(ididvar)

dep <- envirDependencies("package:ididvar")

# visualization
plot(dep)
