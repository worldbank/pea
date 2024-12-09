{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure9a}{right:November 2024}
{hline}

//Figure 9a. Inequality by year lines

{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure9a}{right:November 2024}
{hline}

{title:Title}

{bf:pea_figure9a} — Generate inequality plots (GINI trends) by urban and rural areas across years with optional comparability adjustments.

{title:Syntax}

{p 4 15}
{opt pea_figure9a} 
	[{it:weight}] 
	[{opt if} {it:exp}] 
	[{opt in} {it:exp}] 
	[{opt ,}  	{opt ONEWelfare(varname)}     {opt Year(varname)}     {opt urban(varname)}     {opt setting(string)}     {opt comparability(string)}     {opt excel(string)}     {opt save(string)}     {opt NOOUTPUT}     {opt NONOTES}     {opt EQUALSPACING}     {opt scheme(string)}     {opt palette(string)}]{p_end} 


{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}


{title:Description}

{p 4 4 2}
{opt pea_figure9a} generates inequality line plots of GINI index estimates over time across urban and rural groups.
These plots visualize trends in inequality and allow comparisons over time. This program includes options for comparability adjustments, Excel exports, and plotting options such as visual adjustments.

{title:Options}
{p 4 4 2}  {opt ONEWelfare(varname)} specifies the name of the welfare variable (income or consumption) to compute the GINI index from.  
      
{p 4 4 2}  {opt Year(varname)} specifies the variable indicating the years across which trends will be plotted.
    
{p 4 4 2}  {opt urban(varname)} identifies urban/rural group classifications to separate inequality estimates accordingly.
    
{p 4 4 2}  {opt setting(string)} specifies settings for inequality comparisons.
    
{p 4 4 2}  {opt comparability(string)} applies comparability adjustments over time between urban and rural groups for better trend visualization.
    
{p 4 4 2}  {opt excel(string)} allows exporting the GINI trends plot data to the specified Excel file.
    
{p 4 4 2}  {opt save(string)} saves the generated plot trends as a Stata dataset or file.
    
{p 4 4 2}  {opt NOOUTPUT} suppresses the graphical output, allowing only data processing.
    
{p 4 4 2}  {opt NONOTES} suppresses generated notes related to data visualization.
    
{p 4 4 2}  {opt EQUALSPACING} ensures that the years are evenly spaced in the visualization, regardless of sampling differences or time periods.
    
{p 4 4 2}  {opt scheme(string)} allows users to specify visual color themes for plots.
    
{p 4 4 2}  {opt palette(string)} allows custom palette settings for visualizations to better highlight inequality trends.

{title:Remarks}

    {pstd} The {opt pea_figure9a} command generates GINI trends visualizations over time between urban and rural areas, leveraging survey estimates.
    
    {pstd} The tool visualizes trends using GINI index calculations with optional comparability settings and Excel export features for analysis customization.

{title:Examples}
