#' @title Simulate Drift
#'
#' @description Simulate drift across a number of populations and generations, for a single allele
#'
#' @param f0 The allele frqeuency pre-bottleneck
#' @param N0 The effective population size pre-bottleneck
#' @param Nt The effective population size after 't' generations
#' @param t The number of generations
#' @param n The number of populations
#' @param mig The migration rate
#' @param surv The survival rate at the original population bottleneck
#' @param litter The litter size at each generation
#' @param pops Specify the method for generating f0 in surrounding populations.
#' Choosing \code{pops = "same"} gives neighbouring populations with the same starting frequency.
#' Choosing \code{pops = "flip50"} gives neighbouring populations where allele frequencies are flipped between 0.5 and 1,
#' such that if f0 = 0.55, in neighbouring populations it will be given f0 = 0.95.
#' Choosing \code{pops = "flip100"} gives neighbouring populations with allele frequencies flipped between 0 and 1,
#' such that if f0 = 0.55, neighbouring populations will be given f0 = 0.45.
#' Choosing either \code{pops = "fixed"} or \code{pops = "absent"} will set the alleles to be strictly fixed or absent in the neighbouring populations.
#' @param sd The variability of allele frequencies in neighbouring populations around the central population.
#' @param genoProbs A vector of length three indicating the selective advantage for each genotype.
#' Should be specified as relative probabilities and defaults to the vector \code{c(1, 1, 1)},
#' giving an equal probability of selection to each genotype.
#' By way of example, a 20\% fitness increase for a homozygous reference allele could be given the vector \code{c(1.2, 1, 1)}.
#'
#' @details Starting with the initial population size, which is equal across all populations,
#' all populations are subject to the same bottleneck with survival probability as given in the argument \code{surv}.
#' Populations are grown exponentially until reaching \code{Nt}, and despite the given litter-size,
#' only the appropriate number will be allowed to breed at each generation.
#'
#' By default, all neighbouring populations will be given the same initial frequency as the central population.
#' These can be varied around this value on the logit scale using the parameter \code{sd}.
#' Choosing values such as \code{sd < 0.5} will give moderate variability around the starting frequency,
#' whilst values near one will clearly spread the allele frequencies more widely across the entire range.
#' Extreme values such as \code{sd = 100} will give alleles which are effectively either fixed or absent in the neighbouring populations with equal probability.
#'
#'
#' @return A list with components \code{ft} and \code{nEff}.
#' These denote the final allele frequency, and the effective populations sizes at each generation respectively.
#'
#' @examples
#' test <- simDrift(f0 = 0.8, N0 = 100, Nt = 200, t = 10, n = 6, mig = 0.01, surv = 0.1, litter= 6)
#'
#' @import magrittr
#'
#' @export
simDrift <- function(f0, N0, Nt, t, n, mig, surv, litter,
                     pops = c("same", "flip50", "flip100", "fixed", "absent"), sd = 0, genoProbs = c(1, 1, 1), ...){

  # Convert all to integers where required
  N0 <- as.integer(N0)
  Nt <- as.integer(Nt)
  t <- as.integer(t)
  n <- as.integer(n)
  litter <- as.integer(litter)

  # Check all variables
  stopifnot(c(f0 > 0, f0 < 1)) # The original frequency must be between 0 & 1
  stopifnot(!is.na(c(N0, Nt, t, n, litter))) # Ensure all required as integers were specified as numeric
  stopifnot(c(t, n) > 0) # There must be at least one generation & one population
  stopifnot(c(mig >= 0, mig < 1)) # Zero migration is acceptable
  stopifnot(c(surv > 0, surv <= 1)) # 100% survival is aceptable if there is no bottleneck
  stopifnot(litter >= 3) # Litters must be greater than 2 for population growth
  stopifnot(pops %in% c("same", "flip50", "flip100", "fixed", "absent")) # Only valid settings
  if (missing(pops)) pops <- "same"
  if (length(pops) > 1) {
    message("More than one value provided for the variable pops. Only the first value will be used")
    pops <- pops[1]
  }
  stopifnot(sd >= 0)
  stopifnot(length(genoProbs) == 3, is.numeric(genoProbs))

  # Assuming all is good, get into the function
  logit <- binomial()$linkfun
  inv.logit <- binomial()$linkinv

  # Set the starting frequencies
  if (pops == "same"){
    other_f0 <- rnorm(n - 1, logit(f0), sd) %>% inv.logit
  }
  if (pops == "flip50"){
    other_f0 <- rnorm(n - 1, logit(1.5 - f0), sd) %>% inv.logit
  }
  if (pops == "flip100"){
    other_f0 <- rnorm(n - 1, logit(1 - f0), sd) %>% inv.logit
  }
  if (pops == "fixed") other_f0 <- rep(1, n - 1)
  if (pops == "absent") other_f0 <- rep(0, n - 1)
  f0 <- c(f0, other_f0)

  # Build a data.frame of migration probabilities
  migDf <- as.data.frame(setMigProbs(n, mig))

  # Simulate the starting populations
  pop0 <- lapply(f0, function(x){
    # The initial population genotypes
    gt <- rbinom(n = 2*N0, size = 2, prob = 1 - x)
    # The sizes post- bottleneck
    sz <- rbinom(1, length(gt), surv)
    # Select the survivors based on any selective advantage
    sample(gt, sz, prob = genoProbs[gt+1])

  })

  # Check that all populations are viable (i.e have >= 2 members)
  viable <- vapply(pop0, function(x){length(x)>=2}, logical(1))
  if (any(!viable)) stop("One or more populations are too small to be viable post-bottleneck")

  # Estimate population growth for each population
  genSizes <- lapply(pop0, function(x){
    seq(log(length(x)/2), log(Nt), length.out = t + 1) %>%
      exp %>%
      round(0) %>%
      extract(-1)
  })

  # Form into breeding pairs.
  # If an odd number of individuals is in a population, assume polygamy and use recursion
  pairs <- vector("list", t + 1)
  pairs[[1]] <- lapply(pop0, function(x){suppressWarnings(matrix(x, ncol = 2))})

  for (i in 1:t){
    # Breed at every iteration
    progeny <- lapply(pairs[[i]], breedInPairs, litter = litter)

    # Allow migration pre-survival
    progeny <- migrate(progeny, mig, migDf)

    # Check population sizes are appropriate
    nKeep <- lapply(genSizes, magrittr::extract, i)
    popVsKeep <- mapply(function(pop, n){length(pop) > 2*n},
                        pop = progeny,
                        n = nKeep,
                        SIMPLIFY = FALSE)
    if (any(!unlist(popVsKeep))) stop("Breeding rates unable to give required final population size")

    # Select the breeding population for the next generation
    pairs[[i+1]] <- mapply(function(pop, n){
      matrix(sample(x = pop,
                    size = 2*n,
                    prob = genoProbs[pop + 1]), ncol = 2)
    },
    pop = progeny,
    n = nKeep,
    SIMPLIFY = FALSE)


  }

  # Return population 1 as the population of interest
  list(ft = mean(2 - progeny[[1]])/2,
       nEff = genSizes[[1]])

}
