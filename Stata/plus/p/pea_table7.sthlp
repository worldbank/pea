{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table7}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table7} — Generates tables of vulnerability to poverty measures.

{title:Syntax}

{p 4 15}
{opt pea table7} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,}  
{opt Welfare(varname numeric numeric)} 
{opt Povlines(varname numeric numeric)}
{opt Year(varname numeric numeric)} 
[{opt CORE setting(string)}
{opt excel(string)}
{opt save(string)}
{opt MISSING}]{p_end}

{title:Description}

{p 4 4 2}   
{opt pea_table7} computes two vulnerability to poverty indicators:
 
	  - The share of the population below 1.5 times the poverty line (vulpovl15)
	  - The share of the population below 2 times the poverty line (vulpov2)

{p 4 4 2}  
The program uses the welfare and poverty lines specified by the user, and computes these indicators for each year in the data. 
The results are then formatted and organized, and an Excel file can be generated if the `excel` option is provided. The output
contains the calculated vulnerability to poverty measures along with the relevant years and summary statistics.


{title:Options}
 
{p 4 4 2} 
{opt Welfare(varname numeric numeric)}:
 specifies the welfare variable to be used for vulnerability calculations.
  
{p 4 4 2} 
{opt Povlines(varname numeric numeric)}:
 specifies the variable for the poverty lines to be used in calculations.
 
{p 4 4 2} 
{opt Year(varname numeric numeric)}:
 specifies the year variable for the analysis.
 
{p 4 4 2} 
{opt CORE setting(string)}:
 allows the use of custom settings for the analysis (e.g., regional specifications).
 
{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for exporting results to Excel. If omitted, the results are saved to a temporary file.
 
{p 4 4 2} 
{opt save(string)}:
 specifies the file path for saving intermediate data.
 
{p 4 4 2} 
{opt MISSING}:
 enables the handling of missing data, allowing for custom handling of categorical variables.

{title:Example}

{p 4 4 2}    
{bf:pea_table7} [aw=weight_p], welfare(welfppp) povlines(pline365) year(year) 

