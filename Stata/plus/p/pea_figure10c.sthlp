{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10c}{right:January 2025}
{hline}

{title:Title}  

{p 4 15}
{bf:pea figure10c} — Generate scatter plot comparing prosperity gaps (PG) and GDP per capita.  

{title:Syntax}  

{p 4 15}  
{opt pea figure10c}  
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
    {opt excel(string)}  
    {opt within(integer)}]{p_end}  

{title:Description}  

{p 4 4 2}  
{opt pea figure10c} generates a scatter plot comparing the survey-based prosperity gap (PG) with GDP per capita for a given country. The comparison includes the closest available survey year within a user-specified range and allows users to specify benchmark countries and visualization options.  

{title:Options} 
 
{p 4 4 2}  
{opt Country(string)}: specifies the PEA country of interest for the scatter analysis.  

{p 4 4 2}  
{opt Year(varname numeric)}: specifies the year variable for the analysis.  

{p 4 4 2}  
{opt BENCHmark(string)}: is a list of benchmark countries for comparison (e.g., "India, Bhutan").  

{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)".
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 5 for this figure).

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}: is the variable containing the prosperity gap calculations.  

{p 4 4 2}  
{opt scheme(string)}: defines the plotting color scheme.  

{p 4 4 2}  
{opt palette(string)}: specifies the visualization's color palette.  

{p 4 4 2}  
{opt save(string)}: specifies the file path to save the resulting visualization.  

{p 4 4 2}  
{opt excel(string)}: specifies the file path to export visualization-related results to Excel.  

{p 4 4 2}  
{opt within(integer)}: specifies the number of years to search for the survey overlap within the range of survey years (default is 3).  

{title:Examples}  

{p 4 4 2}
{bf: pea figure10c} [aw=weight_p], c(GNB) year(year) benchmark(CIV GHA GMB SEN) onewelfare(welfppp) yrange(0(5)25)
