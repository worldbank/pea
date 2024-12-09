{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table2}{right:November 2024}
{hline}

{title:Title}

{bf:pea table2} — Generates tables of core poverty indicators

{title:Syntax}

{p 4 15}
{opt pea table2} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
  {opt NATWelfare(varname)} 
  {opt NATPovlines(varlist)}
    [{opt PPPWelfare(varname)} 
	{opt PPPPovlines(varlist)} 
	{opt FGTVARS using(string)} 
	{opt Year(varname)}
    {opt byind(varlist)} 
	{opt CORE setting(string)} 
	{opt LINESORTED} 
	{opt excel(string)} 
    {opt save(string)} 
	{opt MISSING}]{p_end}

{title:Description}

{p 4 4 2} 
{opt pea_table2} calculates and outputs core poverty indicators using various welfare variables, poverty lines, 
  and grouping options. The program processes the data by performing calculations based on FGT poverty measures,
  grouping results by year and additional specified categories, and exporting the output as an Excel file.

{title:Options}
{p 4 4 2} 
{opt NATWelfare(varname)} specifies the variable representing welfare levels in natural (non-adjusted) terms.
  
{p 4 4 2} 
{opt NATPovlines(varlist)} specifies a list of natural (non-adjusted) poverty lines for analysis.
  
{p 4 4 2} 
{opt PPPWelfare(varname)} specifies the variable for welfare levels adjusted for purchasing power parity (PPP).
  
{p 4 4 2} 
{opt PPPPovlines(varlist)} provides a list of poverty lines adjusted for PPP.
  
{p 4 4 2} 
{opt FGTVARS using(string)} allows specifying an external file to load existing FGT variables.
  
{p 4 4 2} 
{opt Year(varname)} specifies the variable representing the year of observation.
  
{p 4 4 2} 
{opt byind(varlist)} specifies one or more variables by which to group the data when calculating statistics.
 
{p 4 4 2} 
{opt CORE setting(string)} defines a core setting used for indicator processing (e.g., regional settings).
  
{p 4 4 2} 
{opt LINESORTED} ensures that poverty lines are processed in sorted order if specified.
  
{p 4 4 2} 
{opt excel(string)} specifies the file path for the Excel output. If omitted, a temporary file is created.
  
{p 4 4 2} 
{opt save(string)} provides a file path to save intermediate data.
  
{p 4 4 2} 
{opt MISSING} enables handling of missing data in categorical variables, assigning a custom label for missing values.

{title:Details}

{p 4 4 2} 
{opt pea_table2} organizes poverty statistics by calculating FGT (Foster-Greer-Thorbecke) poverty measures.When grouped by different categories, it computes the poverty rate, the number of poor, and their share within each group. The program can use either natural or PPP-adjusted welfare measures depending on the options selected.

{p 4 4 2} 
After calculating poverty indicators, {opt pea_table2} reshapes the data, labels the results, and organizes the final  output. This ensures that poverty indicators are grouped and easily interpretable.

{title:Example}

{p 4 4 2} 
To generate a poverty indicators table using national and PPP welfare variables with defined poverty lines, grouped by region and exported to an Excel file:

{p 4 4 2} 
pea_table2, NATWelfare(welfare_nat) NATPovlines(povline_nat1 povline_nat2) PPPWelfare(welfare_ppp) PPPPovlines(povline_ppp1 povline_ppp2) Year(year) byind(region) excel("output_table2.xlsx")

