{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure9a}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure9a} — Inequality by year lines. Generate inequality plots (GINI trends) by urban and rural areas across years with optional comparability adjustments.

{title:Syntax}

{p 4 15}
{opt pea figure9a} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[{opt ,}  	
	{opt ONEWelfare(varname numeric)}    
	{opt Year(varname numeric)}    
	{opt urban(varname numeric)}     
	{opt setting(string)}     
	{opt comparability(string)}     
	{opt excel(string)}     
	{opt save(string)}     
	{opt NOOUTPUT}     
	{opt NONOTES}    
	{opt EQUALSPACING}   
	{opt YRange0}   
	{opt MISSING}
	{opt scheme(string)}   
	{opt palette(string)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea figure9a} generates inequality line plots of GINI index estimates over time across urban and rural groups.
These plots visualize trends in inequality and allow comparisons over time. This program includes options for comparability adjustments, Excel exports, and plotting options such as visual adjustments.

{title:Options}

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}: specifies the name of the welfare variable (income or consumption) to compute the GINI index from.  
      
{p 4 4 2}  
{opt Year(varname numeric)}: specifies the variable indicating the years across which trends will be plotted.
    
{p 4 4 2} 
{opt urban(varname numeric)}: identifies urban/rural group classifications to separate inequality estimates accordingly.
    
{p 4 4 2}  
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options 
(hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 

{p 4 4 2}
{opt comparability(varname numeric)}: Required. This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).
    
{p 4 4 2}  
{opt excel(string)}: allows exporting the GINI trends plot data to the specified Excel file.
    
{p 4 4 2}  
{opt save(string)}: saves the generated plot trends as a Stata dataset or file.
    
{p 4 4 2}  
{opt NOOUTPUT}: suppresses the graphical output, allowing only data processing.
    
{p 4 4 2}  
{opt NONOTES}: suppresses generated notes related to data visualization.
    
{p 4 4 2}  
{opt EQUALSPACING}: ensures that the years are evenly spaced in the visualization, regardless of sampling differences or time periods.
    
{p 4 4 2}
{opt yrange0}: Optional. When specified, the y-axis starts at 0.

{p 4 4 2}  
{opt scheme(string)}: allows users to specify visual color themes for plots.
    
{p 4 4 2}  
{opt palette(string)}: allows custom palette settings for visualizations to better highlight inequality trends.

{title:Examples}

{p 4 4 2} 

{bf: pea figure9a} [aw=weight_p], year(year) onewelfare(welfare) urban(urban) comparability(comparability) 
