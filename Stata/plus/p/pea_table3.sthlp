{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table3} — Subgroup poverty rates.

{title:Syntax}

{p 4 15}
{opt  pea table3}
	[{it:weight}] 
	[{opt if} {it:exp}] 
	[{opt in} {it:exp}] 
	[{opt ,}  
	{opt Country(string)} 
    {opt NATWelfare(varname numeric)}
	{opt NATPovlines(varlist numeric)} 
    {opt PPPWelfare(varname numeric)} 
	{opt PPPPovlines(varlist numeric)} 
	{opt PPPyear(integer)}
    {opt FGTVARS}
	{opt using(string)} 
    {opt Year(varname numeric)} 
    {opt LINESORTED} 
	{opt excel(string)} 
	{opt save(string)} 
    {opt MISSING} 
	{opt minobs(numlist)}
	{opt age(varname numeric)}
	{opt male(varname numeric)} 
    {opt hhhead(varname numeric)}
	{opt edu(varname numeric)}]{p_end}

{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}

{title:Description}

{p 4 4 2}  
{opt pea table3} generates three detailed tables that provides poverty statistics based on both 
    national and international poverty lines, as well as specified welfare measures. Table 3a presents poverty rates by sex and age-group, Table 3b by education, and Table 3c by age, gender, and education level of the household head. 

{title:Options}

{p 4 4 2} 
{opt Country(string)}:
 specifies the country code or name for the analysis.
    
{p 4 4 2} 
{opt NATWelfare(varname numeric)}:
 is the variable containing national welfare values for analysis, such as income or consumption.

{p 4 4 2} 
{opt NATPovlines(varlist numeric)}:
 lists the national poverty lines to be used for poverty analysis.
    
{p 4 4 2} 
{opt PPPWelfare(varname numeric)}:
 is the welfare variable adjusted for purchasing power parity (PPP), typically for international comparisons.
    
{p 4 4 2} 
{opt PPPPovlines(varlist numeric)}:
 lists the PPP-adjusted poverty lines.
    
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt FGTVARS}:
 generates Foster-Greer-Thorbecke (FGT) poverty indices, including headcount, poverty gap, and squared poverty gap.

{p 4 4 2} 
{opt using(string)}:
 specifies the dataset to use for the analysis.
    
{p 4 4 2}
{opt Year(varname numeric)}:
 is the variable indicating the year for each observation.
  
{p 4 4 2} 
{opt LINESORTED}:
 indicates that the poverty lines are already sorted and skips internal sorting for efficiency.
    
{p 4 4 2} 
{opt excel(string)}:
 specifies an Excel file for saving the results. If this option is not specified, a temporary file is used by default.

{p 4 4 2} 
{opt save(string)}:
 specifies a file path to save the generated table in Stata dataset format.

{p 4 4 2} 
{opt MISSING}:
 handles missing data in key demographic variables like age, gender, and education.

{p 4 4 2} 
{opt age(varname numeric)}:
 specifies the variable representing age groups for subgroup analysis.

{p 4 4 2} 
{opt male(varname numeric)}:
 specifies the variable representing gender (typically 1 for male, 0 for female).

{p 4 4 2} 
{opt hhhead(varname numeric)}:
 specifies the variable indicating household head status (typically 1 for head, 0 for non-head).

{p 4 4 2} 
{opt edu(varname numeric)}:
 specifies the variable indicating education level for subgroup analysis.

 {p 4 4 2}
{opt minobs(numlist)}: specifies the minimum number of observations required to display a cell value.

{title:Examples}
  
{p 4 4 2}
{bf:pea table3} [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year)  age(age) male(male) hhhead(head) edu(educat4) missing
  
{p 4 4 2}
{bf:pea table3} [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year)  age(age) male(male) hhhead(head) edu(educat4) minobs(100) missing

