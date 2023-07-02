/* Chapter 11: Statistical Functions in SQL */

/* We'll be going over some of the powerful stats packages offered in PostgreSQL, and therefore how to apply
high level statistical concepts to derive meaning from data in PostgreSQL. Also, how to create rankings, calculate rates, 
and how to smooth out timeseries data using rolling averages and sums. 
*/

/* Step 1: Let's set up our environment by creating the table and importing the data. */

CREATE TABLE acs_2014_2018_stats (
	geoid text CONSTRAINT geoid_key PRIMARY KEY,
	county text NOT NULL,
	st text NOT NULL,
	pct_travel_60_min numeric(5,2), -- percentage of workers 16+ who commute 60+ minutes to work
	pct_bachelors_higher numeric(5,2), --% of people 25+ who have 16+ yrs of education
	pct_masters_higher numeric(5,2), -- % of people 25+ who have 18+ yrs of education
	median_hh_income integer, -- county's median household income in 2018 (adjusted for inflation)
	CHECK (pct_masters_higher <= pct_bachelors_higher)
);

COPY acs_2014_2018_stats
FROM '/Users/hannahbdr/Desktop/DataAnalysis/PracticalSQL/Chapter_11/acs_2014_2018_stats.csv'
WITH (FORMAT CSV, HEADER);

-- Cool, let's take a look!
SELECT *
FROM acs_2014_2018_stats;
-- We have 7 columns, and 3142 rows 

/* Step 2: Let's calculate correlation coefficients  

We're going to calculate the correlation between the % of people with a Bachelor's degree or higher in a given county, 
and the median household income in that county.  To determine if a higher level of education equates to a higher income.

Here's a list of Correlation Coefficient's Interpretations:
	* 0 - No relationship
	* (.01 : .29) - Weak relationship
	* (.3 : .59) - Moderate relationship
	* (.6 : .99) - Strong relationship
	* 1 - Perfect relationship
*/

SELECT corr(median_hh_income, pct_bachelors_higher) 
	AS bachelors_income_corr
FROM acs_2014_2018_stats;
-- 0.6999, looks like its a strong relationship!

-- Okay, let's check a couple other correlation coefficients 
SELECT
	round(
		corr(median_hh_income, pct_bachelors_higher)::numeric, 2) AS bachelors_income_corr,
	round(
		corr(pct_travel_60_min, median_hh_income)::numeric, 2) AS income_travel_corr,
	round(
		corr(pct_travel_60_min, pct_bachelors_higher)::numeric, 2) AS bachelors_travel_corr
FROM acs_2014_2018_stats;
-- Looks like we got 0.70, 0.06, and -0.14 respectively. 

/*So, our initial correlation is strong, but the correlation b/w income & traveling to work 
as well as the aorrelation b/w degree and traveling to work are both weak.

It would be interesting to re-run this analysis with data from 2021 - 2023 to see if the last 
correlation coefficient has changed since the pandemic. 
*/

/* Step 3: Linear regression to make predications 

The formula for the least squares regression line is Y= bX + a

If we know what our X value is, then we can use SQL to calculate b(slope) and a(y-intercept).
*/

-- Let's see if we can determine what a county's median household income would be if 30% of the population had a BA+

SELECT
	round(
		regr_slope(median_hh_income, pct_bachelors_higher)::numeric, 2) AS slope,
	round(
		regr_intercept(median_hh_income, pct_bachelors_higher)::numeric, 2) AS y_intercept
FROM acs_2014_2018_stats;
-- slope: 1016.55, and y_intercept: 29651.42

/* 
The value for slope means that for every one-unit increase in Bachelor's degree percentage, the county's median 
household income increases $1016.55.  

The y-intercept value shows us what the base value of a county's median household income is, regardless of BA degrees. 

Now we can calculate what a county's expected median value is for household income, if 30% of the pop has a BA degree.
(1016.55 * 30) + 29651.42 = 60,147.92

So, county's where 30% of the population have a BA degree, the median household income is ~60K
*/

/* Step 4: Coefficient of Determination

The coefficient of determination, or r-squared, is used to determine the extent that the variation in the independent 
variable explains the variation in the dependent variable.  
 
Let's see what extent the variation of a county's pop having BA degrees, has on the variation of median household incomes.
*/

SELECT
	round(
		regr_r2(median_hh_income, pct_bachelors_higher)::numeric, 3) AS r_squared
FROM acs_2014_2018_stats;
-- 0.490, so 49% of the variation in a county's median household income, is explained by the percentage of it's pop w/ BA degrees
-- Any number of factors can make up the other 51%. 

/* Step 5: Variance & Standard Deviation

- var_pop(numeric) calculates the population variance (i.e. a dataset containing ALL possible values) 
- var_samp(numeric) calculates the sample variance (i.e. a dataset containing only a PORTION of all possible values) 
- stddev_pop(numeric) calculates the population standard deviation
- stddev_samp(numeric) calculates the sample standard deviation 

Let's see if we can apply any of this to our data
*/

SELECT 
	round(
		var_pop(median_hh_income)::numeric, 2) AS income_var,
	round(
		stddev_pop(median_hh_income)::numeric, 2) AS income_sd
FROM acs_2014_2018_stats;
-- Okay, I have no idea what these #'s mean, SD: 13701.32 & Var: 187726187.18






