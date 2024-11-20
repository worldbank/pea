

cap program drop pea_figure7
program pea_figure7, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS using(string) Year(varname numeric) CORE setting(string) LINESORTED excel(string) save(string) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) file(string) save(string) scheme(string) palette(string) MISSING]
	
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
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year' `byind' `age'"'
		markout `touse' `flist' 
	} //qui
		
		
	// Generate poverty measures
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		gen double _pop = `wvar'
	}
	gen _total = 1
	la def _total 1 "Total"
	la val _total _total	
	tempfile data1 data2
	save `data1', replace
	clear
	save `data2', replace emptyok	

	// 
	use `data1', clear	
	local byind `male' _total

	local i = 1
	foreach var of local byind {
		use `data1', clear
		levelsof `var', local(lclist)
		local label1 : value label `var'
		 
		foreach lvl of local lclist {
			use `data1', clear
			keep if `var'==`lvl'
			local lbllvl : label `label1' `lvl'			
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) rawsum(_pop) by(`year')
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
	la val _group _group
	
	foreach p of local ppppovlines {
		gen num_`p' = _fgt0_`pppwelfare'_`p' * _pop
		bys `year': 
	}
		
end	