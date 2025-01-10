{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure9b}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure9b} —  GINI and GDP per capita scatter.

{title:Syntax}

{p 4 15}
{opt pea figure9b}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[{opt ,}
	{opt Country(string)}
	{opt Year(varname numeric)}   
	{opt BENCHmark(string)} 
	{opt ONEWelfare(varname numeric)}    
	{opt within(integer 3)}  
	{opt NONOTES} 
	{opt scheme(string)} 
	{opt palette(string)} 
	{opt save(string)} 
	{opt excel(string)} 
	{opt welfaretype(string)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea figure9b} generates GINI and GDP per capita scatter. Shows inequality against other countries in the same region.

{title:Options}

{p 4 4 2}  
{opt Country(string)}: specifies the country code or name for the analysis.

{p 4 4 2}  
{opt Year(varname numeric)}: variable specifying the year for each observation.  

{p 4 4 2} 
{opt BENCHmark(string)}: list of benchmark countries to be included in the analysis.

{p 4 4 2} 
{opt ONEWelfare(varname numeric)}: specifies the one-line welfare variable.

{p 4 4 2} 
{opt within(integer)}: specifies the number of years to search for the survey overlap within the range of survey years (default is 3).  
 
{p 4 4 2}  
{opt NONOTES}: suppresses generated notes related to data visualization. 

{p 4 4 2}  
{opt scheme(string)}: allows users to specify visual color themes for plots.
    
{p 4 4 2}  
{opt palette(string)}: allows custom palette settings for visualizations to better highlight inequality trends.
 
{p 4 4 2}  
{opt excel(string)}: specifies the path to save results in Excel format.  

{p 4 4 2}  
{opt save(string)}: specifies a path to save the results in Stata format.  

{p 4 4 2} 
{opt welfaretype(string)}: Optional. Can be used to specify whether the survey uses income (INC) or consumption (CONS) to calculate welfare. 

{title:Examples}

{p 4 4 2} 
{bf: pea figure9b} [aw=weight_p], c(GNB) year(year) benchmark(CIV GHA GMB SEN) onewelfare(welfare) welfaretype(CONS) 
