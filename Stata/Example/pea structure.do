//pea code
//data example

//PEA example code

** DLW UAT
*sysdir set PLUS "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\Global\All GSGs\PEA\Coding\plus\" 
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"

/*
use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\ARM_2015_2018_2025_GMD_ALL.dta" , clear
keep if year==2018
gen welfppp = welfare/cpi2017/icp2017/365
_pea_mpm [aw=weight_p], c(ARM)  welfare(welfppp) setting(GMD)
*/

***
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

*gen head = relationharm==1 if relationharm~=.
*la def head 1 "HH head" 
*la val head head

pea_table1 [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) core onew(welfppp) onel(pline215)

pea_table1 [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline365)

pea_table_A2 [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) age(age) male(male) edu(educat4) missing

pea_table3 [aw=weight_p], natw(welfare) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) year(year)  age(age) male(male) hhhead(head) edu(educat4) 
missing

pea tables [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing setting(GMD) spells(2018 2021)

pea core [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline215) missing setting(GMD) spells(2018 2021)

*****
use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\PER_2017-2022_GMD_ALL.dta", clear
use "c:\Users\wb327173\OneDrive - WBG\Min core analytics\PEA ado\data\ARM_2015_2018_2025_GMD_ALL.dta" , clear

gen welfppp = welfare/cpi2017/icp2017/365
gen pline215 = 2.15
gen pline365 = 3.65
gen pline685 = 6.85
gen natline = 303974.3 
gen natline2 = 500000
la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
la var pline365 "Poverty line: $3.65 per day (2017 PPP)"
la var pline685 "Poverty line: $6.85 per day (2017 PPP)"
la var natline "Poverty line: 300,000 per year (2017 LCU)"
la var natline2 "Poverty line: 500,000 per year (2017 LCU)"
split subnatid, parse("-") gen(tmp)
split subnatid1, parse("-") gen(tmpb)
gen temp = tmp2 
replace temp = tmpb2 if temp==""
replace temp = trim(temp)
encode temp, gen(subnatvar)
la var subnatvar "By regions"
drop tmp1 tmpb1 tmp2 tmpb2 temp

*drop if year==2015|year==2016|year==2017

/*
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
gen married = marital==1 if marital~=.
*/

pea tables [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing onew(welfppp) onel(pline365) spells(2015 2016; 2016 2017;2018 2025;2017 2025)

pea tables [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing setting(GMD) spells(2015 2016; 2016 2017;2018 2025;2017 2025)

pea core [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) oneline(pline685) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing

pea core [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing setting(GMD) spells(2015 2016; 2016 2017;2018 2025;2017 2025)
s
pea_table1 [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) core onew(welfppp) onel(pline365)

pea_table1 [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline365)

pea_table2 [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) 

pea_table3 [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year)  age(age) male(male) hhhead(head) edu(educat4) missing

pea_table_A2 [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) age(age) male(male) edu(educat4) missing

pea_table6 [aw=weight_p], c(ARM) welfare(welfppp) year(year)  benchmark(ALB HRV XKX) setting(GMD) last3

pea_table7 [aw=weight_p], welfare(welfppp) povlines(pline365) year(year) 

pea_table8 [aw=weight_p], welfare(welfare) year(year) byind(urban) missing

pea_table10 [aw=weight_p], c(ARM) welfare(welfppp) povlines(pline365 pline215 pline685) year(year) benchmark(ALB HRV XKX) latest
//not running if there is no countries within 3 years.
pea_table10 [aw=weight_p], c(ARM) welfare(welfppp) povlines(pline365 pline215 pline685) year(year) benchmark(ALB HRV XKX) within3

pea_table11 [aw=weight_p], welfare(welfppp) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) by(urban) graph

pea_table11 [aw=weight_p], welfare(welfppp) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) nooutput

pea_table12 [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) 

pea_table13 [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) urban(urban)

pea_table14 [aw=weight_p], welfare(welfppp) povlines(pline685) year(year) missing age(age) male(male) edu(educat4) hhhead(head)  urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) 

core

pea_table11 [aw=weight_p], natw(welfare) natp(natline ) year(year) core spell()

pea core []

spells(var1)
var1 = 1 when it is 2017-2020
var2 = 1 when it is 2017-2022

spell1() spell2()
core


sssss	
pea 

Stata code:
pea, global core natwelfare(var1) natpovlines() pppwelfare(var2) ppppovlines(pline215 pline365 pline685) age(age) hhhead(head) education(educat4) bygroups(agecat gender eduhead)… etc

benchmark()
natwelfare(var1) natpovlines()
pppwelfare(var2) ppppovlines(pline215 pline365 pline685)
age(age) hhhead(head) education(educat4) 
bygroups(agecat gender eduhead)


we can also take it by tables such as
pea core, [options]
pea tables, [options]
then check the variable conditions and trigger the sub-tables

pea table1, options
pea table2, options
