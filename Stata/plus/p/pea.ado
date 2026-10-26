*================================================================
* Main entry point for the PEA package
*
* This program:
*   1. Parses the user-supplied subcommand
*   2. Displays package/version information
*   3. Initializes the PEA environment if needed
*   4. Restores the user's active dataset
*   5. Dispatches execution to a pea_* subcommand
*
* Most analytical work is implemented in the individual pea_*
* modules. This file primarily acts as a command dispatcher.
*================================================================
	
* Disclaimers & credits 

	*! version 0.1.2  29Sep2026
	*! Copyright (C) World Bank 2017-2024 
	*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez 
	*<ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>.
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

*================================================================
cap program drop pea
program pea, rclass
version 18.0

 * Preserve caller version when invoking subcommands.
	local version : di "version " string(_caller()) ":"
	
* Parse command line and identify requested subcommand
	set prefix pea
	gettoken subcmd 0 : 0, parse(" :,=[]()+-")
	//local l = strlen("`subcmd'") // NEVER USED TO BE DELETED
	noi _pea_logo

*---------------------------------------------------------------
* Package version information
*---------------------------------------------------------------
* IMPORTANT: Update these values whenever a new package release is pushed.
* The release date shown here is what users see when loading PEA.
	local pea_pushed "September 29, 2026"
	local pea_cycle  "SM26"
	local dot = ustrunescape("\u00B7")
	local msg "Package updated `pea_pushed' `dot' `pea_cycle' data cycle"
	
* Use ustrlen(), not strlen(), because the separator character
    * is multibyte. strlen() would count bytes rather than characters.
	local n = ustrlen("`msg'")
	local rule : di _dup(`n') "*"
	noi di ""
	noi di as result "  `rule'"
	noi di as result "  {bf:`msg'}"
	noi di as result "  `rule'"
	noi di ""
	
*---------------------------------------------------------------
* Session cleanup and initialization
*---------------------------------------------------------------
	cap putexcel clear
	
	cap mata: mata describe pea_setup
	if _rc~=0 {
		preserve
		pea_setup
		restore
	}
	
*-----------------------------------------------------------
* Fallback mechanism ONLY
* This allows package extensions to be added without
* modifying the central dispatcher.
*-----------------------------------------------------------
		if ("`subcmd'"=="") {
			di as smcl as err "syntax error"
			di as smcl as err "{p 4 4 2}"
			di as smcl as err "{bf:pea} must be followed by a subcommand."
			di as smcl as err "You might type {bf:pea table1}, or {bf:pea figure1}, or {bf:pea tables}, etc."			
			di as smcl as err "{p_end}"
			exit 198
		}
		capture which pea_`subcmd'
		if (_rc) { 
			if (_rc==1) exit 1
			di as smcl as err "unrecognized subcommand:  {bf:pea `subcmd'}"
			exit 199
		}
		`version' pea_`subcmd' `0'
	return add
end

*================================================================