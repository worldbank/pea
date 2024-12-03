//IDN

adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"

use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\IDN_GMD_ALL_clean.dta" , clear
/*
gen welfppp = welfare/cpi2017/icp2017/365
gen pline215 = 2.15
gen pline365 = 3.65
gen pline685 = 6.85
gen natline = 1240939  if year==2000
replace natline = 2140828  if year==2007
replace natline = 2622254  if year==2008
replace natline = 3286805  if year==2012
replace natline = 4065332  if year==2016
replace natline = 4665332  if year==2020
replace natline = 5065332  if year==2023

replace subnatid = proper(subnatid1)
split subnatid1, parse("-") gen(tmp)
gen temp = tmp2 
replace temp = trim(temp)
encode temp, gen(subnatvar)
drop tmp1  tmp2  temp
*/
la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
la var pline365 "Poverty line: $3.65 per day (2017 PPP)"
la var pline685 "Poverty line: $6.85 per day (2017 PPP)"
la var natline "National poverty line"
la var subnatvar "By regions"
replace year = 2022 if year==2023

pea figures [aw=weight_p], c(IDN) natw(welfare) natp(natline ) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(MYS VNM THA) missing setting(GMD) spells(2000 2007; 2007 2008; 2016 2022) comparability(comparability) welfaretype(CONS) 

use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\IDN_GMD_ALL_clean.dta" , clear

la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
la var pline365 "Poverty line: $3.65 per day (2017 PPP)"
la var pline685 "Poverty line: $6.85 per day (2017 PPP)"
la var natline "National poverty line"
la var subnatvar "By regions"
replace year = 2022 if year==2023

*pea_table10 [aw=weight_p], c(IDN) welfare(welfppp) povlines(pline365 pline215 pline685) year(year) benchmark(MYS VNM THA PHL) latest
/*
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
gen married = marital==1 if marital~=.

pea_table14 [aw=weight_p], welfare(welfppp) povlines(pline685) year(year) missing age(age) male(male) edu(educat4) hhhead(head)  urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(cellphone computer) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) 

pea_table11 [aw=weight_p], welfare(welfppp) spells(2000 2007; 2007 2008; 2016 2022) year(year) by(urban) graph

pea_table11 [aw=weight_p], welfare(welfppp) spells(2000 2007; 2007 2008; 2016 2022) year(year) nooutput

pea_table12 [aw=weight_p], natw(welfare) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2000 2007; 2007 2008; 2016 2022) year(year) 

pea_table13 [aw=weight_p], natw(welfare) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2002 2007; 2007 2008; 2016 2022) year(year) urban(urban)
*/
pea tables [aw=weight_p], c(IDN) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(MYS VNM THA PHL) missing setting(GMD) spells(2000 2007; 2007 2008; 2016 2022)

use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\IDN_GMD_ALL_clean.dta" , clear

la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
la var pline365 "Poverty line: $3.65 per day (2017 PPP)"
la var pline685 "Poverty line: $6.85 per day (2017 PPP)"
la var natline "National poverty line"
la var subnatvar "By regions"
replace year = 2022 if year==2023

pea core [aw=weight_p], c(IDN) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(MYS VNM THA PHL) missing setting(GMD) spells(2000 2007; 2007 2008; 2016 2022)

