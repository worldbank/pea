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
    {opt FGTVARS} 
	{opt using(string)} 
    {opt Year(varname numeric)} 
	{opt setting(string)} 
    {opt LINESORTED} 
	{opt excel(string)} 
	{opt save(string)} 
    {opt ONELine(varname numeric)}
	{opt ONEWelfare(varname numeric)}]{p_end} 

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
{opt FGTVARS}:
 generates Foster-Greer-Thorbecke (FGT) poverty indices (headcount, gap, and severity).
    
{p 4 4 2} 
{opt using(string)}:
 specifies the dataset to use; the dataset will be loaded if provided.
    
{p 4 4 2} 
{opt Year(varname numeric)}:
 is the variable indicating the year for each observation.
    
{p 4 4 2} 
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options 
(hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 
    
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

{title:Examples}

{p 4 4 2}     
{bf:pea table1} [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) core onew(welfppp) onel(pline215)

{p 4 4 2} 
{bf:pea table1} [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline365)

{p 4 4 2} 
{bf:pea table1} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) core onew(welfppp) onel(pline365)

{p 4 4 2} 
{bf:pea table1} [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline365)
