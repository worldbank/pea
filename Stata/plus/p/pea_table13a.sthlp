{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table13a}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table13a} — Decomposition of poverty changes: Huppi-Ravallion decomposition (urban/rural)

{title:Syntax}

{p 4 15}
{opt pea table13a} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,}
{opt NATWelfare(varname numeric)} 
{opt NATPovlines(varlist numeric)} 
{opt PPPWelfare(varname numeric)} 
{opt PPPPovlines(varlist numeric)} 
{opt PPPyear(integer)}
{opt urban(varname numeric)}
{opt spells(string)} 
{opt Year(varname numeric)} 
{opt LINESORTED} 
{opt NOOUTPUT} 
{opt excel(string)} 
{opt save(string)} 
{opt MISSING} 
{opt GRAPH}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table13a} calculates and generates tables for the decomposition of poverty changes based on income and non-income factors. 
Poverty changes are disaggregated into urban, rural and population shift components, as well as their interactions.

{title:Options}

{p 4 4 2}
{opt NATWelfare(varname numeric)}:
 specifies the variable representing the welfare indicator (e.g., income or consumption).
  
{p 4 4 2}
{opt NATPovlines(varlist numeric)}:
 specifies the list of national poverty lines to be used in the analysis.
  
{p 4 4 2}
{opt PPPWelfare(varname numeric)}:
 specifies the variable for welfare under PPP adjustments.

{p 4 4 2}
{opt PPPPovlines(varlist numeric)}: 
 specifies the list of PPP-adjusted poverty lines.

{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2}
{opt spells(string)}:
 specifies the periods (spells) over which the decomposition should be performed, e.g., "2000;2004".

{p 4 4 2}
{opt Year(varname numeric)}:
 specifies the variable representing the year for the analysis.

{p 4 4 2}
{opt urban(varname numeric)}: Urban/Rural classification variable for subgroup analysis.

{p 4 4 2}
{opt LINESORTED}:
 orders the poverty lines before decomposition.
 
{p 4 4 2}
{opt NOOUTPUT}:
 suppresses output to the screen.

{p 4 4 2}
{opt excel(string)}:
 specifies the file path for exporting results to an Excel file.

{p 4 4 2}
{opt save(string)}:
 specifies the file path for saving intermediate data.

{p 4 4 2}
{opt MISSING}:
 includes missing data in the analysis.

{p 4 4 2}
{opt GRAPH}:
 generates a graphical representation of the results.

{title:Example}

{p 4 4 2}
{bf:pea table13a} [aw=weight_p], natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) urban(urban)
