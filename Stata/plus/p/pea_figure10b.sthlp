{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10b}{right:November 2024}
{hline}

{smcl}  
{* 10Nov2024}{...}  
{hline}  
help for {hi:pea_figure10b}{right:November 2024}  
{hline}  

// Figure 10b. Prosperity gap visualized as scatter plot

{smcl}  
{* 10Nov2024}{...}  
{hline}  
help for {hi:pea_figure10b}{right:November 2024}  
{hline}  

{title:Title}  

{bf:pea_figure10b} — Generate Figure 10b visualizing the prosperity gap scatter plot for the selected country or groups.  

{title:Syntax}  

{p 4 15}  
{opt pea_figure10b}  
	[{it:weight}]  
	[{opt if} {it:exp}]  
	[{opt in} {it:exp}]  
	[{opt ,}  
	{opt ONEWelfare(varname)}  
	{opt Year(varname)}  
	{opt Country(string)}  
	{opt BENCHmark(string)}  
	{opt NONOTES}  
	{opt scheme(string)}  
	{opt palette(string)}  
	{opt save(string)}  
	{opt excel(string)}]  
{p_end}  

{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}  

{title:Description}  

{p 4 4 2}  
{opt pea_figure10b} generates **Figure 10b: Prosperity Gap as Scatter Plot**. This visualization allows users to assess the relationship between GDP per capita and income/poverty measures across countries or specific urban/rural comparisons.  

The visualization uses scatter plots for trends analysis, allowing comparisons of various benchmarks or welfare outcomes in dynamic visual trends.  

{title:Options}  

{p 4 4 2}  {opt ONEWelfare(varname)}  
Specifies the numeric welfare variable, such as income, consumption, or wealth, for analysis.  

{p 4 4 2}  {opt Year(varname)}  
Specifies the numeric variable indicating survey years or temporal intervals for visualization.  

{p 4 4 2}  {opt Country(string)}  
Specifies the name of the country or countries for scatter plot comparisons.  

{p 4 4 2}  {opt BENCHmark(string)}  
A list of benchmark comparison countries. These will be plotted in the visualization for comparative analysis.  

{p 4 4 2}  {opt NONOTES}  
Suppresses descriptive notes and annotations from the visualization.  

{p 4 4 2}  {opt scheme(string)}  
Specifies the visualization style (default options include visualization schemes like `viridis`, `rainbow`).  

{p 4 4 2}  {opt palette(string)}  
Defines a custom color scheme or palette for visual clarity.  

{p 4 4 2}  {opt save(string)}  
Specifies the file path to save the visualization results.  

{p 4 4 2}  {opt excel(string)}  
Exports the visualization results or statistics into Excel for further analysis or visualization sharing.  

{title:Remarks}  

{pstd} The {opt pea_figure10b} program generates scatter visualizations connecting GDP per capita and welfare gaps for insights into temporal poverty trends and cross-country comparisons.  

{pstd} The visualization provides insights into welfare disparities among urban and rural groups or selected benchmark comparisons.  

{title:Examples}  
