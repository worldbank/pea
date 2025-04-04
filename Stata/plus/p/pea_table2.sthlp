{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table2}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table2} — Poverty rate and share of poor by area and admin1 regions.

{title:Syntax}

{p 4 15}
{opt pea table2} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
  {opt NATWelfare(varname numeric)} 
  {opt NATPovlines(varlist numeric)}
    {opt PPPWelfare(varname numeric)} 
	{opt PPPPovlines(varlist numeric)} 
	{opt PPPyear(integer)}
	{opt FGTVARS} 
	{using(string)} 
	{opt using(string)}
	{opt Year(varname numeric)}
    {opt byind(varlist numeric)} 
	{opt LINESORTED} 
	{opt excel(string)} 
    {opt save(string)} 
	{opt MISSING}
	{opt minobs(numlist)}]{p_end}

{title:Description}

{p 4 4 2} 
{opt pea table2} calculates poverty rate and share of poor by area and admin1 regions. Indicators include: poverty rates, share of poor, and number of poor disaggregated by urban and rural regions, as well as admin1 regions (both at international and national poverty lines).

{title:Options}

{p 4 4 2} 
{opt NATWelfare(varname numeric)}:
 specifies the variable representing welfare levels in natural (non-adjusted) terms.
  
{p 4 4 2} 
{opt NATPovlines(varlist numeric)}:
 specifies a list of natural (non-adjusted) poverty lines for analysis.
  
{p 4 4 2} 
{opt PPPWelfare(varname numeric)}:
 specifies the variable for welfare levels adjusted for purchasing power parity (PPP).
  
{p 4 4 2} 
{opt PPPPovlines(varlist numeric)}:
 provides a list of poverty lines adjusted for PPP.
  
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt FGTVARS using(string)}:
 allows specifying an external file to load existing FGT variables.

{p 4 4 2} 
{opt using(string)}:
 specifies the dataset to use; the dataset will be loaded if provided.
 
{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the variable representing the year of observation.
  
{p 4 4 2} 
{opt byind(varlist)}:
 specifies one or more variables by which to group the data when calculating statistics.


 {p 4 4 2}
{opt minobs(numlist)}: specifies the minimum number of observations required to display a cell value.

{p 4 4 2} 
{opt LINESORTED}:
 ensures that poverty lines are processed in sorted order if specified.
  
{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for the Excel output. If omitted, a temporary file is created.
  
{p 4 4 2} 
{opt save(string)}:
 provides a file path to save intermediate data.
  
{p 4 4 2} 
{opt MISSING}:
 enables handling of missing data in categorical variables, assigning a custom label for missing values.

{title:Details}

{p 4 4 2} 
{opt pea table2} organizes poverty statistics by calculating FGT (Foster-Greer-Thorbecke) poverty measures.When grouped by different categories, it computes the poverty rate, the number of poor, and their share within each group. The program can use either natural or PPP-adjusted welfare measures depending on the options selected.

{p 4 4 2} 
After calculating poverty indicators, {opt pea table2} reshapes the data, labels the results, and organizes the final  output. This ensures that poverty indicators are grouped and easily interpretable.

{title:Example}

{p 4 4 2} 
To generate a poverty indicators table using national and PPP welfare variables with defined poverty lines, grouped by region and exported to an Excel file:

{p 4 4 2} 
{bf:pea table2} [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) minobs(100)

