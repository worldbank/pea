cap program drop _pea_vars_set
program _pea_vars_set, rclass
	version 16.0
	syntax [if] [in] [aw pw fw], [SETting(string)]	

	if "`=upper("`setting'")'"=="GMD" {
		//checking GMD variables
		local vlistcheck hhid pid 
		foreach var of local vlistcheck {
			cap des `var'
			if _rc==0 {
				gen ct_`var' = ~missing(`var')
				qui su ct_`var', d 
				if r(N)==0 {
					noi dis as error "Variable `var' has no values/missing in the GMD data. Please check."
					error 1
				}
				cap drop ct_`var'
			}
			else {
				noi dis as error "Variable `var' has no values/missing in the GMD data. Please check."
				error 1
			}			
		}

		local vlistcheck age male educat4 urban marital school hsize imp_wat_rec imp_san_rec electricity relationharm
		foreach var of local vlistcheck {
			cap des `var'
			if _rc==0 {
				qui su `var',d
				if r(N)==0 {
					noi dis as error "Variable `var' has no values/missing in the GMD data. Please check."
					error 1
				}
			}
		}
		
		//Head
		cap des relationharm
		if _rc==0 {
			qui tab relationharm
			if r(r)>0 {
				gen head = relationharm==1 if relationharm~=.
				la def head 1 "HH head" 
				la val head head
				global pea_hhhead "head"
			}
			else {				
				noi dis as error "Variable relationharm is missing in the GMD data."
				error 1
			}
		}
		else {
			noi dis as error "Variable relationharm is missing in the GMD data."
			error 1
		}
		
		//lstatus
		cap des lstatus
		if _rc==0 {
			qui tab lstatus
			if r(r)>0 {
				gen nowork = lstatus==2|lstatus==3 if lstatus~=.
				global pea_lstatus "nowork"
			}
			else {				
				noi dis as error "Variable lstatus is missing in the GMD data."				
				global pea_lstatus ""
				*error 1
			}
		}
		else {
			noi dis as error "Variable lstatus is missing in the GMD data."
			global pea_lstatus "nowrk"
			*error 1
		}
		
		gen married = marital==1 if marital~=.
		la var male "By gender"
		la var urban "Urban or rural"
		*age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets		
		global pea_age "age"
		global pea_male "male"
		
		global pea_edu "educat4"
		global pea_urban "urban"
		global pea_married "married"
		global pea_school "school"
		global pea_hhid "hhid"
		global pea_pid "pid"
		global pea_hhsize "hsize"
		global pea_services "imp_wat_rec imp_san_rec electricity"
		global pea_relationharm "relationharm"
		
		//lstatus
		cap des industrycat4
		if _rc==0 {
			qui tab industrycat4
			if r(r)>0 {
				global pea_industrycat4 "industrycat4"				
			}
			else {				
				noi dis as error "Variable industrycat4 is missing in the GMD data."				
				global pea_industrycat4 ""								
				*error 1
			}
		}
		else {
			noi dis as error "Variable industrycat4 is missing in the GMD data."
			global pea_industrycat4 ""										
			*error 1
		}
		
		//empstat
		cap des empstat
		if _rc==0 {
			qui tab empstat
			if r(r)>0 {
				global pea_empstat "empstat"				
			}
			else {				
				noi dis as error "Variable empstat is missing in the GMD data."				
				global pea_empstat ""
				*error 1
			}
		}
		else {
			noi dis as error "Variable empstat is missing in the GMD data."
			global pea_empstat ""
			*error 1
		}
			
		//assets 
		local vlistcheck tv car cellphone computer fridge
		local assets1
		foreach var of local vlistcheck {
			cap des `var'
			if _rc==0 {
				qui ta `var'
				if r(r) > 0 local assets1 "`assets1' `var'"
			}
		}
		global pea_assets "`assets1'"
	}
end
