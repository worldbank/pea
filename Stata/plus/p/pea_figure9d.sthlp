{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure9d}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure9d} — Welfare percentiles by year, with optional comparability adjustments.

{title:Syntax}

{p 4 15}
{opt pea figure9d} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[{opt ,}  	
	{opt ONEWelfare(varname numeric)}    
	{opt PPPyear(integer)}
	{opt Year(varname numeric)}    
	{opt comparability(string)}     
	{opt excel(string)}     
	{opt save(string)}     
	{opt NOEQUALSPACING}   
	{opt yrange(string)}
	{opt BAR}
	{opt MISSING}
	{opt scheme(string)}   
	{opt palette(string)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea figure9d} generates percentile plots (10th, 25th, 50th, 75th, 90th) over time .
These plots visualize trends in inequality and allow comparisons over time. This program includes options for comparability adjustments, Excel exports, and plotting options such as visual adjustments. The y-axis label is taken from the specified welfare variable label.

{title:Options}

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}: specifies the name of the welfare aggregate variable to compute the percentiles from. Make sure that this variable has a concise label, as the label is used for the figure note.  
      
{p 4 4 2}  
{opt Year(varname numeric)}: specifies the variable indicating the years across which trends will be plotted.
   
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.
   
{p 4 4 2}
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).
    
{p 4 4 2}  
{opt NOEQUALSPACING}: Optional. Adjusts year spacing on x-axis to be proportional to the distance between years. Default is that years are evenly spaced in the visualization.
    
{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)". Note that the Palma (Kuznets) ratio is shown on the second y-axis with a range from 0-10. It will always be 1/10 of the specified yrange.
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 10).

{p 4 4 2}
{opt bar}: Optional. Users can specify this option to display the figure as a bar graph instead of line graph. Note that bar graphs only allow for one y-axis, so the Palma (Kuznets) ratio is multiplied by 10 for visibility. Warning: All selected years will be shown in the figures, regardless of whether they are comparable or not.
	
{p 4 4 2}  
{opt scheme(string)}: Optional. Allows users to specify visual color themes for plots.
    
{p 4 4 2}  
{opt palette(string)}: Optional. Allows custom palette settings for visualizations to better highlight inequality trends.

{p 4 4 2}  
{opt excel(string)}: Optional. Allows exporting the percentiles trends plot data to the specified Excel file.
    
{p 4 4 2}  
{opt save(string)}: Optional. Saves the generated plot trends as a Stata dataset or file.
    
{title:Examples}

{p 4 4 2} 

{bf: pea figure9d} [aw=weight_p], year(year) onewelfare(welfare) comparability(comparability)  
