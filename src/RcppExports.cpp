// This file was generated by Rcpp::compileAttributes
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// breed
NumericVector breed(IntegerVector pair, int litter);
RcppExport SEXP driftSim_breed(SEXP pairSEXP, SEXP litterSEXP) {
BEGIN_RCPP
    Rcpp::RObject __result;
    Rcpp::RNGScope __rngScope;
    Rcpp::traits::input_parameter< IntegerVector >::type pair(pairSEXP);
    Rcpp::traits::input_parameter< int >::type litter(litterSEXP);
    __result = Rcpp::wrap(breed(pair, litter));
    return __result;
END_RCPP
}
// breedInPairs
NumericVector breedInPairs(IntegerMatrix pairs, int litter);
RcppExport SEXP driftSim_breedInPairs(SEXP pairsSEXP, SEXP litterSEXP) {
BEGIN_RCPP
    Rcpp::RObject __result;
    Rcpp::RNGScope __rngScope;
    Rcpp::traits::input_parameter< IntegerMatrix >::type pairs(pairsSEXP);
    Rcpp::traits::input_parameter< int >::type litter(litterSEXP);
    __result = Rcpp::wrap(breedInPairs(pairs, litter));
    return __result;
END_RCPP
}
// setMigProbs
NumericMatrix setMigProbs(int n, double mig);
RcppExport SEXP driftSim_setMigProbs(SEXP nSEXP, SEXP migSEXP) {
BEGIN_RCPP
    Rcpp::RObject __result;
    Rcpp::RNGScope __rngScope;
    Rcpp::traits::input_parameter< int >::type n(nSEXP);
    Rcpp::traits::input_parameter< double >::type mig(migSEXP);
    __result = Rcpp::wrap(setMigProbs(n, mig));
    return __result;
END_RCPP
}
