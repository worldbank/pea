{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_table6}
{hline 80}
{title:Title}
  {bf pea_table6} — Generates tables of multidimensional poverty measures

{title:Syntax}
  {cmd:pea_table6} [{it:if}] [{it:in}] [{it:aw} {cmd:pw} {cmd:fw}], {cmdab:Country(string)} {cmdab:Welfare(varname)} {cmdab:Year(varname)} 
    [{cmdab:setting(string)} {cmdab:excel(string)} {cmdab:save(string)} {cmdab:MISSING} {cmdab:BENCHmark(string)} {cmdab:ALL} {cmdab:LAST3}]

{title:Description}
  {cmd:pea_table6} calculates and outputs multidimensional poverty measures, including various poverty indicators. The program
  processes data using welfare variables and poverty lines, calculates the poverty index, and generates output tables. Additionally, 
  it can export the results to an Excel file.

{title:Options}
  {phang} {opt Country(string)} specifies the country for the analysis.
  
  {phang} {opt Welfare(varname)} specifies the welfare variable to be used for poverty calculations.
 
  {phang} {opt Year(varname)} specifies the variable for the year of observation.
 
  {phang} {opt setting(string)} specifies any regional or custom settings to apply to the analysis.
 
  {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, results are stored in a temporary file.
 
  {phang} {opt save(string)} specifies the path to save intermediate data.

  {phang} {opt MISSING} enables handling of missing data in categorical variables, allowing custom labels for missing values.

  {phang} {opt BENCHmark(string)} defines the benchmark level for comparison.

  {phang} {opt ALL} includes all observations without grouping.

  {phang} {opt LAST3} limits the analysis to the last three years of data.

{title:Details}
  {cmd:pea_table6} calculates multidimensional poverty indicators using a combination of welfare variables and poverty lines.
  It outputs results by region, year, or other specified groupings. The results include various poverty measures, such as poverty
  rate, number of poor, and their share within each group. The program reshapes and organizes the final output for easy interpretation.

  If the `excel` option is provided, the results will be exported to an Excel file. The table will include separate sheets for each 
  indicator, and a summary of the key statistics for poverty measures will be added as well.

{title:Example}
  To generate a multidimensional poverty table for a specific country, including welfare variables, year, and exporting results
  to an Excel file:
{cmd:. pea_table6, Country("CountryName") Welfare(welfare_var) Year(year) excel("output_table6.xlsx")}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  {help pea_table5}: To generate additional poverty-related tables.
{hline 80}

