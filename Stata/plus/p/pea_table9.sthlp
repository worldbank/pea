{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table9}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table9} — Generates Scorecard Vision Indicator Tables.

{title:Syntax}

{p 4 15}
{opt pea table9} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
  {opt Country(string)} 
  {opt Year(varname numeric)} 
  {opt setting(string)} 
  {opt excel(string)}
  {opt save(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table9} calculates and generates tables of vision-related indicators from the World Bank Scorecard. It extracts country-specific and region-specific indicators, including key economic and social measures, and produces an ordered table for use in reporting. The results can be exported to an Excel file.

{title:Options}
  
{p 4 4 2} 
{opt Country(string)}:
 specifies the country code for which the indicators are to be generated.
  
{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.
  
{p 4 4 2} 
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options 
(hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file.
 
{p 4 4 2} 
{opt save(string)}:
 specifies the file path for saving intermediate data.

{title:Example}

{p 4 4 2}
{bf:pea table9}, c(GNB) year(year)

