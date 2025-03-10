*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>
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

//pea setup all things

cap program drop pea_setup
program pea_setup, rclass
	version 18.0
		
	//Install the packages used in pea
	local packages apoverty ineqdeco svylorenz fastgini glcurve alorenz povdeco fs groupfunction drdecomp adecomp pip skdecomp schemepack geoplot palettes colrspace grc1leg2 treemap graphfunctions carryforward
	//check way for moremata
	foreach package of local packages  {
 		cap which `package'
 		if (_rc) {
			cap ssc install `package', replace
			if _rc~=0 {
				noi dis "Unable to download the `package' from SSC, maybe check the internet"
				error `=_rc'
			}
		}
	}
	//https://github.com/vavalomi/stata_tools/tree/master/sedecomposition
	
	//Setup the folder
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	cap mkdir "`persdir'pea"

	//Check and download the necessary data
	local mustfiles CLASS.dta UNESCO.dta CSC_atrisk2021.dta 
	foreach file of local mustfiles {
		cap confirm file "`persdir'pea/`file'"
		if _rc~=0 {
			noi dis "The data file `file' is not there in the folder `persdir'pea/, reinstall the pea package to get the basic data files"
			error `=_rc'
		}
	}
		
	local mustfiles EN_ATM_GHGT_GT_CE.xlsx EN_CLM_VULN.xlsx ER_LND_HEAL.xlsx SH_H2O_STA_HYGN_TO.xlsx SI_DST_INEQ.xlsx SI_POV_DDAY_TO.xlsx SI_POV_PROS.xlsx SN_ITK_MSFI_ZS.xlsx
	foreach file of local mustfiles {
		cap confirm file "`persdir'pea//Scorecard_Summary_Vision//`file'"
		if _rc~=0 {
			noi dis "The scorecard data file `file' is not there in the folder `persdir'pea/Scorecard_Summary_Vision, reinstall the pea package to get the basic data files"
			error `=_rc'
		}
	}
	
	//Update data from PIP and MPM first time
	local dtypes MPM LIST PIP
	foreach dtype of local dtypes {
		cap pea_dataupdate, datatype(`dtype')
		if _rc~=0 {
			noi dis "Unable to update the data from `dtype'. Either DLW or PIP services are unavailable at the moment"
			error `=_rc'
		}
	}
	mata: pea_setup = 1	
end