{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_table8}
{hline 80}
{title:Title}
  {bf pea_table8} — Generates tables of poverty dynamics measures

{title:Syntax}
  {cmd:pea_table8} [{it:if}] [{it:in}] [{it:aw} {cmd:pw} {cmd:fw}], {cmdab:Welfare(varname numeric)} {cmdab:Povlines(varname numeric)} {cmdab:Year(varname numeric)} 
    [{cmdab:CORE setting(string)} {cmdab:excel(string)} {cmdab:save(string)} {cmdab:MISSING}]

{title:Description}
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
  {cmd:pea_table8} computes poverty dynamics indicators, which include:
  - The share of individuals who were poor in the previous period and remain poor (poverty persistence)
  
  - The share of individuals who were not poor in the previous period but are poor in the current period (poverty entry)
  
  - The share of individuals who were poor in the previous period but are no longer poor in the current period (poverty exit)

  The program uses the welfare and poverty lines specified by the user, and computes these indicators for each year in the data. 
  The results are then formatted and organized, and an Excel file can be generated if the `excel` option is provided. The output
  contains the calculated poverty dynamics measures along with the relevant years and summary statistics.

{title:Example}
  To generate a poverty dynamics table for a specific welfare variable, poverty line, and year, and export the results
  to an Excel file:

{cmd:. pea_table8, Welfare(welfare_var) Povlines(povline_var) Year(year) excel("output_table8.xlsx")}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  {help pea_table7}: To generate vulnerability to poverty tables.
{hline 80}
