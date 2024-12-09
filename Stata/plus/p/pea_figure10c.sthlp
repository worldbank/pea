{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table10c}{right:November 2024}
{hline}


{title:Title}  

{bf:pea_figure10c} — Generate scatter plot comparing prosperity gaps (PG) and GDP per capita.  

{title:Syntax}  

{p 4 15}  
{opt pea_figure10c}  
	[{it:weight}]  
	[{opt if} {it:exp}]  
	[{opt in} {it:exp}]  
	[{opt ,}  
	{opt Country(string)}  
    {opt Year(varname)}  
    {opt BENCHmark(string)}  
    {opt ONEWelfare(varname)}  
    {opt NONOTES}  
    {opt scheme(string)}  
    {opt palette(string)}  
    {opt save(string)}  
    {opt excel(string)}  
    {opt within(integer)}]  
{p_end}  

{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}  

{title:Description}  

{p 4 4 2}  
{opt pea_figure10c} generates a scatter plot comparing the survey-based prosperity gap (PG) with GDP per capita for a given country. The comparison includes the closest available survey year within a user-specified range and allows users to specify benchmark countries and visualization options.  

{title:Options}  
{p 4 4 2}  {opt Country(string)} specifies the PEA country of interest for the scatter analysis.  

{p 4 4 2}  {opt Year(varname)} specifies the year variable for the analysis.  

{p 4 4 2}  {opt BENCHmark(string)} is a list of benchmark countries for comparison (e.g., "India, Bhutan").  

{p 4 4 2}  {opt ONEWelfare(varname)} is the variable containing the prosperity gap calculations.  

{p 4 4 2}  {opt NONOTES} suppresses all notes from the generated visualization.  

{p 4 4 2}  {opt scheme(string)} defines the plotting color scheme.  

{p 4 4 2}  {opt palette(string)} specifies the visualization's color palette.  

{p 4 4 2}  {opt save(string)} specifies the file path to save the resulting visualization.  

{p 4 4 2}  {opt excel(string)} specifies the file path to export visualization-related results to Excel.  

{p 4 4 2}  {opt within(integer)} specifies the number of years to search for the survey overlap within the range of survey years (default is 3).  

{title:Remarks}  

{pstd} The {opt pea_figure10c} command visualizes scatter plots with GDP per capita on the x-axis and the calculated survey-based prosperity gap (PG) on the y-axis.  

{pstd} Users can specify key benchmarks and adjust visualization options, including color schemes and saving results to external files.  

{title:Examples}  

