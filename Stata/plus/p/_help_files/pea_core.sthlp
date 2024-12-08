{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea core}{right:November 2024}
{hline}

{title:Title}

{bf:pea core} — calculates key poverty and welfare indicators

{title:Syntax}

{p 4 15}
{opt pea core} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,}  
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
{opt Country(string)} 
{opt LATEST} 
{opt WITHIN3} 
{opt BENCHmark(string)} 
{opt spells(string)}]{p_end}

{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}

{title:Description}

{p 4 4 2}  
{opt pea core} calculates several important poverty and welfare statistics for the specified country and year, including:

	- Poverty headcount ratio (e.g., the proportion of individuals below the poverty line)
	- Poverty gap (the average shortfall from the poverty line)
	- Squared poverty gap (a measure of inequality among the poor)
	- Gini index (for measuring income or wealth inequality)
	- Growth Incidence Curves (GIC) to measure income or welfare growth across the distribution
	- Other welfare indicators

{p 4 4 2}    
The results are presented in tables, showing the poverty and inequality measures for the specified year and country. The program also allows exporting the results to Excel or saving the intermediate data in a file. The `graph` option generates visualizations of the indicators, helping with a better understanding of the distribution of poverty and inequality.

{title:Options}

{p 4 4 2}
{opt NATWelfare(varname numeric)} specifies the variable for national welfare measures.

{p 4 4 2}
{opt NATPovlines(varlist numeric)} specifies a list of national poverty lines to use.

{p 4 4 2}
{opt PPPWelfare(varname numeric)} specifies the variable for purchasing power parity (PPP) adjusted welfare.

{p 4 4 2}
{opt PPPPovlines(varlist numeric)} specifies a list of PPP-adjusted poverty lines.

{p 4 4 2}
{opt Year(varname numeric)} specifies the year variable for the analysis.

{p 4 4 2}
{opt SETting(string)} specifies the setting or dataset being used.

{p 4 4 2}
{opt excel(string)} specifies the file path for exporting results to Excel.

{p 4 4 2}
{opt save(string)} specifies the file path for saving results.

{p 4 4 2}
{opt BYInd(varlist numeric)} specifies the variables by which to break down the analysis (e.g., urban/rural, subnational).

{p 4 4 2}
{opt age(varname numeric)} specifies the age variable for the analysis.

{p 4 4 2}
{opt male(varname numeric)} specifies the gender variable (e.g., male/female).

{p 4 4 2}
{opt hhhead(varname numeric)} specifies the household head status variable.

{p 4 4 2}
{opt edu(varname numeric)} specifies the education level variable.

{p 4 4 2}
{opt urban(varname numeric)} specifies the urban/rural classification variable.

{p 4 4 2}
{opt married(varname numeric)} specifies the marital status variable.

{p 4 4 2}
{opt school(varname numeric)} specifies the schooling variable.

{p 4 4 2}
{opt services(varlist numeric)} specifies a list of household service variables (e.g., water access, sanitation).

{p 4 4 2}
{opt assets(varlist numeric)} specifies a list of household asset variables (e.g., TV, car, cellphone).

{p 4 4 2}
{opt hhsize(varname numeric)} specifies the household size variable.

{p 4 4 2}
{opt hhid(string)} specifies the household ID variable.

{p 4 4 2}
{opt pid(string)} specifies the individual ID variable.

{p 4 4 2}
{opt industrycat4(varname numeric)} specifies the industry category variable.

{p 4 4 2}
{opt lstatus(varname numeric)} specifies the labor status variable (e.g., employed, unemployed).

{p 4 4 2}
{opt empstat(varname numeric)} specifies the employment status variable.

{p 4 4 2}
{opt ONELine(varname numeric)} specifies the one-line poverty line variable.

{p 4 4 2}
{opt ONEWelfare(varname numeric)} specifies the one-line welfare variable.

{p 4 4 2}
{opt MISSING} includes missing data in the analysis.

{p 4 4 2}
{opt Country(string)} specifies the country code for the analysis.

{p 4 4 2}
{opt LATEST} includes only the most recent available data.

{p 4 4 2}
{opt WITHIN3} limits analysis to data from countries within 3 years of the target year.

{p 4 4 2}
{opt BENCHmark(string)} specifies a list of benchmark countries (e.g., ALB HRV XKX).

{p 4 4 2}
{opt spells(string)} specifies the periods or time spells for longitudinal analysis (e.g., 2015 2016; 2016 2017).

{title:Examples}

{p 4 4 2} 
To calculate the poverty and welfare indicators for Ghana (GHA) in 2020, using a poverty line of $1.90 per day, and export the results to an Excel file:

{p 4 4 2} 
pea core [aw=weight_p], c(GNB) natw(welfarenom) natp(natline ) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline215) missing setting(GMD) spells(2018 2021)

{p 4 4 2} 
pea core [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) oneline(pline685) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing

{p 4 4 2}
pea core [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing setting(GMD) spells(2015 2016; 2016 2017;2018 2025;2017 2025)
