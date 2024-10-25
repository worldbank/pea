cap program drop _pea_vars_set
program _pea_vars_set, rclass
	version 16.0
	syntax [if] [in] [aw pw fw], [SETting(string)]	

	if "`=upper("`setting'")'"=="GMD" {
		gen head = relationharm==1 if relationharm~=.
		la def head 1 "HH head" 
		la val head head 
		gen nowork = lstatus==2|lstatus==3 if lstatus~=.
		gen married = marital==1 if marital~=.
		
		*age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets		
		global pea_age "age"
		global pea_male "male"
		global pea_hhhead "head"
		global pea_edu "educat4"
		global pea_urban "urban"
		global pea_married "married"
		global pea_school "school"
		global pea_hhid "hhid"
		global pea_pid "pid"
		global pea_hhsize "hsize"
		global pea_industrycat4 "industrycat4"
		global pea_empstat "empstat"
		global pea_lstatus "nowork"
		global pea_services "imp_wat_rec imp_san_rec electricity"
		global pea_assets "tv car cellphone computer fridge"
	}
end
