{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table16}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table16} — Social Protection Coverage and Adequacy.

{title:Syntax}

{p 4 15}
{opt pea table16} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
  {opt Country(string)} 
  {opt Year(varname numeric)} 
  {opt benchmark(string)} 
  {opt excel(string)}
  {opt save(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table16} generates a table showing coverage and adequacy of Social Protection and Labor programs. Data comes from the ASPIRE database. Values are shown for the PEA and peer countries. The results can be exported to an Excel file.

{title:Options}
  
{p 4 4 2} 
{opt Country(string)}:
 specifies the country code for which the indicators are to be generated.
  
{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.
  
{p 4 4 2}
{opt benchmark(string)}: list of benchmark countries (e.g. VNM IDN THA).

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file.
 
{p 4 4 2} 
{opt save(string)}:
 specifies the file path for saving intermediate data.

{title:Example}

{p 4 4 2}
{bf:pea table16}, c(PHL) year(year) benchmark(VNM IDN THA)

