cls
clear all 
set more off

********************************************************************************

global project "/Users/taylorjaworski/Dropbox/Papers/EH/RegionalDevelopment/transportation/LongRunMarketAccess"
global github "/Users/taylorjaworski/Documents/GitHub/jaworskit.github/articles/ww2-tva"

********************************************************************************

	foreach year in 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010 {
	import delimited "$github/data/marketaccess/output/MA`year'_cost1.csv",clear
	rename (v1 v2) (fips marketaccess)
	if `year' == 1920 {
	qui g year = `year'
	qui save "$github/data/marketaccess/output/MA`year'.dta",replace
	}
	if `year' == 1930 {
	qui g year = `year'
	qui save "$github/data/marketaccess/output/MA`year'.dta",replace
	}
	if `year' == 1940 {
	qui g year = `year'
	qui save "$github/data/marketaccess/output/MA`year'.dta",replace
	}
	if `year' == 1950 {
	qui g year = 1947
	qui save "$github/data/marketaccess/output/MA1947.dta",replace
	qui replace year = 1954
	qui save "$github/data/marketaccess/output/MA1954.dta",replace
	}
	if `year' == 1960 {
	qui g year = 1958
	qui save "$github/data/marketaccess/output/MA1958.dta",replace
	qui replace year = 1963
	qui save "$github/data/marketaccess/output/MA1963.dta",replace
	}
	if `year' == 1970 {
	qui g year = 1967
	qui save "$github/data/marketaccess/output/MA1967.dta",replace
	qui replace year = 1972
	qui save "$github/data/marketaccess/output/MA1972.dta",replace
	}
	if `year' == 1980 {
	qui g year = 1977
	qui save "$github/data/marketaccess/output/MA1977.dta",replace
	qui replace year = 1982
	qui save "$github/data/marketaccess/output/MA1982.dta",replace
	}
	if `year' == 1990 {
	qui g year = 1987
	qui save "$github/data/marketaccess/output/MA1987.dta",replace
	}
	}
	
	clear all
	foreach year in 1920 1930 1940 1947 1954 1958 1963 1967 1972 1977 1982 1987 {
	append using "$github/data/marketaccess/output/MA`year'.dta"
	rm "$github/data/marketaccess/output/MA`year'.dta"
	}
	qui replace marketaccess = (marketaccess^-8)/1000000000
	qui save "$github/data/dta/marketaccess.dta",replace
	
	by year, sort: sum mark
	
********************************************************************************

	use "$github/data/dta/data-figure4.dta",clear

	* merge market access data
	
		merge m:m year fips using "$github/data/dta/marketaccess.dta"
		keep if _merge==3
		drop _merge

********************************************************************************

	* variables : World War II facilities, contracts
	
		qui g contracts = wrsccomb + wrscoth
		replace contracts = 0 if contracts ==.
		qui g invest = private_structures + public_structures
		local years "1920 1930 1947 1954 1958 1963 1967 1972 1977 1982 1987"
		foreach var of varlist invest private_structures public_structures contracts {
			qui replace `var' = 0 if `var'==.
			qui g ln_`var' = ln(`var'+1)
			foreach t of local years{
				qui g double ln_`var'_`t' = (year==`t')*ln_`var'	
				}
			}	
		
		local years "1920 1930 1947 1954 1958 1963 1967 1972 1977 1982 1987"
		foreach t of local years{
			qui g plant_`t' = plant*(year==`t')
			}
		
		local years "1920 1930 1947 1954 1958 1963 1967 1972 1977 1982 1987"
		foreach t of local years{
			qui g tva_`t' = tva*(year==`t')
			}
			
	* variables : county-level controls
	
		qui g x_centroid2 = x_centroid^2
		qui g y_centroid2 = y_centroid^2
		local years "1930 1940 1947 1954 1958 1963 1967 1972 1977 1982 1987"
		local vars "density40 share_urban40 share_foreign40 share_black40 x_centroid x_centroid2 y_centroid y_centroid2"
		foreach t of local years{
		foreach v of local vars{
			qui replace `v' = 0 if `v'==.
			qui g control_`v'_`t' = `v'*(year==`t')
			}
			}
			
	* variables : manufacturing outcomes
	
		sort fips year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui g `var'_temp = `var' if year==1940
			qui egen `var'_1940 = max(`var'_temp), by(fips)
			by fips, sort: g double ln_`var' = ln(`var' + 1)
			by fips, sort: g double dln_`var' = ln(`var' + 1) -  ln(`var'_1940 + 1)
			}
	
	* variables : market access
	
		qui g ln_marketaccess = log(marketaccess)

****** Effect of WW2 Investment ************************************************

	* without Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg ln_`var' ln_invest_* ln_contracts_* _I* control_* tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(ln_invest_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
								
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(ln_invest_1*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			ln_invest_1920 "1920" ///
			ln_invest_1930 "1930" ///
			ln_invest_1947 "1947" ///
			ln_invest_1954 "1954" ///
			ln_invest_1958 "1958" ///
			ln_invest_1963 "1963" ///
			ln_invest_1967 "1967" ///
			ln_invest_1972 "1972" ///
			ln_invest_1977 "1977" ///
			ln_invest_1982 "1982" ///
			ln_invest_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withoutMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-without-MA.dta", replace

		restore
		
********************************************************************************

	* with Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg dln_`var' ln_invest_1* ln_contracts_1* control_* _I* ln_marketaccess tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(ln_invest_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
			
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(ln_invest_1*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			ln_invest_1920 "1920" ///
			ln_invest_1930 "1930" ///
			ln_invest_1947 "1947" ///
			ln_invest_1954 "1954" ///
			ln_invest_1958 "1958" ///
			ln_invest_1963 "1963" ///
			ln_invest_1967 "1967" ///
			ln_invest_1972 "1972" ///
			ln_invest_1977 "1977" ///
			ln_invest_1982 "1982" ///
			ln_invest_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-with-MA.dta", replace

		restore
	
	*Make Figure
	
		preserve 
		
		clear all
		append using "$github/results/fig-without-MA.dta"
		append using "$github/results/fig-with-MA.dta"
		qui gen b_upper = b+1.96*se
		qui gen b_lower = b-1.96*se
		
		sort variable spec year
		replace variable ="Establishments"  if variable=="mfg_est"
		replace variable ="Employment"  if variable=="mfg_emp"
		replace variable ="Wage Bill"  if variable=="mfg_wages"
		replace variable ="Value-Added"  if variable=="mfg_val"
		
		foreach var in "Establishments" "Employment" "Wage Bill" "Value-Added" {
		
		qui sum b_upper if variable=="`var'"
		scalar temp_max = round(`r(max)'+.1,.1)
		qui sum b_lower if variable=="`var'"
		scalar temp_min = round(`r(min)'-.1,.1)
		scalar temp = max(abs(`=temp_max'),abs(`=temp_min'))
		
		qui gr tw 	(line b year 		if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(solid)) 	///
					(line b_upper year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	/// 
					(line b_lower year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	///
					(line b year 	if variable=="`var'" & spec=="withMA", lcolor(blue) lpattern(solid)) 			///
					, yline(`=-1*temp', lc(none)) yline(`=temp', lc(none)) legend(off) ///
					xtitle(" ") ytitle("Estimated Coefficients") xlabel(1920(20)1990, grid labsize(vlarge)) xmtick(1920(10)1990, grid) xscale(range(1920 1990)) ///
					ylabel(`=-1*temp'(`=temp/1')`=temp', format(%12.1f) labsize(vlarge)) ymtick(`=-1*temp'(`=temp/2')`=temp', grid gmin gmax) ///
					title("`var'", color(black)) graphregion(color(white)) saving("$github/results/`var'.gph",replace)
			}
		
		qui gr combine 	"$github/results/Establishments.gph" 	"$github/results/Employment.gph" ///
						"$github/results/Wage Bill.gph" 		"$github/results/Value-Added.gph" ///
						, graphregion(color(white)) rows(2) xsize(6)
		gr export "$github/results/WW2_invest.pdf", as(pdf) replace
		rm "$github/results/Establishments.gph" 
		rm "$github/results/Employment.gph" 
		rm "$github/results/Wage Bill.gph" 
		rm "$github/results/Value-Added.gph"
		*rm "$github/results/fig-without-MA.dta"
		*rm "$github/results/fig-with-MA.dta"
		
		restore

****** Effect of WW2 Contracts *************************************************

	* without Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg ln_`var' ln_invest_* ln_contracts_* _I* control_* tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(ln_contracts_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
								
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(ln_contracts_1*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			ln_contracts_1920 "1920" ///
			ln_contracts_1930 "1930" ///
			ln_contracts_1947 "1947" ///
			ln_contracts_1954 "1954" ///
			ln_contracts_1958 "1958" ///
			ln_contracts_1963 "1963" ///
			ln_contracts_1967 "1967" ///
			ln_contracts_1972 "1972" ///
			ln_contracts_1977 "1977" ///
			ln_contracts_1982 "1982" ///
			ln_contracts_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withoutMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-without-MA.dta", replace

		restore
		
********************************************************************************

	* with Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg dln_`var' ln_invest_1* ln_contracts_1* control_* _I* ln_marketaccess tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(ln_contracts_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
		
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(ln_contracts_1*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			ln_contracts_1920 "1920" ///
			ln_contracts_1930 "1930" ///
			ln_contracts_1947 "1947" ///
			ln_contracts_1954 "1954" ///
			ln_contracts_1958 "1958" ///
			ln_contracts_1963 "1963" ///
			ln_contracts_1967 "1967" ///
			ln_contracts_1972 "1972" ///
			ln_contracts_1977 "1977" ///
			ln_contracts_1982 "1982" ///
			ln_contracts_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-with-MA.dta", replace

		restore
	
	*Make Figure
	
		preserve 
		
		clear all
		append using "$github/results/fig-without-MA.dta"
		append using "$github/results/fig-with-MA.dta"
		qui gen b_upper = b+1.96*se
		qui gen b_lower = b-1.96*se
		
		sort variable spec year
		replace variable ="Establishments"  if variable=="mfg_est"
		replace variable ="Employment"  if variable=="mfg_emp"
		replace variable ="Wage Bill"  if variable=="mfg_wages"
		replace variable ="Value-Added"  if variable=="mfg_val"
		
		foreach var in "Establishments" "Employment" "Wage Bill" "Value-Added" {
		
		qui sum b_upper if variable=="`var'"
		scalar temp_max = round(`r(max)'+.1,.1)
		qui sum b_lower if variable=="`var'"
		scalar temp_min = round(`r(min)'-.1,.1)
		scalar temp = max(abs(`=temp_max'),abs(`=temp_min'))
		
		qui gr tw 	(line b year 		if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(solid)) 	///
					(line b_upper year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	/// 
					(line b_lower year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	///
					(line b year 	if variable=="`var'" & spec=="withMA", lcolor(blue) lpattern(solid)) 			///
					, yline(`=-1*temp', lc(none)) yline(`=temp', lc(none)) legend(off) ///
					xtitle(" ") ytitle("Estimated Coefficients") xlabel(1920(20)1990, grid labsize(vlarge)) xmtick(1920(10)1990, grid) xscale(range(1920 1990)) ///
					ylabel(`=-1*temp'(`=temp/1')`=temp', format(%12.1f) labsize(vlarge)) ymtick(`=-1*temp'(`=temp/2')`=temp', grid gmin gmax) ///
					title("`var'", color(black)) graphregion(color(white)) saving("$github/results/`var'.gph",replace)
			}
		
		qui gr combine 	"$github/results/Establishments.gph" 	"$github/results/Employment.gph" ///
						"$github/results/Wage Bill.gph" 		"$github/results/Value-Added.gph" ///
						, graphregion(color(white)) rows(2) xsize(6)
		gr export "$github/results/WW2_contracts.pdf", as(pdf) replace
		rm "$github/results/Establishments.gph" 
		rm "$github/results/Employment.gph" 
		rm "$github/results/Wage Bill.gph" 
		rm "$github/results/Value-Added.gph"
		*rm "$github/results/fig-without-MA.dta"
		*rm "$github/results/fig-with-MA.dta"
		
		restore

****** Effect of WW2 Plant *****************************************************

	* without Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg ln_`var' plant_19* _I* control_* tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(plant_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
								
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(plant_19*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			plant_1920 "1920" ///
			plant_1930 "1930" ///
			plant_1947 "1947" ///
			plant_1954 "1954" ///
			plant_1958 "1958" ///
			plant_1963 "1963" ///
			plant_1967 "1967" ///
			plant_1972 "1972" ///
			plant_1977 "1977" ///
			plant_1982 "1982" ///
			plant_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withoutMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-without-MA.dta", replace

		restore
		
********************************************************************************

	* with Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg dln_`var' plant_1* control_* _I* ln_marketaccess tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(plant_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
			
		
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(plant_1*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			plant_1920 "1920" ///
			plant_1930 "1930" ///
			plant_1947 "1947" ///
			plant_1954 "1954" ///
			plant_1958 "1958" ///
			plant_1963 "1963" ///
			plant_1967 "1967" ///
			plant_1972 "1972" ///
			plant_1977 "1977" ///
			plant_1982 "1982" ///
			plant_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-with-MA.dta", replace

		restore
	
	*Make Figure
	
		preserve 
		
		clear all
		append using "$github/results/fig-without-MA.dta"
		append using "$github/results/fig-with-MA.dta"
		qui gen b_upper = b+1.96*se
		qui gen b_lower = b-1.96*se
		
		sort variable spec year
		replace variable ="Establishments"  if variable=="mfg_est"
		replace variable ="Employment"  if variable=="mfg_emp"
		replace variable ="Wage Bill"  if variable=="mfg_wages"
		replace variable ="Value-Added"  if variable=="mfg_val"
		
		foreach var in "Establishments" "Employment" "Wage Bill" "Value-Added" {
		
		qui sum b_upper if variable=="`var'"
		scalar temp_max = round(`r(max)'+.1,.1)
		qui sum b_lower if variable=="`var'"
		scalar temp_min = round(`r(min)'-.1,.1)
		scalar temp = max(abs(`=temp_max'),abs(`=temp_min'))
		
		qui gr tw 	(line b year 		if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(solid)) 	///
					(line b_upper year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	/// 
					(line b_lower year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	///
					(line b year 	if variable=="`var'" & spec=="withMA", lcolor(blue) lpattern(solid)) 			///
					, yline(`=-1*temp', lc(none)) yline(`=temp', lc(none)) legend(off) ///
					xtitle(" ") ytitle("Estimated Coefficients") xlabel(1920(20)1990, grid labsize(vlarge)) xmtick(1920(10)1990, grid) xscale(range(1920 1990)) ///
					ylabel(`=-1*temp'(`=temp/1')`=temp', format(%12.1f) labsize(vlarge)) ymtick(`=-1*temp'(`=temp/2')`=temp', grid gmin gmax) ///
					title("`var'", color(black)) graphregion(color(white)) saving("$github/results/`var'.gph",replace)
			}
		
		qui gr combine 	"$github/results/Establishments.gph" 	"$github/results/Employment.gph" ///
						"$github/results/Wage Bill.gph" 		"$github/results/Value-Added.gph" ///
						, graphregion(color(white)) rows(2) xsize(6)
		gr export "$github/results/WW2_plant.pdf", as(pdf) replace
		rm "$github/results/Establishments.gph" 
		rm "$github/results/Employment.gph" 
		rm "$github/results/Wage Bill.gph" 
		rm "$github/results/Value-Added.gph"
		*rm "$github/results/fig-without-MA.dta"
		*rm "$github/results/fig-with-MA.dta"
		
		restore
		
****** Effect of TVA ***********************************************************

	* without Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg ln_`var' ln_invest_* ln_contracts_* _I* control_* tva_19*, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(tva_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
								
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(tva_*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			tva_1920 "1920" ///
			tva_1930 "1930" ///
			tva_1947 "1947" ///
			tva_1954 "1954" ///
			tva_1958 "1958" ///
			tva_1963 "1963" ///
			tva_1967 "1967" ///
			tva_1972 "1972" ///
			tva_1977 "1977" ///
			tva_1982 "1982" ///
			tva_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withoutMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-without-MA.dta", replace

		restore
		
********************************************************************************

	* with Market Access

		preserve

		est clear
		xi i.state*i.year
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			qui areg dln_`var' ln_invest_1* ln_contracts_1* control_* _I* tva_19* ln_marketaccess, cluster(state) a(fips)
			qui eststo byyear_`var'
			quietly esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain keep(tva_19*) ///
			eqlabels(none) collabels(none) mlabels(none) nomtitles b(a4) se(a4) nostar nonumbers nonotes noobs nopa not
			
			}

		*SAVE RESULTS
		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {
			esttab byyear_`var' using "$github/results/byyear_`var'.csv", replace wide plain eqlabels(none) collabels(none) ///
			mlabels(none) nomtitles keep(tva_19*) b(a4) se(a4) nostar nonumbers nonotes noobs nopa not varlabels( ///
			tva_1920 "1920" ///
			tva_1930 "1930" ///
			tva_1947 "1947" ///
			tva_1954 "1954" ///
			tva_1958 "1958" ///
			tva_1963 "1963" ///
			tva_1967 "1967" ///
			tva_1972 "1972" ///
			tva_1977 "1977" ///
			tva_1982 "1982" ///
			tva_1987 "1987") 
			}

		foreach var of varlist mfg_est mfg_emp mfg_wages mfg_val {	
			qui import delimited "$github/results/byyear_`var'.csv", clear
			rename v1 year
			rename v2 b
			rename v3 se
			set obs `=_N+ 1'
			qui g variable = "`var'"	
			qui g spec = "withMA"
			qui replace year = 1940 if year==.
			qui replace b = 0 if b ==.
			destring se, replace
			qui replace se = 0 if se ==.
			keeporder variable spec year b se
			sort year
			qui save "$github/results/byyear_`var'.dta", replace
			}

		clear
		local vars "mfg_est mfg_emp mfg_wages mfg_val"
		foreach var of local vars {
			append using "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.dta"
			rm "$github/results/byyear_`var'.csv"
			}
		qui save "$github/results/fig-with-MA.dta", replace

		restore
	
	*Make Figure
	
		preserve 
		
		clear all
		append using "$github/results/fig-without-MA.dta"
		append using "$github/results/fig-with-MA.dta"
		qui gen b_upper = b+1.96*se
		qui gen b_lower = b-1.96*se
		
		sort variable spec year
		replace variable ="Establishments"  if variable=="mfg_est"
		replace variable ="Employment"  if variable=="mfg_emp"
		replace variable ="Wage Bill"  if variable=="mfg_wages"
		replace variable ="Value-Added"  if variable=="mfg_val"
		
		foreach var in "Establishments" "Employment" "Wage Bill" "Value-Added" {
		
		qui sum b_upper if variable=="`var'"
		scalar temp_max = round(`r(max)'+.1,.1)
		qui sum b_lower if variable=="`var'"
		scalar temp_min = round(`r(min)'-.1,.1)
		scalar temp = max(abs(`=temp_max'),abs(`=temp_min'))
		
		qui gr tw 	(line b year 		if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(solid)) 	///
					(line b_upper year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	/// 
					(line b_lower year 	if variable=="`var'" & spec=="withoutMA", lcolor(black) lpattern(dash)) 	///
					(line b year 	if variable=="`var'" & spec=="withMA", lcolor(blue) lpattern(solid)) 			///
					, yline(`=-1*temp', lc(none)) yline(`=temp', lc(none)) legend(off) ///
					xtitle(" ") ytitle("Estimated Coefficients") xlabel(1920(20)1990, grid labsize(vlarge)) xmtick(1920(10)1990, grid) xscale(range(1920 1990)) ///
					ylabel(`=-1*temp'(`=temp/1')`=temp', format(%12.1f) labsize(vlarge)) ymtick(`=-1*temp'(`=temp/2')`=temp', grid gmin gmax) ///
					title("`var'", color(black)) graphregion(color(white)) saving("$github/results/`var'.gph",replace)
			}
		
		qui gr combine 	"$github/results/Establishments.gph" 	"$github/results/Employment.gph" ///
						"$github/results/Wage Bill.gph" 		"$github/results/Value-Added.gph" ///
						, graphregion(color(white)) rows(2) xsize(6)
		gr export "$github/results/TVA_area.pdf", as(pdf) replace
		rm "$github/results/Establishments.gph" 
		rm "$github/results/Employment.gph" 
		rm "$github/results/Wage Bill.gph" 
		rm "$github/results/Value-Added.gph"
		rm "$github/results/fig-without-MA.dta"
		rm "$github/results/fig-with-MA.dta"
		
		restore
