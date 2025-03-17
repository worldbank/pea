cap program drop _pea_svycheck
program _pea_svycheck, rclass
	version 16.0
	syntax [if] [in] [aw pw fw], [std(string)]	
		
	cap svydescribe
	if _rc~=0 {
		noi dis "SVY is not set. Please do svyset to get the correct standard errors"
		exit `=_rc'
		//or svyset [w= `wvar'],  singleunit(certainty)
	}
	else {
		//check on singleton, remove?
		//std option: inside, below, right
		if "`std'"=="" c_local std inside
		else {
			local std = lower("`std'")
			if "`std'"~="inside" & "`std'"~="right" { //"`std'"~="below"
				noi dis "Wrong option for std(). Available options: inside, right"
				exit 198
			}
		}	
		c_local svycheck = 1
	} //else svydescribe	
end