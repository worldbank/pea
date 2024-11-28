

cap program drop pea_figure7
program pea_figure7, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) Year(varname numeric) FGTVARS LINESORTED NONOTES age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) setting(string) scheme(string) palette(string) excel(string) save(string)]
	
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married  
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
	}
	
	//house cleaning
	if "`excel'"=="" {
		tempfile xlsxout 
		local excelout `xlsxout'		
		local path "`xlsxout'"		
		local lastslash = strrpos("`path'", "\") 				
		local dirpath = substr("`path'", 1, `lastslash')		
	}
	else {
		cap confirm file "`excel'"
		if _rc~=0 {
			noi dis as error "Unable to confirm the file in excel()"
			error `=_rc'	
		}
		else local excelout "`excel'"
	}
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `hhhead' `edu' {
			su `var'
			local miss = r(max)
			replace `var' = `=`miss'+10' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+10' "Missing", add
		}
	}
	
	qui {
		//order the lines
		if "`linesorted'"=="" {
			if "`ppppovlines'"~="" {
				_pea_pline_order, povlines(`ppppovlines')
				local ppppovlines `=r(sorted_line)'
				foreach var of local ppppovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
			
			if "`natpovlines'"~="" {
				_pea_pline_order, povlines(`natpovlines')
				local natpovlines `=r(sorted_line)'
				foreach var of local natpovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
		}
		else {
			foreach var of varlist `natpovlines' `ppppovlines' {
				local lbl`var' : variable label `var'
			}
		}
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year' `male' `edu' `age' `urban'"'
		markout `touse' `flist' 
	} //qui
			
	// Generate poverty measures
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		gen double _pop = `wvar'
	}
	
	
	
	// Shorten value labels 
    local lbl: value label `edu'
	if "`lbl'" == "educat4" {
		label define educat4_m 1 "No education" 2 "Primary" 3 "Secondary" 4 "Tertiary"
		label values `edu' educat4_m
	}	
	
	// Variable definitions
	if "`age'"!="" {
		su `age',d
		if r(N)>0 {
			gen agecatind = 1 if `age'>=0 & `age'<=14
			replace agecatind = 2 if `age'>=15 & `age'<=65
			replace agecatind = 3 if `age'>=66 & `age'<=.
			la def agecatind 1 "Age 0-14" 2 "Age 15-65" 3 "Age 66+"
			la val agecatind agecatind
		}
	}
	
	gen _total = 1
	la def _total 1 "Total"
	la val _total _total	
	tempfile data1 data2
	// Only last year
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	save `data1', replace
	clear
	save `data2', replace emptyok	

	// Prepare poverty rates by groups
	use `data1', clear	
	local byind `male' `edu' agecatind `urban' _total

	local i = 1
	foreach var of local byind {
		use `data1', clear
		qui levelsof `var', local(lclist)
		local label1 : value label `var'
		 
		foreach lvl of local lclist {
			use `data1', clear
			keep if `var'==`lvl'
			local lbllvl : label `label1' `lvl'			
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt0*) rawsum(_pop) by(`year')
			gen _group = `i'			
			la def _group `i' "`lbllvl'", add
			la val _group _group
			tempfile labelx`i'
			label save _group using `labelx`i''
			la drop _group
			local i = `i' + 1			
			append using `data2'
			save `data2', replace
		}
	}
	qui forv j=1(1)`=`i'-1' {
		do `labelx`j''
	}
	qui for var _fgt0*: replace X = X*100
	la val _group _group
	
	//Prepare Notes
	local notes "Source: World Bank calculations using survey data accessed through the GMD."
	local notes `"`notes'" "Note: Figure presents poverty rates within each group."'
	if "`nonotes'" ~= "" {
		local notes = ""
	}
	else if "`nonotes'" == "" {
		local notes `notes'

	local vars_graph
	local vars_label
	local o 1
	if "`natwelfare'"~="" {
		foreach var in `natpovlines' {
			local vars_graph "`vars_graph' _fgt0_`natwelfare'_`var'"
			local vars_label `"`vars_label' `o' "`lbl`var''" "'
			local o = `o' + 1
		}
	}
	if "`pppwelfare'"~="" {
		foreach var in `ppppovlines' {
			local vars_graph "`vars_graph' _fgt0_`pppwelfare'_`var'"
			local vars_label `"`vars_label' `o' "`lbl`var''" "'
			local o = `o' + 1
		}
	}
		
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure7.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	
	tempfile graph
	putexcel set "`excelout2'", `act'
	graph dot `vars_graph', 				///
			over(_group) marker(1, msymbol(O)) marker(2, msymbol(D))  marker(3, msymbol(S))  marker(4, msymbol(T))  	///
			legend(pos(6) order(`vars_label') row(2)) 						///
			name(ngraph`gr', replace)																					///
			ytitle("Poverty rate (percent)")																			///
			note("`notes'", size(small))

	putexcel set "`excelout2'", modify sheet(Figure7, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(3000)		
	putexcel A1 = image("`graph'")
	putexcel save							
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure7.xlsx"	
			
end	