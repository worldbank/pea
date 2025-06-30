{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table1}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table1} — Core poverty indicators.

{title:Syntax}

{p 4 15}
{opt pea table1}
	[{it:weight}] 
	[{opt if} {it:exp}] 
	[{opt in} {it:exp}] 
	[{opt ,}  
	{opt Country(string)} 
    {opt NATWelfare(varname numeric)} 
	{opt NATPovlines(varlist numeric)} 
    {opt PPPWelfare(varname numeric)} 
	{opt PPPPovlines(varlist numeric)} 
	{opt pppyear(integer)}
	{opt SVY}
	{opt std(string)}
    {opt FGTVARS} 
	{opt using(string)} 
    {opt Year(varname numeric)} 
    {opt LINESORTED} 
	{opt excel(string)} 
	{opt save(string)} 
    {opt ONELine(varname numeric)}
	{opt ONEWelfare(varname numeric)}
	{opt vulnerability(string)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea table1} generates core poverty indicators based on specified national and international poverty lines and welfare indicators.

{p 4 4 2}
These include: Poverty headcount, gap, severity and number of poor across different poverty lines (international and national poverty lines), and Welfare by quintile, mean, median, bottom 40% and top 60%.
	
{title:Options}

{p 4 4 2} 
{opt Country(string)}:
 specifies the country code or name for the analysis.
    
{p 4 4 2} 
{opt NATWelfare(varname numeric)}:
 is the variable containing welfare values for national analysis.

{p 4 4 2} 
{opt NATPovlines(varlist numeric)}:
lists the national poverty lines used in the analysis.
    
{p 4 4 2} 
{opt PPPWelfare(varname numeric)}:
 is the welfare variable adjusted for purchasing power parity (PPP).
    
{p 4 4 2} 
{opt PPPPovlines(varlist numeric)}:
 lists the PPP-adjusted poverty lines.
     
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt SVY}: triggers 'svy set' in Stata. If the data is not svy set, no standard errors will be produced.
 
{p 4 4 2} 
{opt std(string)}: Only works when data is svy set. Specifies where standard-errors are displayed. Available options are 'inside' or 'right', where inside means that the standard-error will be added in the same cell as the main statistic, and right means that it will be added in a separate cell to the right.
Default is inside.

{p 4 4 2} 
{opt FGTVARS}:
 generates Foster-Greer-Thorbecke (FGT) poverty indices (headcount, gap, and severity).
    
{p 4 4 2} 
{opt using(string)}:
 specifies the dataset to use; the dataset will be loaded if provided.
    
{p 4 4 2} 
{opt Year(varname numeric)}:
 is the variable indicating the year for each observation.
    
{p 4 4 2} 
{opt LINESORTED}:
 indicates that the poverty lines are already sorted; skipping internal sorting.
    
{p 4 4 2} 
{opt excel(string)}:
 specifies an Excel file for saving the results. If this option is not specified, a temporary file will be used.

{p 4 4 2} 
{opt save(string)}:
 specifies a file path to save the generated table in Stata format.

{p 4 4 2} 
{opt ONELine(varname numeric)}:
 is the poverty line variable for calculating additional poverty statistics.

{p 4 4 2} 
{opt ONEWelfare(varname numeric)}:
 is the welfare variable associated with the {opt ONELine} poverty line.

If core is specified:
 
{p 4 4 2}
{opt vulnerability(string)}: specifies the value by which the main poverty line is multipliede to define vulnerability to poverty.
Vulnerability to poverty is defined as being between the main and the multiple of the poverty line. Default is vulnerability(1.5).


{title:Examples}

{p 4 4 2}     
{bf:pea table1} [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) core onew(welfppp) onel(pline215)

{p 4 4 2} 
{bf:pea table1} [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline365)

{p 4 4 2} 
{bf:pea table1} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) core onew(welfppp) onel(pline365)

{p 4 4 2} 
{bf:pea table1} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline365)
