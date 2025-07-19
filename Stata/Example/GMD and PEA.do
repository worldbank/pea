
//Example PEA - data is from GMD. 
//National welfare is assumed in the data, with the examples of national poverty lines
//Code: https://github.com/worldbank/pea
//See the pdf guideline
//https://github.com/worldbank/pea/blob/main/PEA_code_manual.pdf

//Data: 
use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\GNB_2018-2021_GMD_ALL.dta" , clear
gen welfppp = welfare/cpi2017/icp2017/365
gen pline215 = 2.15
gen pline365 = 3.65
gen pline685 = 6.85
gen natline = 298084 if year==2021
replace natline = 271071.8  if year==2018
la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
la var pline365 "Poverty line: $3.65 per day (2017 PPP)"
la var pline685 "Poverty line: $6.85 per day (2017 PPP)"
la var natline "National poverty line"
replace subnatid = proper(subnatid)
split subnatid, parse("-") gen(tmp)
gen temp = tmp2 
replace temp = trim(temp)
encode temp, gen(subnatvar)
la var subnatvar "By regions"
drop tmp1  tmp2  temp
*within(3)  welfaretype(INC CONS)

svyset psu [w= weight_p],  singleunit(certainty)

//STOP - Run the above code, and then select one at a time, not all together.

pea core [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline215) missing setting(GMD) spells(2018 2021) age(age) male(male) hhsize(hsize) hhid(hhid) pid(pid) lstatus(lstatus) empstat(empstat) relationharm(relationharm) earnage(18) ppp(2017) svy std(right)


pea tables [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing setting(GMD) spells(2018 2021) svy std(right)


pea figures [aw=weight_p], c(ARM) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(CIV GHA GMB) missing setting(GMD) spells(2018 2021) welfaretype(CONS)
