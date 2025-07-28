*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

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

//Update data for many countries

cap program drop pea_dataupdate
program pea_dataupdate, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [datatype(string) PPPyear(integer 2021) pppyear(string) UPDATE]
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	local datayear = real(substr("$S_DATE", -4, .))
	cap dlw, country(WLD) type(GMI) year(`datayear') mod(POV) files
	if _rc==0 clear
	else local datayear = `datayear'-1
	
	if "`pppyear'"=="" local pppyear 2021
	else local pppyear `=trim("`pppyear'")'
	if "`datatype'"~="" local datatype `=upper("`datatype'")'
	
	local dl 0
	if "`update'"=="update" local dl 1
	else {	
		if "`datatype'"=="MPM" local returnfile "`persdir'pea/WLD_GMI_MPM.dta"
		else if "`datatype'"=="PIP" local returnfile "`persdir'pea/PIP_all_country.dta"
		else if "`datatype'"=="GMI" local returnfile "`persdir'pea/GMI_extend_all_country.dta"
		else if "`datatype'"=="PEB" local returnfile "`persdir'pea/PEB_natpovrates.dta"
		else if "`datatype'"=="WDI" local returnfile "`persdir'pea/WDI_gdppc_lcuconst.dta"
		else if "`datatype'"=="POP" local returnfile "`persdir'pea/POP.dta"
		else if "`datatype'"=="SCORECARD" local returnfile "`persdir'pea/Scorecard_country.dta"
		else if "`datatype'"=="LIST" local returnfile "`persdir'pea/PIP_list_name.dta"
		else if "`datatype'"=="UNESCO" local returnfile "`persdir'pea/UNESCO.dta"
		else if "`datatype'"=="CLASS" local returnfile "`persdir'pea/CLASS.dta"
		else {
			di "`returnfile'"
			noi dis "`datatype' is not defined"
			exit 1
		}
		cap confirm file "`returnfile'"
		if _rc==0 {
			cap use "`returnfile'", clear	
			if _rc==0 {
				local dtadate : char _dta[version]			
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > 30 local dl 1
				else return local cachefile "`returnfile'"
			}
			else local dl 1
		}
		else {
			cap mkdir "`persdir'pea"
			local dl 1
		}
	}
	
	if `dl'==1 {
		//MPM DLW
		if "`datatype'"=="MPM" {
			cap dlw, country(WLD) type(GMI) year(`datayear') mod(MPM) files
			if _rc==0 {
				*keep if ppp==`pppyear'
				if _N>0 {
					char _dta[version] $S_DATE		
					save "`persdir'pea/WLD_GMI_MPM.dta", replace
				}
				else {
					noi dis as error "No data is available for the requested PPP year, `pppyear'."
					exit `=_rc'
				}
			}
			else {
				noi dis as error "Unable to update MPM data from DLW"
				exit `=_rc'
			}			
		}
		
		//UNESCO
		if "`datatype'"=="UNESCO" {
			noi dis "Place holder only"
			*char _dta[version] $S_DATE
			*use "`persdir'pea/UNESCO.dta", clear
			*qui dlw, country(Support) year(2005) type(GMDRAW) filename(UNESCO.dta) surveyid($surid) files clear nometa	
		}
		
		//CLASS
		if "`datatype'"=="CLASS" {
		* Get income groups and regions
			tempfile inc_group
			use "`persdir'pea/CLASS.dta", clear
			rename (year_data economy) (year country_name)
			keep code year incgroup_historical incgroup_current region_pip region region_SSA country_name
			foreach i in incgroup_current incgroup_historical {
				replace `i' = subinstr(`i', " ", "-", .)
				replace `i' = subinstr(`i', "income", "income countries", .)
			}
			save	`inc_group'
			* Add 2025 as year 
			keep if year == 2024
			replace year = 2025
			append using `inc_group'	
			char _dta[version] $S_DATE
			save "`persdir'pea/CLASS_incg_region.dta", replace
		}
		
		//LIST country name and regions
		if "`datatype'"=="LIST" {
			cap pip tables, table(countries) clear
			if _rc==0 {
				ren country_code code
				replace region_code = africa_split_code if africa_split_code~=""
				char _dta[version] $S_DATE
				save "`persdir'pea/PIP_list_name.dta", replace
			}
			else {
				noi dis "Unable to update country list from PIP"
				exit `=_rc'
			}
		}
		
		//PEB - national poverty
		* UPDATE TO GMI ONCE READY
		if "`datatype'"=="PEB" {
			cap import delimited "`persdir'pea/PEB_NatPovLine_SM25.csv",   clear
			if _rc==0 {
				ren (title rate comparability) (code natpovrate comparability_peb)
				keep code year natpovrate comparability
				keep if natpovrate ~= .
				char _dta[version] $S_DATE
				save "`persdir'pea/PEB_natpovrates.dta", replace
			}
			else {
				noi dis "Unable to access PEB_NatPovLine_SM25 file, please check that it is stored in personal sysdir folder."
				exit `=_rc'
			}			
		}
		
		//GDP per capita (LCU, constant)
		if "`datatype'"=="WDI" {
			cap wbopendata, indicator(ny.gdp.pcap.kn) clear long
			if _rc==0 {
				drop if region == "NA" | region == ""			// Drop aggregates
				keep countrycode year ny_gdp_pcap_kn
				ren (countrycode ny_gdp_pcap_kn) (code gdp_pc_lcu_const)
				keep if gdp_pc_lcu_const ~= .
				char _dta[version] $S_DATE
				save "`persdir'pea/WDI_gdppc_lcuconst.dta", replace
			}
			else {
				noi dis "Unable to access data from WDI (wbopendata), please check connection or try again later."
				exit `=_rc'
			}	
		}
		
		//Scorecard
		if "`datatype'"=="SCORECARD" {
			noi dis "Place holder only"
			*char _dta[version] $S_DATE
			*save "`persdir'pea/CSC_atrisk2021.dta", replace
		}
		
		//Climate exposure and vulnerability
		if "`datatype'"=="CLIMRISK" {
			noi dis "Place holder only"
			*char _dta[version] $S_DATE
			*save "`persdir'pea/CSC_atrisk2021.dta", replace
		}
		
		//Population data
		if "`datatype'"=="POP" {	
			tempfile pop
			cap pip tables, clear table(pop)
			if _rc==0 {
				rename value pop
				rename (country_code data_level) (code reporting_level)			
				keep code year pop reporting_level
				save `pop', replace
					
				* Get population by age shares (UN)
				use "`persdir'pea/popdata.dta", clear
				local myear = real(substr("$S_DATE", -4, .)) + 1
				drop yf1950-yf1976  yf`myear'-yf2100 ym1950-ym1976 ym`myear'-ym2100
				reshape long yf ym, i(countrycode cohort) j(year)
				gen x=1  if cohort=="P1519" |cohort=="P2024"|cohort=="P2529"|cohort=="P3034"| ///
							cohort=="P3539" |cohort=="P4044"|cohort=="P4549"|cohort=="P5054"| ///
							cohort=="P5559" |cohort=="P6064"
				bys countrycode year: egen totpop = sum(yf+ym)
				bys countrycode year x: egen adultpop = sum(yf+ym)
				drop if x == .
				gen share_1564 = adultpop / totpop
				keep countrycode year share_1564
				bys countrycode year: keep if _n == 1
				rename countrycode code 
					
				merge 1:m code year using `pop', keep(2 3) nogen
				gen pop_15642 = round(share_1564 * pop)
				keep code year reporting_level pop pop_1564
				char _dta[version] $S_DATE
				save "`persdir'pea/POP.dta", replace
			}
			else {
				noi dis "Unable to retrieve population from PIP"
				exit `=_rc'
			}			
		}
		
		//PIP
		if "`datatype'"=="PIP" {
			*local persdir : sysdir PERSONAL	
			*if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
			clear
			tempfile gdppc codereglist povdata povben povdata2017 povdata2021 pfr
			save `povben', replace emptyok
						
			//GDP https://data.worldbank.org/indicator/NY.GDP.PCAP.KD.
			pip tables, table(gdp) clear
			ren country_code code
			keep if data_level=="national"
			ren value gdppc
			char _dta[version] $S_DATE			
			save "`persdir'pea/PIP_all_GDP.dta", replace
			save `gdppc', replace
			
			/* Loop tends to break because of API, use local files for now.
			* UPDATE LATER
			//Country Pov data
			local nlines2017_ext 215 365 685 322 547 1027 430 730 1370 
			local nlines2021_ext 300 420 830 450 630 1245 600 840 1660	
			
			local j = 1
			foreach p in 2017 2021 {		
				foreach line of local nlines`p'_ext {
					tempfile povdata`p'`j'
					cap pip, country(all) year(all) ppp(`p') povline(`=`line'/100') clear
					if _rc==0 {
						ren headcount headcount`line'
						drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
						drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
						drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
						keep country_code country_name year headcount`line' pg gini survey_acronym welfare_type
						gen ppp = `p'
						save `povdata`p'`j'', replace
						local j = `j' + 1
						sleep 10000
					}
					else {
						noi dis "Unable to update data from PIP"
						exit `=_rc'
					}
				}
			}
			* Put together
			foreach p in 2017 2021 {
				local j = 1
				use `povdata`p'1', clear
				foreach line of local nlines`p'_ext {
					if !(`j' == 1) {
						merge 1:1 country_code year welfare_type using `povdata`p'`j'', ///
							nogen keepusing(headcount*)
					}
					local j = `j' + 1
				}
				save `povdata`p'', replace
			}
			use `povdata2017', clear
			append using `povdata2021'		
			*/
			
			*Call local files, update later!
			* Get correct survey
			use "`persdir'pea/Survey_price_framework.dta", clear
			keep code rep_year datatype display_cp survname
			rename (rep_year) (year)
			gen		welfare_type = 1 if datatype == "CONS" | datatype == "C" | datatype == "c"
			replace welfare_type = 2 if datatype == "INC" | datatype == "I" | datatype == "i"
			drop datatype
			save `pfr'
			
			use "`persdir'pea/pip2021.dta"
			append using "`persdir'pea/pip2017.dta"
			gen code = country_code
			rename survey_acronym survname
			keep if reporting_level=="national" | code == "ARG"
			merge m:1 code year welfare_type survname using `pfr', nogen
			drop if display_cp == 0 | display_cp == .
			rename (fgt0_*) (headcount*)
					
			for var headcount*: replace X = X*100		
			merge m:1 code year using `gdppc', keepus(gdppc)
			gen welfaretype= "CONS" if welfare_type==1
			replace welfaretype= "INC" if welfare_type==2
			*rename welfare_type welfaretype
			drop if _merge==2
			drop _merge
			char _dta[version] $S_DATE			
			save "`persdir'pea/PIP_all_country.dta", replace
			
			//PIP lineup data
			tempfile povlineup	
			local nlines2017 215 365 685 
			local nlines2021 300 420 830 
			
			foreach p in 2017 2021 {		
				local j = 1
				foreach line of local nlines`p' {
					tempfile povdata`p'`j'
					cap pip, country(all) year(all) ppp(`p') povline(`=`line'/100') clear fillgap
					if _rc==0 {
						ren headcount headcount`line'
						drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
						drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
						drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
						keep country_code year  headcount`line' pg   welfare_type pop 
						gen ppp = `p'
						save `povdata`p'`j'', replace
						local j = `j' + 1
					}
					else {
						noi dis "Unable to update data from PIP"
						exit `=_rc'
					}
				}
			}
			
			* Put together
			foreach p in 2017 2021 {
				local j = 1
				use `povdata`p'1', clear
				foreach line of local nlines`p' {
					if !(`j' == 1) {
						merge 1:1 country_code year welfare_type using `povdata`p'`j'', ///
							nogen keepusing(headcount*)
					}
					local j = `j' + 1
				}
				save `povdata`p'', replace
			}
			use `povdata2017', clear
			append using `povdata2021'			
			
			gen code = country_code
			gen welfaretype= "CONS" if welfare_type==1
			replace welfaretype= "INC" if welfare_type==2
			for var headcount*: replace X = X*100			
			char _dta[version] $S_DATE
			save "`persdir'pea/PIP_all_countrylineup.dta", replace
			
			//Income group average by historical class
			cap pea_dataupdate, datatype(CLASS)												// If income groups and regions not prepared
			cap pea_dataupdate, datatype(POP)												// If population not prepared
							
			* Get poverty rates and merge (not nowcast)
			foreach p in 2017 2021 {		
				local j = 1
				foreach line of local nlines`p' {
					cap pip, fillgaps ppp(`p') povline(`=`line'/100') clear 
					if _rc==0 {
						keep country_code poverty_line headcount pg year reporting_level
						ren country_code code
						merge 1:1 code reporting_level year using "`persdir'pea/POP.dta", nogen
						merge m:1 code year using "`persdir'pea/CLASS_incg_region.dta", nogen
						keep if year > 1989 & year~=.					
						keep if reporting_level=="national" | code == "ARG"
						/* 2025 not in pop data
						cap assert pop != .
						if _rc~=0 {
							noi dis "There is missing pop data from PIP"
							exit `=_rc'
						}
						*/
						* Calculate regional poverty to fill in missing numbers
						groupfunction [aw=pop], mean(headcount pg) by(region_pip year) merge
						replace headcount = wmean_headcount if headcount == . 	
						replace pg = wmean_pg if pg == . 	
						drop wmean_*	 				
						drop if inlist(code,"ARG") & reporting_level=="national"
						
						* Merge in gdp pc
						merge m:1 code year using "`persdir'pea/PIP_all_GDP.dta", keepus(gdppc)
						
						* Produce income group level poverty rates for each country					
						groupfunction [aw=pop], mean(headcount pg gdppc) by(incgroup_historical year) merge
						drop if inlist(code,"ARG") & reporting_level=="rural"					 // Keep only one observation for Argentina
						sort code year poverty_line
						ren wmean_headcount headcount`line'
						drop pg gdppc
						ren wmean_pg pg
						ren wmean_gdppc gdppc
						keep code year incgroup_historical headcount`line' pg gdppc
						gen ppp = `p'
						save `povdata`p'`j'', replace
						local j = `j' + 1
					}
					else {
						noi dis "Unable to update regional data from PIP"
						exit `=_rc'
					}
				}
			} //nline
			
			* Put together
			foreach p in 2017 2021 {
				local j = 1
				use `povdata`p'1', clear
				foreach line of local nlines`p' {
					if !(`j' == 1) {
						merge 1:1 code year using `povdata`p'`j'', ///
							nogen keepusing(incgroup_historical year headcount* pg ppp)
					}
					local j = `j' + 1
				}
				save `povdata`p'', replace
			}
			use `povdata2017', clear
			append using `povdata2021'
			
			for var headcount*: replace X = X*100
			cap drop if headcount215==.
			char _dta[version] $S_DATE
			save "`persdir'pea/PIP_incgroup_estimate.dta", replace
			
			//regional
			* Prepare gdp per capita
			tempfile regional regdata reggdp

			use `gdppc', clear
			rename data_level reporting_level
			merge 1:1 code reporting_level year using "`persdir'pea/POP.dta", nogen keep(1 3)
			merge 1:1 code year using "`persdir'pea/CLASS_incg_region.dta", nogen keepusing(region_pip region region_SSA)
			replace region_pip = region_SSA if region_SSA ~= ""
			groupfunction [aw=pop], mean(gdppc) by(region_pip year)
			rename region_pip region_code
			save `reggdp'
			
			* Get poverty rates and merge
			foreach p in 2017 2021 {		
				local j = 1
				foreach line of local nlines`p' {
					cap pip wb, region(all)  ppp(`p') povline(`=`line'/100') clear
					if _rc==0 {
						ren headcount headcount`line'
						keep region_name region_code year headcount`line' pg
						gen ppp = `p'
						save `povdata`p'`j'', replace
						local j = `j' + 1
						sleep 5000
					}
					else {
						noi dis "Unable to update regional data from PIP"
						exit `=_rc'
					}
				}
			}

			* Put together
			foreach p in 2017 2021 {
				local j = 1
				use `povdata`p'1', clear
				foreach line of local nlines`p' {
					if !(`j' == 1) {
						merge 1:1 region_code year using `povdata`p'`j'', ///
							nogen keepusing(region_name year headcount* pg ppp)
					}
					local j = `j' + 1
				}
				save `povdata`p'', replace
			}
			
			use `povdata2017', clear
			append using `povdata2021'
			merge m:1 region_code year using `reggdp', nogen keepus(gdppc)			
			for var headcount*: replace X = X*100
			char _dta[version] $S_DATE
			save "`persdir'pea/PIP_regional_estimate.dta", replace
		}
		
		//GMI
		if "`datatype'"=="GMI" {
			foreach dat in CLASS POP MPM {
				cap pea_dataupdate, datatype(`dat')												// If any file not prepared
				if _rc~=0 {
					noi dis "Unable to update the data for `dat'. Either DLW or PIP services are unavailable at the moment"
					error `=_rc'
				}
			}	
			*local persdir : sysdir PERSONAL	
			*if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
			tempfile pop2 pfr ine lab risk
			* Get population national level
			use "`persdir'pea/POP.dta", clear			
			keep if reporting_level == "national"
			drop reporting_level
			save `pop2'
			* First prepare scorecard data
			use "`persdir'pea/CSC_atrisk2021.dta", clear
			keep code year atrisk pop_pip_vul
			save `risk'
			* Get correct survey
			use "`persdir'pea/Survey_price_framework.dta", clear
			keep code rep_year datatype display_cp survname
			rename (datatype rep_year) (welftype year)
			replace welftype = "CONS" if welftype == "C" | welftype == "c"
			replace welftype = "INC" if welftype == "I" | welftype == "i"
			save `pfr', replace

			* Get labor data 
			* UPDATE ONCE GMI DATA IS READY
			use "`persdir'pea/GMI_extended_SM25_ind_labor.dta", clear	
			*cleaning
			replace level = "Urban" if byvar=="_urban_" & level=="1"| level=="1.Urban"
			replace level = "Rural" if byvar=="_urban_" & level=="0"| level=="0.Rural"
			replace level = "Male" if byvar=="_male_" & level=="1"| level=="1. Male"|level=="1.Male" | level == "male"
			replace level = "Female" if byvar=="_male_" & level=="0"| level=="0.Female" | level == "female"
			replace level = "MISSING" if byvar=="_male_" & level=="."  	

			split surveyid, parse("_") gen(survey) 
			rename survey3 survname
			bys code year surveyid mod: egen youth_wrk = min(cond(level=="Youth (15-24)",_working_ind,.))
			bys code year surveyid mod: egen women_wrk = min(cond(level=="Female",_working_ind,.))
			keep if level == "Total"
			drop if count < 30 													// Drop when too few observations
			keep code year survname _working_ind _empstat_ind1 _industry_ind1 _industry_nonagr_ind poor215_wrk nonpoor215_wrk poor365_wrk nonpoor365_wrk poor685_wrk nonpoor685_wrk poor300_wrk nonpoor300_wrk poor420_wrk nonpoor420_wrk poor830_wrk nonpoor830_wrk _misslfs_ind _empstat_ind_m _industry_ind_m women_wrk youth_wrk
			for var *_wrk *_ind* : replace X = X*100
			
			merge m:1 code year survname using `pfr', keep(1 3) nogen
			drop survname
			drop if display_cp == 0												// Only keep main survey for each country
			save `lab'
			* Get GMI data - Inequality and Poverty
			local datayear = real(substr("$S_DATE", -4, .))
			cap dlw, country(WLD) type(GMI) year(`datayear') mod(INE) files
			if _rc==0 {
				drop if strpos(filename, "BIN") > 0 & survname == "EU-SILC"			// Drop EU-SILC binned data
				drop if filename == "MYS_2007_HIS_V01_M_V01_A_GMD_HIST.DTA" 		// Drop not used surveys
				drop if filename == "LCA_2015_SLCHBS_V01_M_V01_A_GMD_BIN.DTA" 		// Drop not used surveys
				drop if filename == "MEX_1989_ENIGH_V01_M_V01_A_GMD_HIST.DTA" 		// Drop not used surveys
				keep code year welftype survname gini pg ppp
				save `ine'
			}
			else {
				noi dis "Unable to access GMI data from DLW"
				exit `=_rc'
			}
			
			cap dlw, country(WLD) type(GMI) year(`datayear') mod(POV) files
			if _rc==0 {
				drop if strpos(filename, "BIN") > 0 & survname == "EU-SILC"			// Drop EU-SILC binned data
				drop if filename == "MYS_2007_HIS_V01_M_V01_A_GMD_HIST.DTA" 		// Drop not used surveys
				drop if filename == "LCA_2015_SLCHBS_V01_M_V01_A_GMD_BIN.DTA" 		// Drop not used surveys
				drop if filename == "MEX_1989_ENIGH_V01_M_V01_A_GMD_HIST.DTA" 		// Drop not used surveys
				keep code year welftype survname fgt* ppp
			}
			else {
				noi dis "Unable to access GMI data from DLW"
				exit `=_rc'
			}
			// Get region, income group and population
			merge 1:1 code year welftype survname ppp using `ine', nogen
			merge m:1 code year welftype survname using `pfr', nogen
			drop if display_cp == 0												// Only keep main survey for each country
			merge m:1 code year using "`persdir'pea/CLASS_incg_region.dta", keep(1 3) nogen 
			merge m:1 code year using `pop2', keep(1 3) nogen
			* Labor
			merge m:1 code year using `lab', keep(1 3) nogen
			* MPM
			merge 1:1 code year welftype survname ppp using "`persdir'pea/WLD_GMI_MPM.dta", keepusing(mdpoor_i1) nogen
			replace mdpoor_i1 = mdpoor_i1 * 100
			* Scorecard
			merge m:1 code using `risk', nogen
			
			char _dta[version] $S_DATE
			save "`persdir'pea/GMI_extend_all_country.dta", replace
		}
	} //dl
end
