{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10a}{right:January 2025}
{hline}

{title:Title}  

{p 4 15}
{bf:pea figure10a} — Prosperity gap by year lines.

{title:Syntax}  

{p 4 15}  
{opt pea figure10a}  
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}] 
	[{opt ,}  
	{opt ONEWelfare(varname numeric)}  
	{opt Year(varname numeric)}  
	{opt urban(varname numeric)}  
	{opt comparability(string)}  
	{opt NOEQUALSPACING}  
	{opt YRange(string)} 
	{opt BAR}
	{opt scheme(string)}  
	{opt palette(string)}  
	{opt save(string)}  
	{opt excel(string)}]{p_end}  

{title:Description}  

{p 4 4 2}  
{opt pea figure10a} computes scatter points representing trends in poverty gaps and creates connecting visualizations across years to highlight temporal comparisons. Users can optionally group by urban/rural classifications, adjust visualization settings, or perform comparability adjustments over specified survey years.

{title:Options}  

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}:  
Specifies the variable representing the numeric welfare measure for analysis, such as income, consumption, or wealth.  

{p 4 4 2}  
{opt Year(varname numeric)}: 
Specifies the numeric variable that represents the time periods for the visualization analysis (e.g., survey years).  

{p 4 4 2}  
{opt urban(varname numeric)}: 
Specifies the urban/rural grouping variable for the analysis.  

{p 4 4 2}
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{p 4 4 2}  
{opt NOEQUALSPACING}: Adjusts year spacing on x-axis to be proportional to the distance between years. Default is that years are evenly spaced in the visualization.
 
{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)".
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 5 for this figure).

{p 4 4 2}
{opt bar}: Optional. Users can specify this option to display the figure as a bar graph instead of line graph. Warning: All selected years will be shown in the figures, regardless of whether they are comparable or not. 

{p 4 4 2}  
{opt scheme(string)}:  
Specifies the visualization scheme (e.g., `viridis`, `rainbow`, etc.).  

{p 4 4 2}  
{opt palette(string)}: 
Defines a custom color palette for visual clarity and distinction among groups or survey periods.  

{p 4 4 2}  
{opt save(string)}:  
Specifies the file path to save the processed results.  

{p 4 4 2} 
{opt excel(string)}: 
Exports visualization and calculated trends into Excel for external analysis.  

{title:Examples}  

{p 4 4 2}
{bf: pea figure10a} [aw=weight_p], year(year) onewelfare(welfppp) urban(urban) comparability(comparability)
