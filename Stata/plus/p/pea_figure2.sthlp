{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure2}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea_figure2} — Create a scatter plot showing poverty rates versus GDP per capita for a specified country and year, with international poverty lines.

{title:Syntax}

{p 4 15}
{opt pea_figure2}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[,{opt Country(string)} 
	{opt Year(varname numeric)} 
	{opt BENCHmark(string)} 
	{opt ONELine(varname numeric)} 
	{opt ONEWelfare(varname numeric)} 
	{opt FGTVARS} 
	{opt NONOTES} 
	{opt scheme(string)} 
	{opt palette(string)} 
	{opt save(string)} 
	{opt excel(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea_figure2} 
generates a scatter plot that shows the relationship between poverty rates and GDP per capita (in logarithmic form) for a given country, using international poverty lines (specifically, 2.15, 3.65, 6.85 in 2017 PPP). This plot includes benchmark countries, regions, and the selected country of analysis, with the option to save the figure to Excel or another format.

{title:Options}

{p 4 4 2} 
{opt Country(string)} 
specifies the country code or name for which the analysis is performed.
    
{p 4 4 2} 
{opt Year(varname numeric)} 
is the variable representing the year of observation.
    
{p 4 4 2} 
{opt BENCHmark(string)} 
is a list of benchmark countries to be included in the analysis.
    
{p 4 4 2} 
{opt ONELine(varname numeric)} 
is the variable containing the selected national poverty line for the country.
    
{p 4 4 2} 
{opt ONEWelfare(varname numeric)} 
is the welfare variable to be used in the analysis.
    
{p 4 4 2} 
{opt FGTVARS} 
generates additional Foster-Greer-Thorbecke poverty indices.
    
{p 4 4 2} 
{opt NONOTES} 
disables the inclusion of notes in the final output.
    
{p 4 4 2} 
{opt scheme(string)} 
allows customization of the figure's color scheme.
    
{p 4 4 2} 
{opt palette(string)} 
sets the color palette used in the figure.
    
{p 4 4 2} 
{opt save(string)} 
specifies a path where the figure will be saved.
    
{p 4 4 2} 
{opt excel(string)} 
specifies an Excel file path to store the output.

{title:Remarks}

{p 4 4 2} 
The {opt pea_figure2} command is specifically designed to work with international poverty lines (2.15, 3.65, 6.85, 2017 PPP). The plot shows the relationship between poverty rates (using the selected poverty line) and GDP per capita, with countries grouped into categories such as benchmarks, regions, and others. 

{p 4 4 2} 
The figure is saved in Excel format by default, but it can also be saved in other formats as specified by the user.

{title:Examples}

{p 4 4 2} 
pea figure2 [aw=weight_p], c(GNB) year(year) onew(welfppp) onel(pline215) benchmark(CIV GHA GMB SEN) palette(viridis)
