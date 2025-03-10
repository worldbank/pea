{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10d}{right:January 2025}
{hline}

{title:Title}  

{p 4 15}
{bf:pea figure10d} — Prosperity gap against benchmark countries (line-up).

{title:Syntax}  

{p 4 15}  
{opt pea figure10d}  
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}] 
	[{opt ,}  
	{opt Country(string)}  
    {opt Year(varname numeric)}  
    {opt BENCHmark(string)} 
	{opt YRange(string)} 
	{opt ONEWelfare(varname numeric)}  
	{opt scheme(string)}  
	{opt palette(string)}  
	{opt save(string)}  
	{opt excel(string)}]{p_end}  

{title:Description}  

{p 4 4 2}  
{opt pea figure10d} computes a line graph showing lined-up estimates of the prosperity gap over time for the country of analysis and benchmark countries. For the PEA survey year, the prosperity gap from the survey is taken. The time-frame is always 20 years prior to the PEA survey in the data. in poverty gaps and creates connecting visualizations across years to highlight temporal comparisons. Users can adjust visualization settings.

{title:Options}  

{p 4 4 2}  
{opt Country(string)}: specifies the PEA country of interest for the scatter analysis.  

{p 4 4 2}  
{opt Year(varname numeric)}: specifies the year variable for the analysis.  

{p 4 4 2}  
{opt BENCHmark(string)}: is a list of benchmark countries for comparison (e.g., "India, Bhutan").  

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}:  
Specifies the variable representing the numeric welfare measure for analysis, such as income, consumption, or wealth.  

{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)".
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 5 for this figure).

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
{bf: pea figure10d} [aw=weight_p], c(GNB) year(year) onew(welfppp) benchmark(CIV GHA GMB SEN AGA) yrange(0(5)25)
