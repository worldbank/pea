{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea core}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea core} — core tables and figures for the standardized data annex.

{title:Syntax}

{p 4 15}
{opt pea core} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
{opt ,}  
[{opt Country(string)} 
{opt NATWelfare(varname numeric)} 
{opt NATPovlines(varlist numeric)} 
{opt PPPWelfare(varname numeric)} 
{opt PPPPovlines(varlist numeric)} 
{opt Year(varname numeric)} 
{opt SETting(string)} 
{opt excel(string)} 
{opt save(string)} 
{opt BYInd(varlist numeric)} 
{opt age(varname numeric)} 
{opt male(varname numeric)} 
{opt hhhead(varname numeric)} 
{opt edu(varname numeric)} 
{opt urban(varname numeric)} 
{opt married(varname numeric)} 
{opt school(varname numeric)} 
{opt services(varlist numeric)} 
{opt assets(varlist numeric)} 
{opt hhsize(varname numeric)} 
{opt hhid(string)} 
{opt pid(string)} 
{opt industrycat4(varname numeric)} 
{opt lstatus(varname numeric)} 
{opt empstat(varname numeric)} 
{opt ONELine(varname numeric)} 
{opt ONEWelfare(varname numeric)}
{opt MISSING} 
{opt LATEST} 
{opt WITHIN3} 
{opt BENCHmark(string)} 
{opt spells(string)}]{p_end}

{p 4 4 2}
The following are NON-mandatory options and are only used if setting(GMD) is not specified:
{bf:hhhead, edu, married, school, services, assets, hhsize, hhid, pid, industrycat4, lstatus, and empstat}.

{title:Description}

{p 4 4 2}  
{opt pea core} generates a standardized data annex that every PEA should contain, as set out in the new PEA guidelines. 
The produced Excel file contains 4 tables and 2 figures. 
This annex is composed of main poverty and shared prosperity indicators, as well as multidimensional and sub-group (e.g. by age or education) poverty rates. 
The code also produces core statistics for benchmark countries, the PEA country’s region and income group, and profiles of the poor and non-poor. 
Growth incidence curves and the Datt-Ravallion decomposition complement the core outputs. 

{title:Options}

Main options:

{p 4 4 2}
{opt Country(string)}: 3-letter country code for the analysis.

{p 4 4 2}
{opt NATWelfare(varname numeric)}: specifies the variable for national welfare measures.

{p 4 4 2}
{opt NATPovlines(varlist numeric)}: specifies a list of national poverty lines to use.

{p 4 4 2}
{opt PPPWelfare(varname numeric)}: specifies the variable for purchasing power parity (PPP) adjusted welfare.

{p 4 4 2}
{opt PPPPovlines(varlist numeric)}: specifies a list of PPP-adjusted poverty lines.

{p 4 4 2}
{opt Year(varname numeric)}: specifies the year variable for the analysis.

{p 4 4 2}
{opt SETting(string)}: specifies the setting or dataset being used.

{p 4 4 2}
{opt excel(string)}: specifies the file path for exporting results to Excel.

{p 4 4 2}
{opt save(string)}: specifies the file path for saving results.

{p 4 4 2}
{opt BYInd(varlist numeric)}: specifies the variables by which to break down the analysis (e.g., urban/rural, subnational).

{p 4 4 2}
{opt ONELine(varname numeric)}: specifies the one-line poverty line variable.

{p 4 4 2}
{opt ONEWelfare(varname numeric)}: specifies the one-line welfare variable.

{p 4 4 2}
{opt MISSING}: Optional. Includes missing data in the analysis.

{p 4 4 2}
{opt LATEST}: includes only the most recent available data.

{p 4 4 2}
{opt WITHIN3}: limits analysis to data from countries within 3 years of the target year.

{p 4 4 2}
{opt BENCHmark(string)}: specifies a list of benchmark countries (e.g., ALB HRV XKX).

{p 4 4 2}
{opt spells(string)}: specifies the periods or time spells for longitudinal analysis (e.g., 2015 2016; 2016 2017).

Additional options if setting(GMD) is not specified:

{p 4 4 2}
{opt age(varname numeric)}: specifies the age variable for the analysis.
Default under setting(GMD): age

{p 4 4 2}
{opt male(varname numeric)}: specifies the gender variable (e.g., male/female).
Default under setting(GMD): male

{p 4 4 2}
{opt hhhead(varname numeric)}: specifies the household head status variable.
Default under setting(GMD): head

{p 4 4 2}
{opt edu(varname numeric)}: specifies the education level variable.
Default under setting(GMD): educat4    

{p 4 4 2}
{opt urban(varname numeric)}: specifies the urban/rural classification variable.
Default under setting(GMD): urban

{p 4 4 2}
{opt married(varname numeric)}: specifies the marital status variable.
Default under setting(GMD): married

{p 4 4 2}
{opt school(varname numeric)}: specifies the schooling variable.
Default under setting(GMD): school

{p 4 4 2}
{opt services(varlist numeric)}: specifies a list of household service variables (e.g., water access, sanitation).
Default under setting(GMD): imp_wat_rec imp_san_rec electricity

{p 4 4 2}
{opt assets(varlist numeric)}: specifies a list of household asset variables (e.g., TV, car, cellphone).
Default under setting(GMD): tv car cellphone computer fridge

{p 4 4 2}
{opt hhsize(varname numeric)}: specifies the household size variable.
Default under setting(GMD): hsize

{p 4 4 2}
{opt hhid(string)}: specifies the household ID variable.
Default under setting(GMD): hhid

{p 4 4 2}
{opt pid(string)}: specifies the individual ID variable.
Default under setting(GMD): pid

{p 4 4 2}
{opt industrycat4(varname numeric)}: specifies the industry category variable.
Default under setting(GMD): industrycat4

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed).
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{title:Examples}

When GMD is specified:

{p 4 4 2}
{bf:pea core} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing setting(GMD) 
spells(2015 2016; 2016 2017;2018 2025;2017 2025)

When GMD is NOT specified:

{p 4 4 2} 
{bf:pea core} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school)
 services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) oneline(pline685) benchmark(ALB HRV XKX) onew(welfppp) 
 onel(pline365) missing


