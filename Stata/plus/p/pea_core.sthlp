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
{opt BYInd(varlist numeric)} 
{opt vulnerability(string)}
{opt comparability(varname numeric)}
{opt trim(string)}
{opt aggregate(string)}
{opt MISSING} 
{opt LATEST} 
{opt WITHIN3} 
{opt minobs(numlist)}
{opt earnage(integer)}
{opt year_fcast}
{opt natpov_fcast}
{opt gdp_fcast}
{opt comparability_peb(varname strings)}
{opt yrange(string)} 
{opt yrange2(string)} 
{opt NOEQUALSPACING} 
{opt scheme(string)}
{opt palette(string)}
{opt excel(string)} 
{opt save(string)}]{p_end}

{p 4 4 2}
The following only need to be used if setting(GMD) is not specified:
{bf:hhhead, edu, married, school, services, assets, hhsize, hhid, pid, industrycat4, lstatus, and empstat}.

{title:Description}

{p 4 4 2}  
{opt pea core} generates core tables and figures, and a standardized data annex that every PEA should contain, as set out in the new PEA guidelines. 
The produced Excel file contains 7 tables and 3 figures. 
This annex is composed of main poverty, shared prosperity and labor indicators, as well as multidimensional and sub-group (e.g. by age or education) poverty rates. 
The code also produces core statistics for benchmark countries, the PEA country’s region and income group, and profiles of the poor and non-poor. 
Growth incidence curves and the Datt-Ravallion decomposition complement the core outputs. 

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
{opt setting(string)}: If GMD option is specified, harmonized variables are created, and additional options
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
{opt scheme(string)}: Optional. Sets the scheme, specifying the overall look of the figures. 
Default is "white_tableau".

{p 4 4 2}
{opt palette(string)}: Optional. Sets the color palette for figures. Default is "tab20". 
See Annex 1: Example. Either string (e.g. vividis) or list of colors.

{p 4 4 2}
{opt noequalspacing}: Optional. When specified, figures show gaps between years on the x-axis proportional to their distance. Default is to display constant gaps between years, regardless of how far away years are. 
This can be useful if gaps between survey-years are large.
  
{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)". 
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 10).
    
{p 4 4 2}
{opt yrange2}: Optional. For core Figure 1, users can specify the range of the RIGHT y-axis (GDP per capita). The range must be entered in Stata figure format, such as "yrange(0(10)100)".
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 10).

{p 4 4 2}
{opt comparability_peb(varname numeric)}: Only relevant for core Figure 1: This variable denotes which survey rounds are comparable over time. 
The variable is taken from PEBs and follows its notation. Comparable spells are denoted by "Yes" and non-comparable by "No". Note that this is different from the comparability variable elsewhere specified.
Non-comparable survey rounds are not connected in figures. 

{p 4 4 2}
{opt year_fcast}: Only relevant for core Figure 1: To show now- and forecasts in the figure, insert the variable with forecast years here. See {help pea_figureC1} for more information.

{p 4 4 2}
{opt natpov_fcast}: Only relevant for core Figure 1: To show now- and forecasts in the figure, insert the variable with forecast national poverty here. See {help pea_figureC1} for more information.

{p 4 4 2}
{opt gdp_fcast}: Only relevant for core Figure 1: To show now- and forecasts in the figure, insert the variable with forecast GDP here. See {help pea_figureC1} for more information.

{p 4 4 2}
{opt earnage(integer)}: specifies the age cut-off for working status for the economic composition. Working status depends both on labor force status (lstatus) and employment status (empstat). Individuals will only be considered working if as old or older than the cut-off.
Default: 16

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
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time, which is relevant for the Growth Incidence Curve, and the Datt-Ravallion decomposition. 
When specified, survey rounds are not shown if they are non-comparable. Example:	comparability(comparability).

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

{p 4 4 2}
{opt aggregate(string)}: specifies the way comparator countries or aggregates are displayed in Table C.1.
	Available options are: 
	
	- Default: If aggregate() is not specified, peer countries will be shown individually.
	- aggregate({bf: groups}): Will display aggregate values for countries within the same region or income group as PEA countries (using population weights). 
		Region and income group countries are included if a survey within 3 years of last survey year of the PEA country is available. 
		Note: Regional and income group poverty rates deviate from official World Bank published rates, as no line-up values are used.
	- aggregate({bf: benchmark}): Will display aggregate values for peer countries specified in option {bf: benchmark(string)}). 
		Peer countries are included if a survey within 3 years of last survey year of the PEA country is available.
		
{title:Examples}

When GMD is specified:

{p 4 4 2}
{bf:pea core} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing setting(GMD) comparability(comparability) spells(2015 2016; 2016 2017;2018 2025;2017 2025) minobs(100)

pea core [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(VNM IDN THA) missing setting(GMD) spells(2015 2018; 2018 2021) svy std(inside) aggregate(groups)

With forecasts in Figure 1:

pea core [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(SEN CIV GHA SLE) aggregate(groups) missing setting(GMD) spells(2018 2021) svy std(right) comparability_peb(comparability_peb) natpov_fcast(natpov_fcast) gdp_fcast(gdp_fcast) yrange(20(20)80) yrange2(300000(50000)500000)

When GMD is NOT specified:

{p 4 4 2} 
{bf:pea core} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) oneline(pline685) benchmark(ALB HRV XKX) onew(welfppp) onel(pline365) missing


