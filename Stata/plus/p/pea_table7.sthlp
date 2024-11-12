{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_table7}
{hline 80}
{title:Title}
  {bf pea_table7} — Generates tables of vulnerability to poverty measures

{title:Syntax}
  {cmd:pea_table7} [{it:if}] [{it:in}] [{it:aw} {cmd:pw} {cmd:fw}], {cmdab:Welfare(varname numeric)} {cmdab:Povlines(varname numeric)} {cmdab:Year(varname numeric)} 
    [{cmdab:CORE setting(string)} {cmdab:excel(string)} {cmdab:save(string)} {cmdab:MISSING}]

{title:Description}
  {cmd:pea_table7} calculates and outputs vulnerability to poverty measures based on welfare variables and poverty lines. Specifically,
  the program generates indicators of vulnerability based on being below 1.5 and 2 times the poverty line, calculated for different
  years. It also provides the option to export the results to Excel.

{title:Options}
  {phang} {opt Welfare(varname numeric)} specifies the welfare variable to be used for vulnerability calculations.
  {phang} {opt Povlines(varname numeric)} specifies the variable for the poverty lines to be used in calculations.
  {phang} {opt Year(varname numeric)} specifies the year variable for the analysis.
  {phang} {opt CORE setting(string)} allows the use of custom settings for the analysis (e.g., regional specifications).
  {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, the results are saved to a temporary file.
  {phang} {opt save(string)} specifies the file path for saving intermediate data.
  {phang} {opt MISSING} enables the handling of missing data, allowing for custom handling of categorical variables.

{title:Details}
  {cmd:pea_table7} computes two vulnerability to poverty indicators:
  - The share of the population below 1.5 times the poverty line (vulpovl15)
  - The share of the population below 2 times the poverty line (vulpov2)

  The program uses the welfare and poverty lines specified by the user, and computes these indicators for each year in the data. 
  The results are then formatted and organized, and an Excel file can be generated if the `excel` option is provided. The output
  contains the calculated vulnerability to poverty measures along with the relevant years and summary statistics.

{title:Example}
  To generate a vulnerability to poverty table for a specific welfare variable, poverty line, and year, and export the results
  to an Excel file:
{cmd:. pea_table7, Welfare(welfare_var) Povlines(povline_var) Year(year) excel("output_table7.xlsx")}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  {help pea_table6}: To generate additional poverty-related tables.
{hline 80}
