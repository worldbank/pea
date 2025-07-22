*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>
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

cap program drop pea
program pea, rclass
	version 18.0
	local version : di "version " string(_caller()) ":"
	set prefix pea
	gettoken subcmd 0 : 0, parse(" :,=[]()+-")
	local l = strlen("`subcmd'")
	
	qui	tempfile __datax
	qui save `__datax', replace emptyok
	
	noi _pea_logo
	//run pea setup first
	cap mata: mata describe pea_setup
	if _rc~=0 pea_setup
	
	use `__datax', clear
	
	//setup like the below	
	if ("`subcmd'"=="core") { //upload relelated tasks
		pea_core `0'
	}	
	else if ("`subcmd'"=="dataupdate") { 
		pea_dataupdate `0'
    }
	else if ("`subcmd'"=="tables") { 
		pea_tables `0'
    }
	else if ("`subcmd'"=="slides") { 
		pea_slides `0'
    }
	else if ("`subcmd'"=="tableC1") {
		pea_tableC1 `0'		
    }
	else if ("`subcmd'"=="figureC1") {
		pea_figureC1 `0'		
    }
	else if ("`subcmd'"=="table1") {
		pea_table1 `0'		
    }
	else if ("`subcmd'"=="table2") {
		pea_table2 `0'		
    }
	else if ("`subcmd'"=="tableA2") {
		pea_tableA2 `0'		
    }
	else if ("`subcmd'"=="table3") {
		pea_table3 `0'		
    }
	else if ("`subcmd'"=="table4") {
		pea_table4 `0'		
    }
	else if ("`subcmd'"=="table5") {
		pea_table5 `0'		
    }
	else if ("`subcmd'"=="table6") {
		pea_table6 `0'		
    }
	else if ("`subcmd'"=="table7") {
		pea_table7 `0'		
    }
	else if ("`subcmd'"=="table8") {
		pea_table8 `0'		
    }
	else if ("`subcmd'"=="table9") {
		pea_table9 `0'		
    }
	else if ("`subcmd'"=="table10") {
		pea_table10 `0'		
    }
	else if ("`subcmd'"=="table11") {
		pea_table11 `0'		
    }
	else if ("`subcmd'"=="table12") {
		pea_table12 `0'		
    }
	else if ("`subcmd'"=="table13") {
		pea_table13 `0'		
    }
	else if ("`subcmd'"=="table14") {
		pea_table14 `0'		
    }
	/*
	else if ("`subcmd'"=="table14b") {
		pea_table14b `0'		
    }
	*/
	else if ("`subcmd'"=="table15") {
		pea_table15 `0'		
    }
	else if ("`subcmd'"=="figures") {
		pea_figures `0'		
    }
	else if ("`subcmd'"=="figure1") {
		pea_figure1 `0'		
    }
	else if ("`subcmd'"=="figure2") {
		pea_figure2 `0'		
    }
	else if ("`subcmd'"=="figure3") {
		pea_figure3 `0'		
    }
	else if ("`subcmd'"=="figure4a") {
		pea_figure4a `0'		
    }
	else if ("`subcmd'"=="figure4b") {
		pea_figure4b `0'		
    }
	else if ("`subcmd'"=="figure5") {
		pea_figure5 `0'		
    }
	else if ("`subcmd'"=="figure6") {
		pea_figure6 `0'		
    }
	else if ("`subcmd'"=="figure7a") {
		pea_figure7a `0'		
    }
	else if ("`subcmd'"=="figure7b") {
		pea_figure7b `0'		
    }
	else if ("`subcmd'"=="figure8") {
		pea_figure8 `0'		
    }
	else if ("`subcmd'"=="figure9a") {
		pea_figure9a `0'		
    }
	else if ("`subcmd'"=="figure9b") {
		pea_figure9b `0'		
    }
	else if ("`subcmd'"=="figure9c") {
		pea_figure9c `0'		
    }	
	else if ("`subcmd'"=="figure10") {
		pea_figure10 `0'		
    }
	else if ("`subcmd'"=="figure10a") {
		pea_figure10a `0'		
    }
	else if ("`subcmd'"=="figure10b") {
		pea_figure10b `0'		
    }
	else if ("`subcmd'"=="figure10c") {
		pea_figure10c `0'		
    }	
	else if ("`subcmd'"=="figure10d") {
		pea_figure10d `0'		
    }	
	else if ("`subcmd'"=="figure11") {
		pea_figure11 `0'		
    }
	else if ("`subcmd'"=="figure12") {
		pea_figure12 `0'		
    }
	else if ("`subcmd'"=="figure13") {
		pea_figure13 `0'		
    }
	else if ("`subcmd'"=="figure14") {
		pea_figure14 `0'		
    }
	else if ("`subcmd'"=="figure15") {
		pea_figure15 `0'		
    }
	else if ("`subcmd'"=="figure16") {
		pea_figure16 `0'		
    }
	else if ("`subcmd'"=="figure17") {
		pea_figure17 `0'		
    }
	else { //none of the above
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
			/*NOTREACHED*/
		}
		`version' pea_`subcmd' `0'
	}
	return add
end
