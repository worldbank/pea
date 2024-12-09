{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table7}{right:November 2024}
{hline}

{title:Title}

{bf:pea table7} — Generates tables of vulnerability to poverty measures

{title:Syntax}

{p 4 15}
{opt pea table7} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,}  
{opt Welfare(varname numeric)} 
{opt Povlines(varname numeric)}
{opt Year(varname numeric)} 
[{opt CORE setting(string)}
{opt excel(string)}
{opt save(string)}
{opt MISSING}]{p_end}

{title:Description}

{p 4 4 2}  
{opt pea_table7} calculates and outputs vulnerability to poverty measures based on welfare variables and poverty lines. Specifically,
the program generates indicators of vulnerability based on being below 1.5 and 2 times the poverty line, calculated for different
years. It also provides the option to export the results to Excel.

{title:Options}
 
{p 4 4 2} 
{opt Welfare(varname numeric)} specifies the welfare variable to be used for vulnerability calculations.
  
{p 4 4 2} 
{opt Povlines(varname numeric)} specifies the variable for the poverty lines to be used in calculations.
 
{p 4 4 2} 
{opt Year(varname numeric)} specifies the year variable for the analysis.
 
{p 4 4 2} 
{opt CORE setting(string)} allows the use of custom settings for the analysis (e.g., regional specifications).
 
{p 4 4 2} 
{opt excel(string)} specifies the file path for exporting results to Excel. If omitted, the results are saved to a temporary file.
 
{p 4 4 2} 
{opt save(string)} specifies the file path for saving intermediate data.
 
{p 4 4 2} 
{opt MISSING} enables the handling of missing data, allowing for custom handling of categorical variables.

{title:Details}

{p 4 4 2}  
{opt pea_table7} computes two vulnerability to poverty indicators:
 
	  - The share of the population below 1.5 times the poverty line (vulpovl15)
	  - The share of the population below 2 times the poverty line (vulpov2)

{p 4 4 2}  
The program uses the welfare and poverty lines specified by the user, and computes these indicators for each year in the data. 
The results are then formatted and organized, and an Excel file can be generated if the `excel` option is provided. The output
contains the calculated vulnerability to poverty measures along with the relevant years and summary statistics.

{title:Example}

{p 4 4 2}  
To generate a vulnerability to poverty table for a specific welfare variable, poverty line, and year, and export the results to an Excel file:  

{p 4 4 2}    
pea_table7, Welfare(welfare_var) Povlines(povline_var) Year(year) excel("output_table7.xlsx")

