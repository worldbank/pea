{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure8}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure8} — Poverty rates by sex and age groups.

{title:Syntax}

{p 4 15}
{opt pea figure8} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[{opt ,}  	
	{opt ONEWelfare(varname numeric)}    
	{opt ONELine(varlist numeric)}  
	{opt PPPyear(integer)}
	{opt Year(varname numeric)}    
    {opt age(varname numeric)}  
    {opt male(varname numeric)}  
	{opt excel(string)}     
	{opt save(string)}     
	{opt NOOUTPUT}     
	{opt yrange(string)}
	{opt MISSING}
	{opt scheme(string)}   
	{opt palette(string)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea figure8} generates a line graph with poverty rates by different age groups by sex, for the latest or specified year in the data. This program includes plotting options such as visual adjustments.

{title:Options}

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}: specifies the name of the welfare variable (income or consumption) to compute the GINI index from.  
    
{p 4 4 2} 
{opt ONELine(varname numeric)}: Specifies the numeric variable representing the poverty line used for comparison in the analysis.
  
{p 4 4 2}  
{opt Year(varname numeric)}: specifies the variable indicating the years in the data. The last available year will be plotted.
   
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.
   
{p 4 4 2}  
{opt NOEQUALSPACING}: Optional. Adjusts year spacing on x-axis to be proportional to the distance between years. Default is that years are evenly spaced in the visualization.
    
{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)". Note that the Palma (Kuznets) ratio is shown on the second y-axis with a range from 0-10. It will always be 1/10 of the specified yrange.
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 10).

{p 4 4 2}
{opt age(varname numeric)}: Variable that defines age groups for subgroup analysis. The program automatically produces 16 age-groups.

{p 4 4 2}
{opt male(varname numeric)}: Variable defining gender for subgroup analysis.

{p 4 4 2}  
{opt scheme(string)}: Optional. Allows users to specify visual color themes for plots.
    
{p 4 4 2}  
{opt palette(string)}: Optional. Allows custom palette settings for visualizations to better highlight inequality trends.

{p 4 4 2}  
{opt excel(string)}: Optional. Allows exporting the GINI trends plot data to the specified Excel file.
    
{p 4 4 2}  
{opt save(string)}: Optional. Saves the generated plot trends as a Stata dataset or file.
    
{title:Examples}

{p 4 4 2} 

{bf: pea figure8} [aw=weight_p], onewelfare(welfare) oneline(natline) year(year) age(age) male(male)
