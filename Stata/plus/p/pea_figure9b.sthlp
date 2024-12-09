{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure9b}{right:November 2024}
{hline}

{title:Title}

{bf:pea_figure9b} — Generate poverty and welfare analysis figures with specified parameters.

{title:Syntax}

{p 4 15}
{opt pea_figure9b}
[{it:weight}]
[{opt if} {it:exp}]
[{opt in} {it:exp}]
[{opt ,}
{opt Country(string)}
{opt NATWelfare(varname)}
{opt NATPovlines(varlist)}
{opt PPPWelfare(varname)}
{opt PPPPovlines(varlist)}
{opt FGTVARS}
[{opt using} {it:string}]
{opt Year(varname)}
{opt CORE}
{opt setting(string)}
{opt LINESORTED}
{opt excel(string)}
{opt save(string)}
{opt ONELine(varname)}
{opt ONEWelfare(varname)}]{p_end}

{p 4 4 2}
The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}

{title:Description}

{p 4 4 2}
{opt pea_figure9b} generates figures for poverty and welfare analysis based on specified national and international poverty lines and welfare measures. It offers insights into income distribution, poverty incidence, and other related welfare statistics across groups and time periods.

{title:Options}
{p 4 4 2}  {opt Country(string)} specifies the country code or name for the analysis.

{p 4 4 2}  {opt NATWelfare(varname)} identifies the variable containing welfare values for national analysis.  

{p 4 4 2}  {opt NATPovlines(varlist)} lists the national poverty lines for analysis.  

{p 4 4 2}  {opt PPPWelfare(varname)} is the welfare variable adjusted for purchasing power parity (PPP).  

{p 4 4 2}  {opt PPPPovlines(varlist)} lists PPP-adjusted poverty lines.  

{p 4 4 2}  {opt FGTVARS} generates the Foster-Greer-Thorbecke (FGT) poverty indices (headcount, gap, severity).  

{p 4 4 2}  {opt using(string)} specifies the dataset to be used for the analysis.  

{p 4 4 2}  {opt Year(varname)} is the variable specifying the year for each observation.  

{p 4 4 2}  {opt CORE} enables World Bank's Multidimensional Poverty Measure (MPM) calculations for the provided year and country.  

{p 4 4 2}  {opt setting(string)} defines the MPM calculation's specific settings.  

{p 4 4 2}  {opt LINESORTED} indicates that poverty lines are pre-sorted, skipping internal sorting.  

{p 4 4 2}  {opt excel(string)} specifies the path to save results in Excel format.  

{p 4 4 2}  {opt save(string)} specifies a path to save the results in Stata format.  

{p 4 4 2}  {opt ONELine(varname)} identifies a specific poverty line variable for additional poverty analysis.  

{p 4 4 2}  {opt ONEWelfare(varname)} sets a welfare variable associated with the {opt ONELine} poverty line.  

{title:Remarks}

{pstd} The {opt pea_figure9b} command performs data checks, transformations, and statistical calculations to generate comprehensive figures summarizing poverty and welfare statistics.

{pstd} Output includes poverty incidence statistics, inequality indices (Gini, Theil, etc.), welfare statistics, and poverty gaps across different population segments and years.

{title:Examples}

