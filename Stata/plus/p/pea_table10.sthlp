{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table10} — Benchmarking of poverty and inequality.

{title:Syntax}

{p 4 15}
{opt  pea table10}
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
{opt Country(string)}
{opt Welfare(varname numeric)} 
{opt Povlines(varlist numeric)}
{opt PPPyear(integer)}
{opt Year(varname numeric)} 
{opt BENCHmark(string)}
{opt LINESORTED}
{opt excel(string)} 
{opt save(string)} 
{opt FGTVARS}
{opt LATEST} 
{opt WITHIN3}]

{title:Description}

{p 4 4 2}
{opt pea table10} Table comparing welfare with various poverty lines across benchmark countries, with options to include or exclude countries within 3 years.
Results can be exported to Excel or saved in a specified file format.

{title:Options}

{p 4 4 2} 
{opt Country(string)}:
 specifies the country code for which the poverty indicators are to be generated.
 
{p 4 4 2} 
{opt Welfare(varname numeric)}:
 specifies the welfare variable to be used for poverty calculations.
 
{p 4 4 2}  
{opt Povlines(varlist numeric)}:
 provides a list of poverty lines adjusted for PPP.
 
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.

{p 4 4 2}
{opt BENCHmark(string)}: specifies a list of benchmark countries (e.g., ALB HRV XKX).

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
{opt FGTVARS using(string)}:
 allows specifying an external file to load existing FGT variables.

{p 4 4 2}
{opt LATEST}: includes only the most recent available data.

{p 4 4 2}
{opt WITHIN3}: limits analysis to data from countries within 3 years of the target year.

{title:Examples}

{p 4 4 2}
{bf:pea table10} [aw=weight_p], c(ARM) welfare(welfppp) povlines(pline365 pline215 pline685) year(year) benchmark(ALB HRV XKX) latest
//not running if there is no countries within 3 years

{p 4 4 2}
{bf:pea table10} [aw=weight_p], c(ARM) welfare(welfppp) povlines(pline365 pline215 pline685) year(year) benchmark(ALB HRV XKX) within3

