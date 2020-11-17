cls
clear all 
set more off

global project "/Users/taylorjaworski/Dropbox/Papers/EH/RegionalDevelopment/transportation/LongRunMarketAccess"

***********************
* CREATE CENTROID DTA *
***********************

	qui import delimited "$project/data/traveltime/centroids_new.csv", clear
	qui g id = _n
	rename (geoid intptlat intptlon) (fips latitude longitude)
	keeporder id name fips latitude longitude
	save "$project/data/traveltime/temp/centroids.dta", replace

***************************
* CREATE TRAVEL TIME DATA *
***************************

	/* load travel time txt */
		
		foreach year of num 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010 {
			forvalues cost = 1/1 {
				
				*actual travel times and distance
				if `year' == 1920 {
				qui import delimited "$project/data/traveltime/cost3_`year'.txt", clear
				rename (total_cost3 total_distance) (hours_`year'_cost`cost' dist_`year'_cost`cost')
				}
				if `year' == 1930 {
				qui import delimited "$project/data/traveltime/cost3_`year'.txt", clear
				rename (total_cost3 total_distance) (hours_`year'_cost`cost' dist_`year'_cost`cost')
				}
				if `year' > 1930 {
				qui import delimited "$project/data/traveltime/cost`cost'_`year'.txt", clear
				rename (total_cost`cost' total_distance) (hours_`year'_cost`cost' dist_`year'_cost`cost')
				}
				
				keeporder originid destinationid hours_`year'_cost`cost' dist_`year'_cost`cost'
				capture replace originid = subinstr(originid,",","",.) 
				capture replace destinationid = subinstr(destinationid,",","",.) 
				capture replace dist_`year'_cost`cost' = subinstr(dist_`year'_cost`cost',",","",.) 
				qui destring originid destinationid dist_`year'_cost`cost', replace
				qui save "$project/data/traveltime/temp/travel_`year'_cost`cost'.dta", replace
			
				}
			}
	
	/* merge travel time dta */
		
		use "$project/data/traveltime/temp/travel_1920_cost1.dta", clear

	/* merge origin id fips */
		
		rename originid id
		qui merge m:m id using "$project/data/traveltime/temp/centroids.dta", nogen
		qui do "$project/do/fix_VA_counties2.do"
		rename (id name fips latitude longitude) (originid origin_name origin_fips origin_latitude origin_longitude)

	/* merge destination id fips */
		
		rename destinationid id
		qui merge m:m id using "$project/data/traveltime/temp/centroids.dta", nogen
		qui do "$project/do/fix_VA_counties2.do"
		rename (id name fips latitude longitude) (destinationid destination_name destination_fips destination_latitude destination_longitude)

	/* calculate physical distance between county pairs */
	
		geodist origin_latitude origin_longitude destination_latitude destination_longitude, g(distance) miles
		keeporder origin* destination* distance dist_* hours_*

	/* append travel time dta */
	
		local files "1930_cost1 1940_cost1 1950_cost1 1960_cost1 1970_cost1 1980_cost1 1990_cost1 2000_cost1 2010_cost1"
		foreach f of local files{
			qui merge m:m originid destinationid using "$project/data/traveltime/temp/travel_`f'.dta"
			keeporder origin* destination* distance dist_* hours_* 
			}
		local files "1930_cost1 1940_cost1 1950_cost1 1960_cost1 1970_cost1 1980_cost1 1990_cost1 2000_cost1 2010_cost1"
		foreach f of local files{
			qui replace hours_`f' = round(hours_`f',.001)
			qui replace dist_`f' = round(dist_`f',.001)
			}
			
	/* collapse to final fips codes */
	
		collapse (mean) origin_latitude origin_longitude distance dist_* hours_* , by(destination_fips origin_fips)
	
	/* save data */
	
		qui save "$project/data/traveltime/traveltime_1920_2010.dta", replace
	
	/* use data */
	
		qui use "$project/data/traveltime/traveltime_1920_2010.dta", clear
	
	/*  collapse to sample counties */
		
		preserve
		qui import delimited using "$project/matlab/input/Fips.csv",clear
		rename v1 fips
		qui save "$project/matlab/input/Fips.dta",replace
		restore
		
		rename origin_fips fips
		merge m:m fips using "$project/matlab/input/Fips.dta"
		keep if _m==3
		rename fips origin_fips
		drop _m
	
		rename destination_fips fips
		merge m:m fips using "$project/matlab/input/Fips.dta"
		keep if _m==3
		rename fips destination_fips
		drop _m
	
		qui save "$project/data/traveltime/traveltime_1920_2010.dta", replace
		rm "$project/matlab/input/Fips.dta"
	
	/* convert travel time and distance to iceberg costs before exporting to Matlab */

		**average value of ton shipped [in 2020 dollars]
			* Source for average value for 2010 [used 2012] is http://www.ops.fhwa.dot.gov/freight/freight_analysis/nat_freight_stats/docs/13factsfigures/pdfs/fff2013.pdf [pp. 3, 4]
			scalar define avgvalue2010 = (1.03*10531000)/12973 /* initial value in 2012 dollars converted to 2015 dollars using http://www.bls.gov/data/inflation_calculator.htm */
			scalar define hrly_trucker_wage1920 = 0.793*13.37 /* use 1940 wage, could use: https://fraser.stlouisfed.org/files/docs/publications/bls/bls_0286_1921.pdf */
			scalar define hrly_trucker_wage1930 = 0.793*15.09 /* use 1940 wage */
			scalar define hrly_trucker_wage1940 = 0.793*18.55 /* from https://fraser.stlouisfed.org/files/docs/publications/bls/bls_0676_1940.pdf for 1940 */
			scalar define hrly_trucker_wage1950 = 01.60*10.97 /* from https://fraser.stlouisfed.org/files/docs/publications/bls/bls_1012_1951.pdf for 1950 */
			scalar define hrly_trucker_wage1960 = 02.68*08.80 /* from https://fraser.stlouisfed.org/files/docs/publications/bls/bls_1291_1961.pdf for 1960 */
			scalar define hrly_trucker_wage1970 = 04.41*06.82 /* from https://fraser.stlouisfed.org/files/docs/publications/bls/bls_1708_1971.pdf for 1970 */
			scalar define hrly_trucker_wage1980 = 06.79*03.31 /* from CPS for 1980 */
			scalar define hrly_trucker_wage1990 = 10.32*02.02 /* from CPS for 1990 */
			scalar define hrly_trucker_wage2000 = 13.56*01.53 /* from CPS for 2000 */
			scalar define hrly_trucker_wage2010 = 19.29*01.19 /* from CPS for 2010 */

		**dollars per mile = (dollars per gallon)*(gallons per mile) 
			* Source for dollars per gallon in 1940 - 2010 is http://energy.gov/eere/vehicles/fact-915-march-7-2016-average-historical-annual-gasoline-pump-price-1929-2015
			* Source for gallons per mile for 1940 - 1990 is https://www.fhwa.dot.gov/ohim/summary95/vm201a.pdf
			* Source for gallons per mile for 2000 and 2010 is http://www.fhwa.dot.gov/policyinformation/statistics/2010/vm1.cfm
			scalar define dollars_permile1920 = 13.37*2.30*(1/10.2) /* Use 1936 efficiency, Use 1930 price per gallon */
			scalar define dollars_permile1930 = 15.09*2.30*(1/10.2) /* Use 1936 efficiency, Use 1930 price per gallon */
			scalar define dollars_permile1940 = 18.55*2.49*(1/9.7)
			scalar define dollars_permile1950 = 10.97*2.14*(1/8.4)
			scalar define dollars_permile1960 = 08.80*1.95*(1/8.0)
			scalar define dollars_permile1970 = 06.82*1.72*(1/5.5)
			scalar define dollars_permile1980 = 03.31*2.95*(1/5.4)
			scalar define dollars_permile1990 = 02.02*1.89*(1/6.0)
			scalar define dollars_permile2000 = 01.53*2.02*(1/5.3)
			scalar define dollars_permile2010 = 01.19*3.02*(1/5.9)

		foreach year of num 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010 {
		forvalues cost = 1/1 {
			
			*actual trade costs
			qui g tau_`year'_cost`cost' = 1 + (hrly_trucker_wage`year'*hours_`year'_cost`cost' + dist_`year'_cost`cost'*dollars_permile`year')/avgvalue2010
			qui g d_`year'_cost`cost' = 1 + (distance*dollars_permile`year')/avgvalue2010	
			
			}
			}
			
			sum tau_*
			sum d_*
			
	/* export ACTUAL tau to Matlab */
	
		sort origin_fips destination_fips
		foreach year of num 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010 {
		forvalues cost = 1/1 {
			
			preserve
			keep origin_fips destination_fips tau_`year'_cost`cost'
			sort origin_fips destination_fips
			qui reshape wide tau_`year'_cost`cost', i(origin_fips) j(destination_fips)
			qui export delimited tau_* using "$project/matlab/input/Tau`year'cost`cost'.csv", novarnames replace
			restore
			
			}
			}
	
	/* export ACTUAL distance to Matlab */
		/*
		sort origin_fips destination_fips
		foreach year of num 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010 {
		forvalues cost = 1/1 {
			
			preserve
			keep origin_fips destination_fips d_`year'_cost`cost'
			sort origin_fips destination_fips
			qui reshape wide d_`year'_cost`cost', i(origin_fips) j(destination_fips)
			qui export delimited d_* using "$project/matlab/input/Dist`year'cost`cost'.csv", novarnames replace
			restore
			
			}
			}
		*/
	/* remove temporary files */
		
		local files "1940_cost1 1950_cost1 1960_cost1 1970_cost1 1980_cost1 1990_cost1 2000_cost1 2010_cost1"
		foreach f of local files{
			rm "$project/data/traveltime/temp/travel_`f'.dta"
			}

		rm "$project/data/traveltime/temp/centroids.dta"
	
