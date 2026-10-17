cap program drop pea_setup
program pea_setup, rclass
version 18.0
*==============================================================================
* pea_setup
*
* Initialize the PEA environment by:
*   - verifying required Stata packages,
*   - checking installation folders,
*   - validating required support files, and
*   - preparing external datasets used by the package.
*
* This routine should be run once after installation or whenever package
* dependencies need to be refreshed.
*==============================================================================
* Disclaimers & credits 
	
	*! version 0.1.1  12Sep2014
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
*==============================================================================

*----------------------------------------------------------------------
* Verify required user-written packages and install missing dependencies from SSC.
*----------------------------------------------------------------------
local packages ineqdeco svylorenz groupfunction drdecomp pip skdecomp schemepack geoplot palettes grc1leg2 colrspace treemap carryforward splitvallabels nicelabels niceloglabels wbopendata alorenz
	
	* Missing packages are installed automatically from SSC.
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
	* Additional dependency not distributed through SSC:
	* https://github.com/vavalomi/stata_tools/tree/master/sedecomposition
	
*----------------------------------------------------------------------
* Create the PEA working directory under the Stata PERSONAL folder.
*----------------------------------------------------------------------
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	cap mkdir "`persdir'pea"

*----------------------------------------------------------------------
* Verify that required support files were installed correctly.
* These files are distributed with the package and are expected to be
* available locally before any benchmarking or scorecard routines run.
*----------------------------------------------------------------------
	local mustfiles CLASS.dta UNESCO.dta counting_people_climate_risk_DDH.xlsx 
	foreach file of local mustfiles {
		cap confirm file "`persdir'pea/`file'"
		if _rc~=0 {
			noi dis "The data file `file' is not there in the folder `persdir'pea/, reinstall the pea package to get the basic data files"
			error `=_rc'
		}
	}
		
* Verify required scorecard reference files.
	local mustfiles EN_ATM_GHGT_GT_CE.xlsx EN_CLM_VULN.xlsx ER_LND_HEAL.xlsx SH_H2O_STA_HYGN_TO.xlsx SI_DST_INEQ.xlsx SI_POV_DDAY_TO.xlsx SI_POV_PROS.xlsx SN_ITK_MSFI_ZS.xlsx
	foreach file of local mustfiles {
		cap confirm file "`persdir'pea//Scorecard_Summary_Vision//`file'"
		if _rc~=0 {
			noi dis "The scorecard data file `file' is not there in the folder `persdir'pea/Scorecard_Summary_Vision, reinstall the pea package to get the basic data files"
			error `=_rc'
		}
	}

*----------------------------------------------------------------------
* Optional initialization of external benchmarking datasets.
* Disabled by default because it requires access to external services
* (PIP, DLW, WDI) and may take several minutes to complete.
*----------------------------------------------------------------------
	//Update data from PIP and MPM first time
	local dtypes MPM LIST PIP GMI PEB WDI	
  /* *local dtypes MPM LIST PIP
	foreach dtype of local dtypes {
		cap pea_dataupdate, datatype(`dtype')
		if _rc~=0 {
			noi dis "Unable to update the data from `dtype'. Either DLW, PIP or WDI services are unavailable at the moment"
			error `=_rc'
		}
	} 	*/
	
* Flag successful completion of PEA setup.
	mata: pea_setup = 1	

end
*==============================================================================