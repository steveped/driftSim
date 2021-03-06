% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/migrate.R
\name{migrate}
\alias{migrate}
\title{Simulate migration}
\usage{
migrate(pops, rate, migrationProbs)
}
\arguments{
\item{pops}{A list of populations with each containing a vector of individuals as 0, 2 or 2}

\item{rate}{The upper bound on the migration rate}

\item{migrationProbs}{A data.frame with columns of probabilities for migration}
}
\value{
A list of populations with the same length as supplied in pops.
The rate of shuffling between populations will have been performed according
to the migration rate specified in the function call.
Population sizes may vary slightly post migration
}
\description{
Simulate migration between populations.
Equal migration between populations is assumed
The size of the first population is used to determine the number of migrants
}
\details{
To model migration, the first population is taken as the centre of a circle.
All populations are in contact with this population, but only have two neighbours.
Migration can thus occur between the central population and all others, but only between neighbours in the outer ring.
This is done by assigning probabilites of population membership to each individual based on it's original population.
}
\examples{
pops <- lapply(c(10, 12, 14, 10, 10), function(x){sample(0:2, x, replace = TRUE)})
n <- length(pops)
mig <- 0.1
migDf <- data.frame(Pop1 = c(1 - mig, rep(mig/(n-1), n - 1)))
for (i in 2:n){
  migDf[[i]] <- rep(0, n)
  migDf[[i]][1] <- mig/3
  migDf[[i]][i] <- 1- mig
  migDf[[i]][ifelse(i + 1 > n, 2, i + 1)] <- mig/3
  migDf[[i]][ifelse(i - 1 < 2, n, i - 1)] <- mig/3
}
names(migDf) <- paste0("Pop", 1:n)
# Now perform simulated migration
migrate(pops, mig, migDf)

}

