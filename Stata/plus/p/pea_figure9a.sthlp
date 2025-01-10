{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure9a}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea_figure9a} — Inequality by year lines. Generate inequality plots (GINI trends) by urban and rural areas across years with optional comparability adjustments.

{title:Syntax}

{p 4 15}
{opt pea_figure9a} 
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
	{opt scheme(string)}   
	{opt palette(string)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea_figure9a} generates inequality line plots of GINI index estimates over time across urban and rural groups.
These plots visualize trends in inequality and allow comparisons over time. This program includes options for comparability adjustments, Excel exports, and plotting options such as visual adjustments.

{title:Options}

{p 4 4 2}  
{opt ONEWelfare(varname numeric)}: specifies the name of the welfare variable (income or consumption) to compute the GINI index from.  
      
{p 4 4 2}  
{opt Year(varname numeric)}: specifies the variable indicating the years across which trends will be plotted.
    
{p 4 4 2} 
{opt urban(varname numeric)}: identifies urban/rural group classifications to separate inequality estimates accordingly.
    
{p 4 4 2}  
{opt setting(string)}: specifies settings for inequality comparisons.
    
{p 4 4 2}  
{opt comparability(string)}: applies comparability adjustments over time between urban and rural groups for better trend visualization.
    
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

{title:Remarks}

{p 4 4 2}  
The {opt pea_figure9a} command generates GINI trends visualizations over time between urban and rural areas, leveraging survey estimates.
    
{p 4 4 2}  
The tool visualizes trends using GINI index calculations with optional comparability settings and Excel export features for analysis customization.

{title:Examples}

{p 4 4 2} 
pea_figure9a [aw=weight_p], year(year) onewelfare(welfare) urban(urban) comparability(comparability) 
