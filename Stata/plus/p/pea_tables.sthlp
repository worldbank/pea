{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea tables}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea tables}  - full set of tables for the main body of the PEA, either with the GMD or country-specific data.

{title:Syntax}

{p 4 15}
{opt pea tables} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
{opt ,} 
{opt Country(string)} 
{opt Year(varname numeric)} 
{opt NATWelfare(varname numeric)} 
{opt NATPovlines(varlist numeric)} 
{opt PPPWelfare(varname numeric)} 
{opt PPPPovlines(varlist numeric)} 
{opt ONELine(varname numeric)} 
{opt ONEWelfare(varname numeric)}
{opt SETting(string)} 
{opt BENCHmark(string)} 
{opt spells(string)}
[{opt lstatus(varname numeric)} 
{opt empstat(varname numeric)} 
{opt industrycat4(varname numeric)} 
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
{opt pid(string)}]
[{opt PPPyear(integer)}
{opt SVY}
{opt std(string)}
{opt excel(string)} 
{opt save(string)} 
{opt BYInd(varlist numeric)} 
{opt vulnerability(string)}
{opt trim(string)}
{opt MISSING} 
{opt LATEST} 
{opt WITHIN3} 
{opt minobs(numlist)}]{p_end}

{p 4 4 2}
The following only need to be used if setting(GMD) is not specified:
{bf:hhhead, edu, married, school, services, assets, hhsize, hhid, pid, industrycat4, lstatus, and empstat}.

{title:Description}

{p 4 4 2}{opt pea tables} generates a set of tables related to poverty, welfare, and income distribution. The command can generate various tables with user-defined specifications based on different variables like income, welfare measures, poverty lines, and socio-demographic characteristics.

{p 4 4 2}This command is part of a suite of `pea` commands that provide flexibility in computing welfare and poverty statistics across a variety of groups, such as by region (urban/rural), year, and socioeconomic categories. It generates detailed tables summarizing these measures at the individual or household level.

{p 4 4 2}Tables generated may include poverty headcount ratios, income distributions, and aggregate poverty gaps. Additionally, it can generate statistics like the Watts index, Sen index, and Foster-Greer-Thorbecke indices.

{p 4 4 2}The following tables are available within the {opt pea tables} command, each serving a distinct purpose. For more detailed explanations of their contents and usage, see below:{p_end}

{p 4 7}{opt Table 1}: core poverty indicators. {p_end}
{p 4 7}{bf:{help pea table1:[PEA] pea table1}} 

{p 4 7}{opt Table 2}: poverty rate and share of poor by area and region. {p_end}
{p 4 7}{bf:{help pea table2:[PEA] pea table2}} 

{p 4 7}{opt Table 3}: subgroup poverty rates.{p_end}
{p 4 7}{bf:{help pea table3:[PEA] pea table3}} 

{p 4 7}{opt Table 6}: Multidimensional Poverty Measure (World Bank).{p_end}
{p 4 7}{bf:{help pea table6:[PEA] pea table6}}

{p 4 7}{opt Table 7}: vulnerability for poverty.{p_end}
{p 4 7}{bf:{help pea table7:[PEA] pea table7}} 

{p 4 7}{opt Table 8}: core inequality indicators.{p_end}
{p 4 7}{bf:{help pea table8:[PEA] pea table8}} 

{p 4 7}{opt Table 9}: vision indicators (corporate scorecard).{p_end}
{p 4 7}{bf:{help pea table9:[PEA] pea table9}} 

{p 4 7}{opt Table 10}: benchmarking of poverty and inequality.{p_end}
{p 4 7}{bf:{help pea table10:[PEA] pea table10}} 

{p 4 7}{opt Table 11}: Growth Incidence Curve. {p_end}
{p 4 7}{bf:{help pea table11:[PEA] pea table11}} 

{p 4 7}{opt Table 12}: decomposition of poverty changes: growth and redistribution.{p_end}
{p 4 7}{bf:{help pea table12:[PEA] pea table12}}

{p 4 7}{opt Table 13}: decomposition of poverty changes: Huppi-Ravallion decomposition.{p_end}
{p 4 7}{bf:{help pea table13:[PEA] pea table13}} 

{p 4 7}{opt Table 14}: profiles of the poor.{p_end}
{p 4 7}{bf:{help pea table14:[PEA] pea table14}} 

{p 4 7}{opt Table A2}: core poverty indicators (test). {p_end}
{p 4 7}{bf:{help pea table_A2:[PEA] pea table A2}}  

{title:Required options}

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
{opt ONELine(varname numeric)}: specifies the main poverty line variable. This will be used by default if only one line is used.

{p 4 4 2}
{opt ONEWelfare(varname numeric)}: specifies the main welfare variable. This will be used by default if only one measure is used.
    
{p 4 4 2}
{opt Year(varname numeric)}: specifies the year variable for the analysis.

{p 4 4 2}
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options
 (hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 
 Either setting(GMD) or these options need to be specified.

{p 4 4 2}
{opt BENCHmark(string)}: specifies a list of benchmark countries (e.g., ALB HRV XKX).

{p 4 4 2}
{opt spells(string)}: specifies the periods or time spells for longitudinal analysis (e.g., 2015 2016; 2016 2017).
 
{title:Options if setting(GMD) is not specified}

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed). Please note that the input variable should have 'not working' (i.e. unemployed or out of labor force) as the value = 1, and employed as a different value. 
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{p 4 4 2}
{opt industrycat4(varname numeric)}: specifies the industry category variable.
Default under setting(GMD): industrycat4

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

{title:Additional options}

{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.
     
{p 4 4 2} 
{opt SVY}: triggers 'svy set' in Stata. If the data is not svy set, no standard errors will be produced. Only relevant for Table A.1.
 
{p 4 4 2} 
{opt std(string)}: Only works when data is svy set. Specifies where standard-errors are displayed. Available options are 'inside' or 'right', where inside means that the standard-error will be added in the same cell as the main statistic, and right means that it will be added in a separate cell to the right.
Default is inside.
 
{p 4 4 2}
{opt excel(string)}: specifies the file path for exporting results to Excel.

{p 4 4 2}
{opt save(string)}: specifies the file path for saving results.

{p 4 4 2}
{opt BYInd(varlist numeric)}: specifies the variables by which to break down the analysis (e.g., urban/rural, subnational).

{p 4 4 2}
{opt vulnerability(string)}: specifies the value by which the main poverty line is multipliede to define vulnerability to poverty.
Vulnerability to poverty is defined as being between the main and the multiple of the poverty line. Default is vulnerability(1.5).

{p 4 4 2}
{opt trim(string)}: specifies percentiles below and above which growth incidence curves are trimmed (Figure A.1).
Default is trim(3 97).

{p 4 4 2}
{opt MISSING}: Optional. Includes missing data in the analysis.

{p 4 4 2}
{opt LATEST}: includes only the most recent available data.

{p 4 4 2}
{opt WITHIN3}: limits analysis to data from countries within 3 years of the target year.

{p 4 4 2}
{opt minobs(numlist)}: specifies the minimum number of observations required to display a cell value.


{title:Examples}

When setting(GMD) is specified:

{p 4 4 2}
{bf:pea tables} [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) 
missing setting(GMD) spells(2018 2021)

{p 4 4 2}
{bf:pea tables} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing setting(GMD) 
spells(2015 2016; 2016 2017;2018 2025;2017 2025)

When setting(GMD) is NOT specified:

{p 4 4 2}
{bf:pea tables} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) 
school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing onew(welfppp) onel(pline365) spells(2015 2016; 2016 2017;2018 2025;2017 2025)







