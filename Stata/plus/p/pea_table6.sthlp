{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table6}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table6} — Generates tables of multidimensional poverty measures. 

{title:Syntax}

{p 4 15}
{opt pea table6} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,}  
  {opt Country(string)} 
  {opt Welfare(varname numeric)} 
  {opt PPPyear(integer)}
  {opt Year(varname numeric)} 
  {opt setting(string)} 
  {opt excel(string)}
  {opt save(string)} 
  {opt MISSING}
  {opt BENCHmark(string)} 
  {opt ALL}
  {opt LAST3}]{p_end}


{p 4 4 2}
The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}

{title:Description}

{p 4 4 2}
{opt pea table6} calculates and outputs mltidimensional poverty measure (MPM) for the PEA and benchmark countries, and
 the Components of the MPM separately (6 variables).

{title:Options}

{p 4 4 2} 
{opt Country(string)}:
 specifies the country for the analysis.
  
{p 4 4 2} 
{opt Welfare(varname numeric)}:
 specifies the welfare variable to be used for poverty calculations.
 
{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the variable for the year of observation.
 
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options 
(hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 
 
{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for exporting results to Excel. If omitted, results are stored in a temporary file.
 
{p 4 4 2} 
{opt save(string)}:
 specifies the path to save intermediate data.

{p 4 4 2} 
{opt MISSING}:
 enables handling of missing data in categorical variables, allowing custom labels for missing values.

{p 4 4 2} 
{opt BENCHmark(string)}:
 defines the benchmark level for comparison.

{p 4 4 2} 
{opt ALL}:
 includes all observations without grouping.

{p 4 4 2} 
{opt LAST3}:
 limits the analysis to the last three years of data.

{title:Example}

{p 4 4 2}  
To generate a multidimensional poverty table for a specific country, including welfare variables, year, and exporting results
to an Excel file:

{p 4 4 2}  
pea table6 [aw=weight_p], c(ARM) welfare(welfppp) year(year)  benchmark(ALB HRV XKX) setting(GMD) last3

