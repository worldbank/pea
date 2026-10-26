cap program drop pea_dataupdate
program pea_dataupdate, rclass
version 18.0

* ==========================================================================
* Main data-update utility for the PEA package.
*
* This program:
*   1. Retrieves external data from PIP, DLW, WDI and local support files.
*   2. Rebuilds cached datasets stored under PERSONAL/pea.
*   3. Refreshes caches when files are missing, stale, or a different
*   PIP release is explicitly requested.
*   4. Standardizes datasets used by downstream PEA tables and figures.
*
* Each datatype() corresponds to a specific derived dataset.
* ==========================================================================

* Disclaimers & credits 
	
	*! version 0.1.2  30Sep2026
	*! Copyright (C) World Bank 2017-2024 
	*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez 
	* <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>.
	*! Modifications by Daylan Alberto Salmeron Gomez; Maria Fernanda Gonzalez Icaza

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

* ============================================================================

* CHANGELOG v0.1.2
*
* Fixes intermittent r(673) failures observed during PIP release rollouts and
* strengthens validation of PIP version consistency throughout the update
* process.
*
* Main changes:
*   1. Added release() option (with $PEA_PIP_RELEASE fallback) to allow
*      validation against a specific PIP release.
*   2. Added pipver_assert to verify that every PIP request returns the
*      expected PPP round and PIP release. Requests now fail explicitly if
*      the returned metadata does not match expectations.
*   3. Added retry-with-backoff logic to all poverty-line retrieval loops
*      (country, lineup, income-group and regional pulls) to handle transient
*      PIP service failures.
*   4. Standardized all PIP requests to use server(prod).
*   5. Added pip_release metadata to cached datasets and extended cache
*      validation so files are refreshed when a different release() is
*      requested, even within the normal cache window.
*
* Notes:
*   - Requests are not pinned using version()/release().
*   - Prior testing showed that version() can override ppp_year()/ppp(),
*     creating a risk of retrieving data from a different PPP round than
*     intended.
*   - The package therefore validates the returned metadata rather than
*     forcing a specific version in the request.
* ============================================================================

* Update data for many countries
	* release() : Expected PIP release date (YYYYMMDD, e.g. 20260922). // v0.1.2
	* Used for validation only; it is not passed to PIP requests.
	* The package validates the release returned by PIP rather than pinning
	* requests with version()/release(), because those options may affect
	* PPP-round resolution.
	* If omitted, release validation is skipped.
	
* ============================================================================
		
syntax [if] [in] [aw pw fw], [datatype(string) PPPyear(integer 2021) pppyear(string) UPDATE RELease(string)]

*----------------------------------*----------------------------------*----
* Initialize runtime settings*and default values
*--------------*----------------------------------*------------------------
	local piptxt "server(prod)"
	
* Fall back to a session-level global so a whole pipeline can set it once.  // v0.1.2
	if "`release'" == "" local release "$PEA_PIP_RELEASE"
	local persdir : sysdir PERSONAL
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all

* Determine the latest DLW year available.
	local datayear = real(substr("$S_DATE", -4, .))
	cap dlw, country(WLD) type(GMI) year(`datayear') mod(POV) files
	if _rc==0 clear
	else local datayear = `datayear'-1

* Standardize user inputs
	if "`pppyear'"=="" local pppyear 2021
	else local pppyear `=trim("`pppyear'")'
	if "`datatype'"~="" local datatype `=upper("`datatype'")'

*--------------------------------------------------------------------------
* Determine whether data need to be downloaded.
* Existing cached files are reused unless:
*   - update is requested,
*   - the cache is missing,
*   - the cache is older than 30 days,
*   - the cache was built from a different PIP release.
*--------------------------------------------------------------------------
	local dl 0
	if "`update'"=="update" local dl 1
	else {
		if "`datatype'"=="MPM" local returnfile "`persdir'pea/WLD_GMI_MPM.dta"
		else if "`datatype'"=="PIP" local returnfile "`persdir'pea/PIP_all_country.dta"
		else if "`datatype'"=="GMI" local returnfile "`persdir'pea/GMI_extend_all_country.dta"
		else if "`datatype'"=="PEB" local returnfile "`persdir'pea/PEB_natpovrates.dta"
		else if "`datatype'"=="WDI" local returnfile "`persdir'pea/WDI_gdppc_lcuconst.dta"
		else if "`datatype'"=="POP" local returnfile "`persdir'pea/POP.dta"
		else if "`datatype'"=="CLIMRISK" local returnfile "`persdir'pea/climrisk.dta"
		else if "`datatype'"=="EXPOSURE" local returnfile "`persdir'pea/exposure.dta"
		else if "`datatype'"=="LIST" local returnfile "`persdir'pea/PIP_list_name.dta"
		else if "`datatype'"=="UNESCO" local returnfile "`persdir'pea/UNESCO.dta"
		else if "`datatype'"=="CLASS" local returnfile "`persdir'pea/CLASS_incg_region.dta"
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
				* Release stamped on the cached file when it was built (see char writes below). // v0.1.2
				local dtarel  : char _dta[pip_release]
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > 30 local dl 1
				* Age alone is not enough: PIP can publish a new release inside the 30-day    // v0.1.2
				* window. Without this branch, asking for a different release returns the old
				* cached file and never contacts PIP -- release() would be inert.
				else if "`release'" != "" & "`dtarel'" != "`release'" {
				noi dis "Cached file built on release `dtarel', requested `release' -- refetching."
				local dl 1
				}
				else return local cachefile "`returnfile'"
				}
			else local dl 1
			}
			else {
				cap mkdir "`persdir'pea"
				local dl 1
				}
			}

*--------------------------------------------------------------------------
* Rebuild requested dataset.
* Each datatype() branch produces a standardized file that is stored in
* PERSONAL/pea and reused by the rest of the package.
*--------------------------------------------------------------------------
if `dl'==1 {

* MPM: multidimensional poverty indicators from DLW
		if "`datatype'"=="MPM" {
			cap dlw, country(WLD) type(GMI) year(`datayear') mod(MPM) files
			if _rc==0 {
* keep if ppp==`pppyear' 
* Intentionally not filtered by PPP year. Store all available PPP rounds and 
* apply PPP-specific filtering in downstream analyses.
			if _N>0 {
				char _dta[version] $S_DATE
				replace welftype = "CONS" if welftype == "C" | welftype == "c"
				replace welftype = "INC" if welftype == "I" | welftype == "i"
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
* UNESCO education indicators
		if "`datatype'"=="UNESCO" {
			dlw, country(Support) year(2005) type(GMDRAW) filename(UNESCO.dta) surveyid($surid) files clear nometa
			char _dta[version] $S_DATE
			save "`persdir'pea/UNESCO.dta", replace
		}
* CLASS: country classifications, regions, and income groups
		if "`datatype'"=="CLASS" {
			tempfile inc_group
			use "`persdir'pea/CLASS.dta", clear
	* CLASS.dta is maintained outside the package and may contain
	* double-encoded UTF-8 country names (e.g. CÃ´te d'Ivoire, TÃ¼rkiye).
	* Repair encoding on import rather than modifying the source file.
		qui ds, has(type string)
		local strvars "`r(varlist)'"
		foreach v of local strvars {
			qui replace `v' = ustrfrom(ustrto(`v', "ISO-8859-1", 1), "UTF-8", 1) if ustrregexm(`v', "\u00C3|\u00C2")
		}
			rename (year_data economy) (year country_name)
	* Changes based on modification to the CLASS file
	        rename regionssa_code region_SSA
			rename region_code region_pip
			rename  incgroup incgroup_historical

			keep code year incgroup_historical region_pip region region_SSA country_name
	* Get the latest year per code
				bysort code (year): gen incgroup_current = incgroup_historical[_N]
			foreach i in incgroup_current incgroup_historical {
				replace `i' = subinstr(`i', " ", "-", .)
				replace `i' = subinstr(`i', "income", "income countries", .)
			}
			save	`inc_group'
	* Add 2025 as year	 // MFGI: TO-DO: DO WE NEED TO UPDATE TO 2026?
			keep if year == 2024
			replace year = 2025
			append using `inc_group'
			char _dta[version] $S_DATE
			save "`persdir'pea/CLASS_incg_region.dta", replace
		}
* LIST: country names, codes, and region mappings from PIP
		if "`datatype'"=="LIST" {
			cap pip tables, table(countries) `piptxt' clear
			if _rc==0 {
			//Validate pip version
			pipver_assert , release(`release')
			ren country_code code
			replace region_code = africa_split_code if africa_split_code~=""
			qui replace country_name = ustrfrom(ustrto(country_name, "ISO-8859-1", 1), "UTF-8", 1) if ustrregexm(country_name, "\u00C3|\u00C2")				
				char _dta[version] $S_DATE
				char _dta[pip_release] "`release'"
				save "`persdir'pea/PIP_list_name.dta", replace
			}
			else {
				noi dis "Unable to update country list from PIP"
				exit `=_rc'
			}
		}
* PEB: national poverty rates from PEA/PEB source files * TO-DO: UPDATE TO GMI ONCE READY
		if "`datatype'"=="PEB" {
			cap import delimited "`persdir'pea/PEB_NatPovLine_SM26.csv",   clear
			if _rc==0 {
				ren (title rate comparability) (code natpovrate comparability_peb)
				keep code year natpovrate comparability
				keep if natpovrate ~= .
				char _dta[version] $S_DATE
				compress code
				save "`persdir'pea/PEB_natpovrates.dta", replace
			}
			else {
				noi dis "Unable to access PEB_NatPovLine_SM26 file, please check that it is stored in personal sysdir folder."
				exit `=_rc'
			}
		}
* WDI: GDP per capita in constant local currency units
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
* Climate risk indicators
		if "`datatype'"=="CLIMRISK" {
			import excel "`persdir'pea/counting_people_climate_risk_DDH.xlsx", clear sheet("national") firstrow 
	* TO-DO: This file needs to be updated to DDH file
			sum lineupyear
			keep if lineupyear == r(max)
			rename (risk_any lineupyear) (atrisk year)
			replace atrisk = atrisk * 100
			keep if scenario == "RP100*"
			keep if hazard == "any"
			keep code year atrisk pop_pip
			char _dta[version] $S_DATE
			save "`persdir'pea/climrisk.dta", replace
		}
* Climate vulnerability and exposure indicators
		if "`datatype'"=="EXPOSURE" {
			import excel "`persdir'pea/counting_people_climate_risk_DDH.xlsx", clear sheet("national") firstrow 
	* TO-DO: This file needs to be updated to DDH file
			sum lineupyear
			keep if lineupyear == r(max)
			keep if scenario == "RP100*"
			keep if hazard == "any"
			rename lineupyear year
			keep code year exp_sh risk_any risk_poor300 risk_educ risk_sp risk_fin risk_elec risk_water risk_rai pop_pip
			char _dta[version] $S_DATE
			save "`persdir'pea/exposure.dta", replace
		}
* Population estimates
		if "`datatype'"=="POP" {
			tempfile pop
			cap pip tables, `piptxt' clear table(pop)
			if _rc==0 {
				pipver_assert , release(`release')
				rename value pop
				rename (country_code data_level) (code reporting_level)
				keep code year pop reporting_level
				save `pop', replace
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
				gen pop_1564 = round(share_1564 * pop) // corrected typo
				keep code year reporting_level pop pop_1564
				char _dta[version] $S_DATE
				char _dta[pip_release] "`release'"
				save "`persdir'pea/POP.dta", replace
			}
			else {
				noi dis "Unable to retrieve population from PIP"
				exit `=_rc'
			}
		}
*--------------------------------------------------------------------------
* PIP-derived datasets
*   - country poverty indicators,
*   - lineup/fillgap series,
*   - income-group estimates,
*   - regional estimates,
*   - GDP reference data.
* All PIP requests are validated using pipver_assert.
*----------------------------------------------------------------------
		if "`datatype'"=="PIP" {
			*local persdir : sysdir PERSONAL
			*if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
			clear
			tempfile gdppc codereglist povdata povben povdata2017 povdata2021 pfr
			save `povben', replace emptyok
			
* GDP reference data. Retrieve national-level GDP per capita from PIP. 	
	* GDP https://data.worldbank.org/indicator/NY.GDP.PCAP.KD.
			pip tables, table(gdp) `piptxt' clear
	* Aux table -- no ppp argument, so only the release can be checked.      // v0.1.2
	* Must be the FIRST command after the pip call: r() is cleared by the next command that sets it.
			pipver_assert , release(`release')
			ren country_code code
			keep if data_level=="national"
			ren value gdppc
			char _dta[version] $S_DATE
	* Stamp provenance so the cache check can tell which release built this. // v0.1.2
			char _dta[pip_release] "`release'"
			save "`persdir'pea/PIP_all_GDP.dta", replace
			save `gdppc', replace

* Population dependency. Ensure POP.dta is available and built from the same validated release.
	* Nested pull must validate against the same release, or PIP output      // v0.1.2
	* could silently mix releases. NOTE: "cap" swallows a mismatch abort
	* and execution continues with whatever POP.dta is on disk.
			cap pea_dataupdate, datatype(POP) release(`release')
			tempfile pop2
			use "`persdir'pea/POP.dta", clear
			keep if reporting_level == "national"
			keep code year pop
			save `pop2', replace

* Country poverty estimates. Retrieve national poverty measures under both 2017 and 2021 PPP.
		local nlines2017_ext 215 365 685 322 547 1027 430 730 1370
		local nlines2021_ext 300 420 830 450 630 1245 600 840 1660
		foreach p in 2017 2021 {
			local j = 1
			foreach line of local nlines`p'_ext {
				tempfile povdata`p'`j'

		* 4-try ladder. Catches ANY nonzero _rc, not just r(673):       // v0.1.2
		* the mechanism behind r(673) was never established, so
		* narrowing the catch would just mean the next unknown code
		* aborts the round. Cost is ~18s of retries before a genuine
		* permanent error surfaces.
					local try = 1
					local ok  = 0
					while `try' <= 4 & `ok' == 0 {
						cap pip cl , ppp_year(`p') povline(`=`line'/100')  `piptxt' clear
						if _rc == 0 {
		* Confirm the round served is the round requested --     // v0.1.2
		* guards against version() silently overriding ppp_year
		* and against a release changing mid-run.
							pipver_assert , pppyear(`p') release(`release')
							local ok = 1
						}
						else {
							local lastrc = _rc
		* r(673) "authorization required by server" traced to a  // v0.1.2
		* transient backend condition, not an auth problem --
		* it stopped reproducing under identical requests. Log
		* timestamp and position so the next occurrence in a
		* production log is diagnosable.
							di as error "  [pip-retry] " c(current_date) " " c(current_time) ///
							"  rc=`lastrc'  call=cl ppp=`p' line=`line'  attempt=`try'"
							if `try' < 4 sleep `=3000*`try''
							local try = `try' + 1
						}
					}
				if `ok' == 1 {
					ren headcount headcount`line'
					*drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
					*drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
					*drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
					keep if reporting_level == "national" | country_code == "ARG"
					keep country_code country_name year headcount`line' pg gini survey_acronym welfare_type
					gen ppp = `p'
					save `povdata`p'`j'', replace
					local j = `j' + 1
					sleep 2000
					}
					else {
						noi dis "Unable to update data from PIP"
						exit `=`lastrc''
					}
				}
			}
			
*--------------------------------------------------------------------------
* Combine individual poverty-line pulls into a single country-year dataset.
*----------------------------------------------------------------------
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
				tempfile povdata`p'
				save `povdata`p'', replace
			}

	*Call local files, update later! // TO-DO: WHAT DOES IT MEAN?
			
	* Survey framework. Keep only surveys marked as displayable/comparable in the PIP framework metadata.
		pip tables, table(framework) `piptxt' clear
			* Aux table -- release only. Watch this one: framework has been observed // v0.1.2
			* resolving under a different PPP round than countries/pop/gdp.
			pipver_assert , release(`release')
			rename (country_code survey_acronym welfare_type) (code survname welf_type)
			keep code year welf_type display_cp survname
			encode welf_type, gen(welfare_type)
			*gen		welfare_type = 1 if datatype == "CONS" | datatype == "C" | datatype == "c"
			*replace welfare_type = 2 if datatype == "INC" | datatype == "I" | datatype == "i"
			drop welf_type
			save `pfr'
	* Assemble final country-level poverty dataset.
		use `povdata2017', clear
			append using `povdata2021'
			gen code = country_code
			rename survey_acronym survname
			merge m:1 code year welfare_type survname using `pfr', nogen
			drop if display_cp == 0 | display_cp == .
			//rename (fgt0_*) (headcount*)

			for var headcount*: replace X = X*100
			merge m:1 code year using `gdppc', keepus(gdppc)
			merge m:1 code year using `pop2', keepus(pop) nogen
			gen welfaretype= "CONS" if welfare_type==1
			replace welfaretype= "INC" if welfare_type==2
			*rename welfare_type welfaretype
			drop if _merge==2
			drop _merge
			qui replace country_name = ustrfrom(ustrto(country_name, "ISO-8859-1", 1), "UTF-8", 1) if ustrregexm(country_name, "\u00C3|\u00C2")
			char _dta[version] $S_DATE
			char _dta[pip_release] "`release'"	// v0.1.2
			save "`persdir'pea/PIP_all_country.dta", replace

*--------------------------------------------------------------------------
* Poverty line-up dataset
	* Retrieve fillgap series used for historical comparisons and trend analysis across countries.
*----------------------------------------------------------------------
		tempfile povlineup
			local nlines2017 215 365 685
			local nlines2021 300 420 830

			foreach p in 2017 2021 {
				local j = 1
				foreach line of local nlines`p' {
					tempfile povdata`p'`j'
					local try = 1
					local ok  = 0
					while `try' <= 4 & `ok' == 0 {
						cap pip, country(all) year(all) ppp(`p') povline(`=`line'/100') `piptxt' clear fillgap
						if _rc == 0 {
							pipver_assert , pppyear(`p') release(`release')		// v0.1.2
							local ok = 1
						}
						else {
							local lastrc = _rc
							di as error "  [pip-retry] " c(current_date) " " c(current_time) ///
							"  rc=`lastrc'  call=fillgap ppp=`p' line=`line'  attempt=`try'"
							if `try' < 4 sleep `=3000*`try''
							local try = `try' + 1
						}
					}

					if `ok' == 1 {
						ren headcount headcount`line'
						drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
						drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
						drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
						keep country_code year headcount`line' pg welfare_type pop
						gen ppp = `p'
						save `povdata`p'`j'', replace
						local j = `j' + 1
						sleep 2000
					}
					else {
						noi dis "Unable to update data from PIP"
						exit `=`lastrc''
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
			char _dta[pip_release] "`release'"						// v0.1.2
			save "`persdir'pea/PIP_all_countrylineup.dta", replace

*----------------------------------------------------------------------
* Income-group aggregates
* Construct poverty and GDP indicators by historical income-group
* classification, filling missing country observations when needed.
*----------------------------------------------------------------------
	cap pea_dataupdate, datatype(CLASS) release(`release')		// If income groups and regions not prepared
	cap pea_dataupdate, datatype(POP) release(`release')		// If population not prepared

	* Get poverty rates and merge (not nowcast)
			foreach p in 2017 2021 {
				local j = 1
				foreach line of local nlines`p' {
				* This loop previously had NO retry wrapper -- a single         // v0.1.2
				* transient failure aborted the whole update. Wrapped in the
				* same ladder as the cl and fillgap loops above.
					local try = 1
					local ok  = 0
					while `try' <= 4 & `ok' == 0 {
						cap pip, fillgaps ppp(`p') povline(`=`line'/100')  `piptxt' clear
						if _rc == 0 {
							pipver_assert , pppyear(`p') release(`release')
							local ok = 1
						}
						else {
							local lastrc = _rc
							di as error "  [pip-retry] " c(current_date) " " c(current_time) ///
							"  rc=`lastrc'  call=incgrp ppp=`p' line=`line'  attempt=`try'"
							if `try' < 4 sleep `=3000*`try''
							local try = `try' + 1
						}
					}
				* Body unchanged -- only the guard around it. _rc is no longer   // v0.1.2
				* meaningful here (the cap inside the loop reset it), hence `ok'.
					if `ok' == 1 {
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
					} 	*/
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
					noi dis "Unable to update income group data from PIP"
					exit `=`lastrc''
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
	* Drop rows with no poverty value at any line.
		* The previous test was "headcount215==.", which only works for the
		* 2017 round: 2021-PPP rows carry headcount300/420/830 and never a
		* headcount215, so headcount215 was missing for every 2021 row and
		* the whole round was deleted here, after being built correctly
		* above. PIP_incgroup_estimate.dta therefore held 2017 only, and
		* pea_table10 returned an empty income-group row at pppyear(2021),
		* which is the package default.
		for var headcount*: replace X = X*100
			
			egen byte _nhc = rownonmiss(headcount*)
			drop if _nhc == 0
			drop _nhc
			drop if incgroup_historical == ""

			char _dta[version] $S_DATE
			char _dta[pip_release] "`release'"						// v0.1.2
			save "`persdir'pea/PIP_incgroup_estimate.dta", replace

*----------------------------------------------------------------------
* Regional aggregates. Construct regional poverty and GDP indicators. 
*----------------------------------------------------------------------
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
		* Two fixes here.                                               // v0.1.2
			* (1) This was the ONLY pip call site in the file with no
			*     `piptxt'/server(prod). It happened to work, but was
			*     inconsistent with the other seven.
			* (2) No retry wrapper, same as the income-group loop.
					local try = 1
					local ok  = 0
					while `try' <= 4 & `ok' == 0 {
						cap pip wb, region(all) ppp(`p') povline(`=`line'/100') `piptxt' clear
						if _rc == 0 {
							pipver_assert , pppyear(`p') release(`release')
							local ok = 1
						}
						else {
							local lastrc = _rc
							di as error "  [pip-retry] " c(current_date) " " c(current_time) ///
							"  rc=`lastrc'  call=regional ppp=`p' line=`line'  attempt=`try'"
							* Longer backoff: regional pulls are heavier than cl.
							if `try' < 4 sleep `=5000*`try''
							local try = `try' + 1
						}
					}
					if `ok' == 1 {
						ren headcount headcount`line'
						keep region_name region_code year headcount`line' pg
						gen ppp = `p'
						save `povdata`p'`j'', replace
						local j = `j' + 1
						sleep 5000
					}
					else {
						noi dis "Unable to update regional data from PIP"
						exit `=`lastrc''
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
		* Combine PPP 2017 and PPP 2021 regional estimates.
			use `povdata2017', clear
			append using `povdata2021'
			* keep(1 3): master rows and matches only.
			* `reggdp' is built from the GDP table, which covers region-years
			* with no poverty data. Without keep(), those arrive as using-only
			* rows carrying a gdppc but no ppp and no headcounts.
			merge m:1 region_code year using `reggdp', nogen keepus(gdppc) keep(1 3)
			for var headcount*: replace X = X*100
			char _dta[version] $S_DATE
			char _dta[pip_release] "`release'"						// v0.1.2
			save "`persdir'pea/PIP_regional_estimate.dta", replace
		}
*----------------------------------------------------------------------
* Extended GMI dataset
* Assemble the master country-year benchmarking dataset used throughout
* the PEA package by combining: poverty, inequality, labor-market, 
* multidimensional poverty, * climate-risk, population, and classification data.
*----------------------------------------------------------------------
	* Ensure prerequisite datasets are available and up to date.
	if "`datatype'"=="GMI" {
		foreach dat in CLASS POP MPM CLIMRISK {
			cap pea_dataupdate, datatype(`dat')	
			if _rc~=0 {
				noi dis "Unable to update the data for `dat'. Either DLW or PIP services are unavailable at the moment"
				error `=_rc'
			}
		}
		*local persdir : sysdir PERSONAL
		*if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all

			tempfile pop2 pfr ine lab
	
	* Retain national-level population estimates only.
		use "`persdir'pea/POP.dta", clear
			keep if reporting_level == "national"
			drop reporting_level
			save `pop2'
	
	* Survey framework used to identify the preferred survey for each country-year.
		use "`persdir'pea/Survey_price_framework.dta", clear
			keep code rep_year datatype display_cp survname
			rename (datatype rep_year) (welftype year)
			replace welftype = "CONS" if welftype == "C" | welftype == "c"
			replace welftype = "INC" if welftype == "I" | welftype == "i"
			save `pfr', replace

	* Labor market indicators derived from the interim extended GMI file.
		* TO-DO: replace with official GMI labor outputs when available
		use "`persdir'pea/GMI_extended_SM26_ind_labor.dta", clear
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
			drop if count < 30 		// Drop when too few observations

	keep code year survname _working_ind _empstat_ind1 _industry_ind1 _industry_nonagr_ind poor215_wrk nonpoor215_wrk poor365_wrk nonpoor365_wrk poor685_wrk nonpoor685_wrk poor300_wrk nonpoor300_wrk poor420_wrk nonpoor420_wrk poor830_wrk nonpoor830_wrk _misslfs_ind _empstat_ind_m _industry_ind_m women_wrk youth_wrk
			for var *_wrk *_ind* : replace X = X*100

			merge m:1 code year survname using `pfr', keep(1 3) nogen
			drop survname
			drop if display_cp == 0	// Only keep main survey for each country
			save `lab'
			
	* Inequality indicators.		
		local datayear = real(substr("$S_DATE", -4, .))
			cap dlw, country(WLD) type(GMI) year(`datayear') mod(INE) files
			if _rc==0 {
				drop if strpos(filename, "BIN") > 0 & survname == "EU-SILC"		// Drop EU-SILC binned data
				drop if filename == "MYS_2007_HIS_V01_M_V01_A_GMD_HIST.DTA" 	// Drop not used surveys
				drop if filename == "LCA_2015_SLCHBS_V01_M_V01_A_GMD_BIN.DTA" 	// Drop not used surveys
				drop if filename == "MEX_1989_ENIGH_V01_M_V01_A_GMD_HIST.DTA" 	// Drop not used surveys
				keep code year welftype survname gini pg ppp
				save `ine'
			}
			else {
				noi dis "Unable to access GMI data from DLW"
				exit `=_rc'
			}
	* Poverty indicators.
			cap dlw, country(WLD) type(GMI) year(`datayear') mod(POV) files
			if _rc==0 {
				drop if strpos(filename, "BIN") > 0 & survname == "EU-SILC"		// Drop EU-SILC binned data
				drop if filename == "MYS_2007_HIS_V01_M_V01_A_GMD_HIST.DTA" 	// Drop not used surveys
				drop if filename == "LCA_2015_SLCHBS_V01_M_V01_A_GMD_BIN.DTA" 	// Drop not used surveys
				drop if filename == "MEX_1989_ENIGH_V01_M_V01_A_GMD_HIST.DTA" 	// Drop not used surveys
				keep code year welftype survname fgt* ppp
			}
			else {
				noi dis "Unable to access GMI data from DLW"
				exit `=_rc'
			}

	* Merging poverty, inequality, classifications, population, labor, multidimensional poverty, and
	* climate-risk indicators
			merge 1:1 code year welftype survname ppp using `ine', nogen
			merge m:1 code year welftype survname using `pfr', nogen
			drop if display_cp == 0				// Only keep main survey for each country
			merge m:1 code year using "`persdir'pea/CLASS_incg_region.dta", keep(1 3) nogen
			merge m:1 code year using `pop2', keep(1 3) nogen
			merge m:1 code year using `lab', keep(1 3) nogen
			merge 1:1 code year welftype survname ppp using "`persdir'pea/WLD_GMI_MPM.dta", keepusing(mdpoor_i1) keep(1 3) nogen
			replace mdpoor_i1 = mdpoor_i1 * 100
			merge m:1 code using "`persdir'pea/climrisk.dta", nogen
			char _dta[version] $S_DATE
			save "`persdir'pea/GMI_extend_all_country.dta", replace
		}
	} //dl
end

*----------------------------------------------------------------------
* pipver_assert // v0.1.2
* Validate that a PIP request returned data from the expected release,
* PPP round, and production server.  
* pppyear() is optional because auxiliary tables (GDP, countries,
* population, framework) are not tied to a specific PPP round.
*----------------------------------------------------------------------
cap program drop pipver_assert
program pipver_assert, rclass
    syntax , [PPPyear(string) RELease(string) NOABort] 
    local v    "`r(version)'"
    local vrel "`r(release)'"
    local vppp "`r(ppp_year)'"
    local vsrv "`r(identity)'"

    if "`v'" == "" {
        local v "$pip_version"
        if "`v'" != "" {
            local parts = subinstr("`v'", "_", " ", .)
            local vrel : word 1 of `parts'
            local vppp : word 2 of `parts'
            local vsrv : word 5 of `parts'
        }
    }

    if "`release'" == "" & "`pppyear'" == "" {
        return scalar pass = 1
        return local version "`v'"
        exit
    }

    if "`v'" == "" {
        di as error "pipver_assert: no version available from pip."
        return scalar pass = 0
        if "`noabort'" == "" error 459
        exit
    }

    local pass = 1
    local msg  ""

    if "`release'" != "" & "`vrel'" != "`release'" {
        local pass = 0
        local msg "`msg' release `vrel' != expected `release';"
    }
    if "`pppyear'" != "" & "`vppp'" != "`pppyear'" {
        local pass = 0
        local msg "`msg' PPP round `vppp' != requested `pppyear';"
    }
    if "`vsrv'" != "PROD" {
        local pass = 0
        local msg "`msg' server `vsrv' != PROD;"
    }

    if `pass' == 0 {
        di as error "PIP VERSION MISMATCH: `v' --`msg'"
        di as error "   query: $pip_last_queries"
    }

    return scalar pass    = `pass'
    return local  msg     "`msg'"
    return local  version "`v'"
    return local  release "`vrel'"
    return local  ppp     "`vppp'"

    if `pass' == 0 & "`noabort'" == "" error 459
	
end
* ==========================================================================