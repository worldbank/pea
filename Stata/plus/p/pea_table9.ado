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

//Table 9 _ Scorecard Vision Indicators

cap program drop pea_table9
program pea_table9, rclass
	version 18.0
	syntax [if] [in], [Country(string) Year(varname numeric) CORE excel(string) save(string) PPPyear(integer 2021)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	local csc: dir "`persdir'pea/Scorecard_Summary_Vision/" files "*.xlsx"
	local indnum : word count `csc'

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
		local ymax = r(max)
	}
	
	// Check if folder exists
	local cwd `"`c(pwd)'"'														// store current wd
	quietly capture cd "`persdir'pea/Scorecard_Summary_Vision/"
	if _rc~=0 {
		noi di in red "Scorecard_Summary_Vision folder does not exist."
		exit `=_rc'
	}
	quietly cd `"`cwd'"'
	
	// Get country name
	use "`persdir'pea/PIP_list_name.dta", clear
	keep if code=="`country'"
	if _N==0 {
		noi dis in y "Warning: wrong country code"
		error 1
	}
	else {
		local ctryname `=country_name[1]'
	}
	
	// Get region name
	use "`persdir'pea/CLASS.dta", clear
	gen region_code = "SSF" if region == "Sub-Saharan Africa"
	replace region_code = "SAS" if region == "South Asia"
	replace region_code = "MEA" if region == "Middle East & North Africa"
	replace region_code = "ECS" if region == "Europe & Central Asia"
	replace region_code = "LCN" if region == "Latin America & Caribbean"
	replace region_code = "EAS" if region == "East Asia & Pacific"
	replace region_code = "NAC" if region == "North America"
	keep if code == "`country'"
	if _N==0 {
		noi dis in y "Warning: wrong country code"
		error 1
	}
	else {
		local region_code `=region_code[1]'
		local region_name `=region[1]'
	}	
	
	// Get list of all CSC files
	forval num = 1 / `indnum' {
		tempfile f`num'
	}
	
	// Import each file and extract country-level indicator
	local f = 1
	foreach file in `csc' {
	  	cap import excel "`persdir'pea/Scorecard_Summary_Vision/`file'", firstrow clear
		if _rc==0 {
			qui destring Time_Period, gen(year_data)
			gen ind = .
			foreach i in `country' `region_code' {
				qui su year_data if Geography_Code == "`i'", d	// Year for aggregate data can be different than year for country data (for FIES)
				local lyear_`i' = r(max)
				// Keep latest survey year or latest indicator year, for both region and country
				replace ind = 1 if (`ymax' > `lyear_`i'') & Time_Period == "`lyear_`i''" & Geography_Code == "`i'"
				replace ind = 1 if (`ymax' <= `lyear_`i'') & Time_Period == "`ymax'" & Geography_Code == "`i'"			
			}
			keep if ind == 1
			keep Indicator_Code Indicator_Name Geography_Code year_data Value
			save `f`f''
			local f = `f' + 1
		}
		else {
			noi dis as error "Unable to load the CSC xlsx data file `file'"
			error `=_rc'
		}
	} 
	
	clear
	forval num = 1 / `=`f'-1' {
		append using  `f`num''
	}
	
	// Display names
	gen name = "`ctryname'"  if Geography_Code == "`country'" 
	replace name = "`region_name'"  if Geography_Code == "`region_code'"
	replace Indicator_Name = subinstr(Indicator_Name," (globally)", "",.)
	replace Indicator_Name = subinstr(Indicator_Name," global", "",.)
	replace Indicator_Name = strupper(substr(Indicator_Name,1,1)) + substr(Indicator_Name,2,length(Indicator_Name))
	
	// inequality indicator as index for high inequality (not GINI)
	replace Value = Value > 40 if Indicator_Code=="SI_DST_INEQ" & Geography_Code == "`country'"
	replace Indicator_Name = "Number of economies with high inequality (=1 if Gini>40)" if Indicator_Code=="SI_DST_INEQ"

	// Add time period in square brackets - note that it can be different between region and country, hence two values
	qui levelsof Indicator_Code, local(cat)
	foreach j of local cat {
		foreach i in `country' `region_code' {
			qui su year_data if Geography_Code == "`i'" & Indicator_Code == "`j'", d
			local `j'_`i' = r(max)
		}
		if ``j'_`region_code'' ~= ``j'_`country''	{	
			replace Indicator_Name = Indicator_Name  + " [``j'_`country'', "  + "``j'_`region_code'']"  if Indicator_Code == "`j'" 
		}
		if ``j'_`region_code'' == ``j'_`country'' {
			replace Indicator_Name = Indicator_Name  + " [``j'_`region_code'']"  if Indicator_Code == "`j'" & Geography_Code == "`region_code'"			// in case one is missing do for both
			replace Indicator_Name = Indicator_Name  + " [``j'_`region_code'']"  if Indicator_Code == "`j'" & Geography_Code == "`country'"			
		}
	}
	// Order of columns
	gen order_c = 2
	replace order_c = 1 if Geography_Code == "`country'" 
	drop Geography_Code
	
	// Order of rows
	gen order = .
	replace order = 1 if Indicator_Code == "SI_POV_DDAY"
	replace order = 2 if Indicator_Code == "SI_POV_UMIC"
	replace order = 3 if Indicator_Code == "SI_POV_PROS"
	replace order = 4 if Indicator_Code == "SI_DST_INEQ"
	replace order = 5 if Indicator_Code == "EN_ATM_GHGT_GT_CE"
	replace order = 6 if Indicator_Code == "EN_CLM_VULN"
	replace order = 7 if Indicator_Code == "ER_LND_HEAL"							
	replace order = 8 if Indicator_Code == "SN_ITK_MSFI_ZS"
	replace order = 9 if Indicator_Code == "SH_H2O_BASW_ZS"
	replace order = 10 if Indicator_Code == "SH_STA_BASS_ZS"
	replace order = 11 if Indicator_Code == "SH_STA_HYGN_ZS"
	
	// Sheet name
	local tabname Table9
	// Export
	collect clear
	qui collect: table (order Indicator_Name) (order_c name) ,statistic(mean Value) nototal nformat(%20.0f) missing
	collect style header order Indicator_Name order_c name, title(hide)
	collect style header order order_c, level(hide)
	collect title `"Table 9. Scorecard Vision Indicators"'
	collect notes 1: `"Source: World Bank calculations using data from the World Bank Group Scorecard, retrieved from https://scorecard.worldbank.org/en/scorecard/home."'
	collect notes 2: `"Notes: Poverty rates and the prosperity gap are reported using `pppyear' purchasing power parity dollars. When available, indicators are presented for the year for which the latest survey data for the PEA is available. Otherwise, the latest available year for each indicator is used. Numbers in square brackets indicate year of data for the country (left) or the region aggregate (right). The high inequality indicator takes a value of 1 if the country GINI is above 40, and 0 otherwise. On the regional level, it depicts the number of economies with high inequality."' 
	collect notes 3: `"The Number of hectares of key ecosystems is not available on the regional level. Basic water refers to water from an improved source within collection time of 30 minutes for a roundtrip including queuing. Basic sanitation refers to the use of improved facilities which are not shared with other households. Basic hygiene refers to the availability of a handwashing facility with soap and water at home (WHO/UNICEF Joint Monitoring Programme)."' 
	_pea_tbtformat
	_pea_tbt_export, filename(Table9) tbtname(Table9) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
	
end	