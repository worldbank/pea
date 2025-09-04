*! version 0.1.1  07Nov2024
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

//Table 16 Social Protection

cap program drop pea_table16
program pea_table16, rclass
	version 18.0
	syntax [if] [in], [Country(string) Year(varname numeric) benchmark(string) CORE excel(string) save(string)]	

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//load data if defined
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}

	// Tempfile if save option not specified
	if "`save'"=="" tempfile saveout
	
	//house cleaning
	_pea_export_path, excel("`excel'")
		
	qui {
		//Identify latest year used for the table
		su `year',d
		local maxy = r(max)
	}
	//Check if data exists
	cap confirm file "`persdir'pea/ASPIRE performance indicators.dta"
	if _rc~=0 {
		noi dis as error "Unable to find 'ASPIRE performance indicators.dta' file."
		error `=_rc'	
	}
	
	//Call data
	use "`persdir'pea/ASPIRE performance indicators.dta", 
	qui count if Country_Code == "`country'"
	if r(N) == 0 {
		noi dis as error "Country `country' does not have ASPIRE data, Table 16 not produced."
		error 1	
	}
	destring Year, gen(year) force
	
	//Save PEA country for later
	gen count = _n
	qui sum count if Country_Code == "`country'"
	local country_name_c `=Countries[r(min)]'	
	
	//Keep relevant countries and years
	gen keep = 1 if Country_Code == "`country'"
	foreach b of local benchmark  {
		replace keep = 1 if Country_Code == "`b'"
	}
	keep if keep == 1
	keep if (year>=`=`maxy'-3' & year<=`=`maxy'+3') | Country_Code == "`country'"
	count
	if r(N) > 0 {
		gen diff = abs(year - `maxy')
		bys Country_Code: egen mindiff = min(diff)
		keep if diff == mindiff | Country_Code == "`country'"
		bys Country_Code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
		keep if year == maxyear | Country_Code == "`country'"
	}
	//Keep relevant indicators
	drop keep
	gen keep = .
	*Coverage
	replace keep = 1 if inlist(Indicator_Code,"per_allsp.cov_pop_tot", "per_allsp.cov_pop_urb", "per_allsp.cov_pop_rur", "per_allsp.cov_q1_tot", "per_allsp.cov_q2_tot", "per_allsp.cov_q3_tot", "per_allsp.cov_q4_tot", "per_allsp.cov_q5_tot")
	*Adequacy
	replace keep = 1 if inlist(Indicator_Code,"per_allsp.adq_pop_tot", "per_allsp.adq_pop_urb", "per_allsp.adq_pop_rur", "per_allsp.adq_q1_tot", "per_allsp.adq_q2_tot", "per_allsp.adq_q3_tot", "per_allsp.adq_q4_tot", "per_allsp.adq_q5_tot")
	keep if keep == 1
	gen indicator = .
	replace indicator = 1 if inlist(Indicator_Code, "per_allsp.cov_pop_tot", "per_allsp.adq_pop_tot")
	replace indicator = 2 if inlist(Indicator_Code, "per_allsp.cov_pop_urb", "per_allsp.adq_pop_urb")
	replace indicator = 3 if inlist(Indicator_Code, "per_allsp.cov_pop_rur", "per_allsp.adq_pop_rur")
	replace indicator = 4 if inlist(Indicator_Code, "per_allsp.cov_q1_tot", "per_allsp.adq_q1_tot")
	replace indicator = 5 if inlist(Indicator_Code, "per_allsp.cov_q2_tot", "per_allsp.adq_q2_tot")
	replace indicator = 6 if inlist(Indicator_Code, "per_allsp.cov_q3_tot", "per_allsp.adq_q3_tot")
	replace indicator = 7 if inlist(Indicator_Code, "per_allsp.cov_q4_tot", "per_allsp.adq_q4_tot")
	replace indicator = 8 if inlist(Indicator_Code, "per_allsp.cov_q5_tot", "per_allsp.adq_q5_tot")
	label define indicator_lbl 1 "Total" 2 "Urban" 3 "Rural" 4 "Q1" 5 "Q2" 6 "Q3" 7 "Q4" 8 "Q5"
	label values indicator indicator_lbl
	gen header = .
	replace header = 1 if Sub_Topic3 == "Coverage"
	replace header = 2 if Sub_Topic3 == "Adequacy of benefits"
	label define header_lbl 1 "Coverage of Social Protection" 2 "Adequacy of benefits of Social Protection"
	label values header header_lbl	
	//Country order
	qui levelsof Countries, local(gval) 
	gen group_order = 1
	local i = 2
	foreach val of local gval {
		// Skip if PEA country
		if "`val'" ~= "`country_name_c'" { 
			replace group_order = `i' if Countries == "`val'"
			label define group_lbl `i' "`val'", add
			local i = `i' + 1
		}
	}
	label define group_lbl 1 "`country_name_c'", add
	label values group_order group_lbl
	keep Countries year header val indicator group_order
	
	// Sheet name
	local tabname Table16
	// Export
	collect clear
	collect: table (header indicator) (group_order year), statistic(mean val) nototal nformat(%20.1f) missing
	collect style header header indicator group_order year, title(hide)
	collect title `"Table 16. Social Protection Coverage and Adequacy"'
	collect notes 1: `"Source: World Bank calculations using data from the ASPIRE database, retrieved from https://www.worldbank.org/en/data/datatopics/aspire."'
	collect notes 2: `"Notes: Table shows coverage and benefit adequacy of all Social Protection and Labor programs. For more information, please refer to the ASPIRE methodology. Quintiles represent five equal groups of households ranked by welfare level, from lowest (Q1) to highest (Q5)."' 
	_pea_tbtformat
	_pea_tbt_export, filename(Table16) tbtname(Table16) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
	
end	