{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure5b}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure5b} — Decomposition of poverty changes: growth and redistribution: Huppi-Ravallion (sectoral)

{title:Syntax}

{p 4 15}
{opt pea figure5b} 
	[{it:if}]
	[{it:in}] 
	[{it:aw pw fw}], 
    [{opt onewelfare(varname numeric)} 
    {opt oneline(varname numeric)}  
    {opt spells(string)} 
    {opt year(varname numeric)} 
	{opt PPPyear(integer)}
	{opt industrycat4(varname numeric)}
	{opt hhhead(varname numeric)}
	{opt hhid(string)}
	{opt LINESORTED(string)}
	{opt comparability(varname numeric)}
    {opt save(string)}
    {opt excel(string)}
	{opt scheme(string)}
	{opt palette(string)}]{p_end}  


{title:Description}

{p 4 4 2}
{opt pea figure5b} performs poverty decomposition over time using the Huppi-Ravallion method. 
The program generates visualizations and numerical results showing the contribution of changes in income or welfare across different time periods and sectors. The results can help analysts and policymakers identify the drivers behind changes in poverty. All individuals are assigned the sector of their household head.

{title:Options}

{p 4 4 2} 
{opt onewelfare(varname numeric)}: Specifies the numeric variable representing welfare (e.g., income or consumption) for poverty analysis. 

{p 4 4 2} 
{opt oneline(varname numeric)}: Specifies the numeric variable representing the poverty line used for comparison in the analysis.
  
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt spells(string)}: Defines time periods (spells) to perform the decomposition. Use pairs of years separated by a space, with multiple spells separated by semicolons (e.g., "2000 2005; 2005 2010").  

{p 4 4 2} 
{opt year(varname numeric)}: Specifies the numeric variable representing the year for time association in the analysis.

{p 4 4 2}
{opt industrycat4(varname numeric)}: Specifies the industry category variable. If it contains only missing values for a year that is requested, the code will not compile.

{p 4 4 2} 
{opt hhhead(varname numeric)}:
 specifies the variable indicating household head status (typically 1 for head, 0 for non-head).

{p 4 4 2} 
{opt hhid(string)}:
 specifies the variable indicating the household id. 
 This is needed to assign the household head sector to other household members.
 
{p 4 4 2} 
{opt LINESORTED(string)}:
Allows users to sort lines based on a specific setting for better visualization clarity.

{p 4 4 2}
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{p 4 4 2} 
{opt save(string)} Specifies the file path for saving the processed data or results from the decomposition analysis. 

{p 4 4 2} 
{opt excel(string)} Specifies the file path for exporting results to an Excel file for further analysis or visualization purposes.  

{p 4 4 2} 
{opt  scheme(string)}:
Allows users to define a specific visualization color scheme.

{p 4 4 2} 
{opt  palette(string)}:
Specifies a custom color palette for use in visualizations.

{title:Examples}

{p 4 4 2} 
{bf: pea figure5b} [aw=weight_p], year(year) onew(welfare) onel(natline) palette(viridis) spells(2018 2021) industrycat4(industrycat4) hhhead(head) hhid(hhid)
