{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table8}{right:November 2024}
{hline}

{title:Title}

{bf:pea table8} — Generates tables of poverty dynamics measures

{title:Syntax}

{p 4 15}
{cmd:pea table8}
[{it:weight}] 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:exp}] 
[{cmd:,} 
{opt Welfare(varname numeric)} 
{opt Povlines(varname numeric)} 
{opt Year(varname numeric)} 
[{opt CORE setting(string)} 
{opt excel(string)} 
{opt save(string)} 
{opt MISSING}]{p_end}


{p 4 4 2}The command supports {cmd:aweight}s, {cmd:fweight}s, and {cmd:pweight}s. See {help weights} for further details.{p_end}


{title:Description}

{p 4 4 2}
  {cmd:pea_table8} calculates and outputs poverty dynamics measures based on welfare variables and poverty lines. Specifically,
  the program generates indicators related to poverty transitions across years, including the share of individuals moving in and out of poverty 
  over time. It also provides the option to export the results to Excel.

{title:Options}
  {phang} {opt Welfare(varname numeric)} specifies the welfare variable to be used for poverty dynamics calculations.
  
  {phang} {opt Povlines(varname numeric)} specifies the variable for the poverty lines to be used in calculations.
 
  {phang} {opt Year(varname numeric)} specifies the year variable for the analysis.
  
  {phang} {opt CORE setting(string)} allows the use of custom settings for the analysis (e.g., regional specifications).
  
  {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, the results are saved to a temporary file.
  
  {phang} {opt save(string)} specifies the file path for saving intermediate data.
  
  {phang} {opt MISSING} enables the handling of missing data, allowing for custom handling of categorical variables.

{title:Details}

{p 4 4 2}
  {cmd:pea_table8} computes poverty dynamics indicators, which include:
  
	  - The share of individuals who were poor in the previous period and remain poor (poverty persistence)
	  
	  - The share of individuals who were not poor in the previous period but are poor in the current period (poverty entry)
	  
	  - The share of individuals who were poor in the previous period but are no longer poor in the current period (poverty exit)

  The program uses the welfare and poverty lines specified by the user, and computes these indicators for each year in the data. 
  The results are then formatted and organized, and an Excel file can be generated if the `excel` option is provided. The output
  contains the calculated poverty dynamics measures along with the relevant years and summary statistics.

{title:Example}

{p 4 4 2}
  To generate a poverty dynamics table for a specific welfare variable, poverty line, and year, and export the results
  to an Excel file:

{p 4 4 2}  
{cmd:. pea_table8, Welfare(welfare_var) Povlines(povline_var) Year(year) excel("output_table8.xlsx")}
