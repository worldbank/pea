{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure6}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure6} — GDP per capita GDP - Poverty elasticity

{title:Syntax}

{p 4 15}
{opt pea figure6} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
    [,{opt Country(string)} 
	{opt Year(varname numeric)}
	{opt ONELine(varname numeric)}
	{opt ONEWelfare(varname numeric)} 
    {opt  FGTVARS} 
	{opt spells(string)}
	{opt comparability(string)} 
	{opt scheme(string)} 
	{opt palette(string)} 
    {opt excel(string)} 
	{opt save(string)]{p_end}

{title:Description}

{p 4 4 2}
{opt pea figure6} calculates GDP per capita poverty elasticity across specified years
and generates a visualization comparing changes in poverty rate and GDP growth.

{p 4 4 2}
Inputs include survey data and GDP per capita data and may optionally integrate 
comparability options, defined spells (time ranges), and visualization customizations.

{p 4 4 2}
This program generates a two-dimensional visualization comparing GDP changes and 
changes in poverty rates over the defined spells using elasticity metrics.

{p 4 4 2}
The output will save visualization graphs (using Stata's `twoway`) to an Excel
file or directly depending on the `excel()` or `save()` options.

{title:Options}

{p 4 4 2} 
{opt Country(string)}: Name of the country being analyzed.

{p 4 4 2}
{opt Year(varname numeric)}: The variable indicating the survey or panel years to be analyzed.

{p 4 4 2}
{opt ONELine(varname numeric)}: Defines the specific poverty line for the analysis.

{p 4 4 2}
{opt ONEWelfare(varname numeric)}: Designates a specific welfare measure for analysis.

{p 4 4 2}
{opt FGTVARS}: Flag to specify welfare aggregation and analysis options.

{p 4 4 2}
{opt spells(string)}: Defines time spells (e.g., "2000;2004") for analysis over specified periods.

{p 4 4 2}
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{p 4 4 2}
{opt scheme(string)}: Defines visualization schemes (e.g., colors or graph themes).

{p 4 4 2}
{opt palette(string)}: Specifies a palette for figure visualization.

{p 4 4 2}
{opt excel(string)}: Path to an Excel file for saving the visualization results.

{p 4 4 2}
{opt save(string)}: Save path for visualization outputs.

{title:Examples}

{p 4 4 2}
{bf: pea figure6} [aw=weight_p], c(GNB) year(year) onew(welfare) onel(natline) palette(viridis) spells(2018 2021) comparability(comparability)

{p 4 4 2}
{bf: pea figure6} [aw=weight_p], c(ARM) year(year) onew(welfare) onel(natline) palette(viridis) spells(2015 2016; 2016 2017;2018 2022;2017 2022) comparability(comparability)

