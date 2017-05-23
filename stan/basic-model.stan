////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Title: Basic Model
// Author: Steve Lane
// Date: Monday, 22 May 2017
// Synopsis: Fits a basic difference of abilities model to AFL scores data.
// Time-stamp: <2017-05-23 19:53:00 (steve)>
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

data{
  // Data to be supplied to sampler
  /* Number of teams */
  int<lower=1> nteams;
  /* Number of games */
  int<lower=1> ngames;
  /* Number of rounds */
  int<lower=1> nrounds;
  /* Round number of game */
  int<lower=1> roundNo[ngames];
  /* Home team ID */
  int<lower=1,upper=nteams> home[ngames];
  /* Away team ID */
  int<lower=1,upper=nteams> away[ngames];
  /* Ability from previous season (shrunk towards 0) */
  row_vector[nteams] preSeasonAbility;
  /* Score difference */
  vector[ngames] scoreDiff;
}

parameters{
  // Parameters for the model
  /* Home ground advantage (mean) */
  real hga;
  /* Preseason ability coef */
  real bPreSeason;
  /* Initial team variation */
  real<lower=0> sigma_a0;
  /* Scaling parameter for variation */
  real<lower=0> tau_a;
  /* Degrees of freedom */
  real<lower=1> nu;
  /* Std. dev. for score difference */
  real<lower=0> sigma_y;
  /* Variation in team abilities across a season (raw) */
  row_vector<lower=0>[nteams] sigma_a_raw;
  /* Random variation around week-to-week variability */
  matrix[nrounds,nteams] eta_a;
}

transformed parameters{
  /* Team abilities */
  matrix[nrounds, nteams] a;
  /* Variation in team abilities across a season */
  row_vector<lower=0>[nteams] sigma_a;
  /* Abilities before season */
  a[1] = bPreSeason * preSeasonAbility + sigma_a0 * eta_a[1];
  /* Adjusted variation */
  sigma_a = tau_a * sigma_a_raw;
  /* Round by round team ability evolution */
  for (r in 2:nrounds) {
    a[r] = a[r-1] + sigma_a .* eta_a[r];
  }
}

model{
  // Model sampling statements
  /* Difference in abilities */
  vector[ngames] a_diff;
  // Priors
  nu ~ gamma(2,0.1);
  bPreSeason ~ normal(0, 5);
  sigma_a0 ~ normal(0,10);
  sigma_y ~ normal(0,10);
  hga ~ normal(0,5);
  sigma_a_raw ~ normal(0,1);
  tau_a ~ cauchy(0,2.5);
  to_vector(eta_a) ~ normal(0,1);
  // Likelihood
  for (g in 1:ngames) {
    a_diff[g] = a[roundNo[g],home[g]] - a[roundNo[g],away[g]];
  }
  scoreDiff ~ student_t(nu, a_diff + hga, sigma_y);
}

generated quantities{
  // Statements for predictive outputs, e.g. new data
  vector[ngames] scoreDiffRep;
  vector[ngames] errorRep;
  for (g in 1:ngames){
    scoreDiffRep[g] = student_t_rng(nu, a[roundNo[g],home[g]] - 
				    a[roundNo[g],away[g]] + hga, sigma_y);
    errorRep[g] = (scoreDiff[g] - scoreDiffRep[g])^2;
  }
}
