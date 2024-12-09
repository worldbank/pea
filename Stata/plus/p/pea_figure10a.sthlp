{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10a}{right:November 2024}
{hline}

{title:Title}  

{bf:pea_figure10a} — Generate Figure 10a visualizing the prosperity gap by year.  

{title:Syntax}  

{p 4 15}  
{opt pea_figure10a}  
	[{it:weight}]  
	[{opt if} {it:exp}]  
	[{opt in} {it:exp}]  
	[{opt ,}  
	{opt ONEWelfare(varname)}  
	{opt Year(varname)}  
	{opt urban(varname)}  
	{opt comparability(string)}  
	{opt NONOTES}  
	{opt EQUALSPACING}  
	{opt scheme(string)}  
	{opt palette(string)}  
	{opt save(string)}  
	{opt excel(string)}]  
{p_end}  

{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}  

{title:Description}  

{p 4 4 2}  
{opt pea_figure10a} generates a visualization of **Figure 10a: Prosperity Gap by Year Lines**. This visualization allows users to analyze trends in income distribution and poverty across urban/rural populations over time.  

The program computes scatter points representing trends in poverty gaps and creates connecting visualizations across years to highlight temporal comparisons. Users can optionally group by urban/rural classifications, adjust visualization settings, or perform comparability adjustments over specified survey years.

{title:Options}  

{p 4 4 2}  {opt ONEWelfare(varname)}  
Specifies the variable representing the numeric welfare measure for analysis, such as income, consumption, or wealth.  

{p 4 4 2}  {opt Year(varname)}  
Specifies the numeric variable that represents the time periods for the visualization analysis (e.g., survey years).  

{p 4 4 2}  {opt urban(varname)}  
Specifies the urban/rural grouping variable for the analysis.  

{p 4 4 2}  {opt comparability(string)}  
Defines criteria for comparing survey years across periods. Only observations meeting these criteria are visualized.  

{p 4 4 2}  {opt NONOTES}  
Suppresses explanatory notes in the visualization.  

{p 4 4 2}  {opt EQUALSPACING}  
Ensures that the visualization represents time intervals as evenly spaced, even in the presence of gaps.  

{p 4 4 2}  {opt scheme(string)}  
Specifies the visualization scheme (e.g., `viridis`, `rainbow`, etc.).  

{p 4 4 2}  {opt palette(string)}  
Defines a custom color palette for visual clarity and distinction among groups or survey periods.  

{p 4 4 2}  {opt save(string)}  
Specifies the file path to save the processed results.  

{p 4 4 2}  {opt excel(string)}  
Exports visualization and calculated trends into Excel for external analysis.  

{title:Remarks}  

{pstd} The {opt pea_figure10a} program performs temporal visual analysis of urban vs rural trends in prosperity gaps over specified years.  

{pstd} The visualization represents scatter points for each urban/rural group over time and connects them based on trends between years.  

{pstd} Options such as `comparability`, `scheme`, and `EQUALSPACING` provide users flexibility in comparing survey years or customizing visual outputs.

{title:Examples}  

