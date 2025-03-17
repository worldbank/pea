{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure4}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure4} — Poverty Decomposition with Datt-Ravallion and Shorrocks-Kolenikov Methods.

{title:Syntax}

{p 4 15}
{opt pea figure4} 
	[{it:if}]
	[{it:in}] 
	[{it:aw pw fw}], 
    [{opt onewelfare(varname numeric)} 
    {opt oneline(varname numeric)}  
    {opt spells(string)} 
    {opt year(varname numeric)} 
	{opt PPPyear(integer)}
	{opt LINESORTED(string)}
	{opt comparability(varname numeric)}
	{opt idpl(varname numeric)}
	{opt setting(string)} 
    {opt save(string)}
    {opt excel(string)}
	{opt scheme(string)}
	{opt palette(string)}]{p_end}  

{title:Description}

{p 4 4 2}
{opt pea figure4} performs poverty decomposition over time using the Datt-Ravallion and Shorrocks-Kolenikov methods. The program generates visualizations and numerical results showing the contribution of changes in income or welfare across different 
time periods or population groups. The results can help analysts and policymakers identify the drivers behind changes in poverty.

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
{opt LINESORTED(string)}:
Allows users to sort lines based on a specific setting for better visualization clarity.

{p 4 4 2}
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{p 4 4 2}
{opt idpl(varname numeric)}: Optional. If national poverty lines are different within one year, specify the variable grouping the poverty lines here. This is relevant for the Shorrocks-Kolenikov decomposition. Example: idpl(urban).

{p 4 4 2}
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options (hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 

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
{bf: pea figure4} [aw=weight_p], year(year) onew(welfare) onel(natline) palette(viridis) spells(2018 2021)

