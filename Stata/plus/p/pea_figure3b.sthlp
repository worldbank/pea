{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure3b}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure3b} —  Generates Growth Incidence Curves (GIC) by urban and rural areas

{title:Syntax}

{p 4 15}
{opt pea figure3b} 
[{it:if}]
 [{it:in}] 
 [{it:aw pw fw}],
    [{opt Welfare(varname numeric)} 
    {opt Year(varname numeric)} 
    {opt comparability(varname numeric)} 
	{opt trim(string)}
    {opt excel(string)} 
    {opt save(string)} 
	{opt yrange(string)} 
    {opt scheme(string)} 
    {opt palette(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea figure3b} generates Growth Incidence Curves (GIC), which display the annualized growth in welfare 
(e.g., income or consumption) by percentiles over the last available period (spell) by the whole country, urban and rural areas. The program supports multiple 
spells, handles comparability of periods when specified, and offers customizable settings for exporting results 
and visualizations.

{title:Options}

{p 4 4 2}{opt Welfare(varname numeric)}:
Specifies the numeric variable representing welfare (e.g., income or consumption).

{p 4 4 2}{opt Year(varname numeric)}:
Specifies the numeric variable indicating the year associated with each observation.

{p 4 4 2}{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{p 4 4 2}{opt excel(string)}:
Specifies the file path for exporting results to an Excel file. If not provided, a temporary Excel file 
is created.

{p 4 4 2}{opt save(string)}:
Specifies the file path for saving the dataset created during the process.

{p 4 4 2}{opt by(varname numeric)}:
Indicates a grouping variable for disaggregating results by subpopulations.

{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)".
Default is that figures start at 0 and go in steps of 1 up to the maximum value of the displayed data (next 10).

{p 4 4 2}
{opt trim(string)}: specifies percentiles below and above which growth incidence curves are trimmed.
Default is trim(3 97).

{p 4 4 2}{opt scheme(string)}:
Defines the graph scheme to apply to the GIC plots.

{p 4 4 2}{opt palette(string)}:
Specifies the color palette to use for the GIC plots.

{title:Examples}

{p 4 4 2}
{bf: pea figure3b} [aw=weight_p], year(year) welfare(welfppp) setting(GMD)

{p 4 4 2}
{bf: pea figure3b} [aw=weight_p], year(year) welfare(welfppp) trim(5 95)

{p 4 4 2}
{bf: pea figure3b} [aw=weight_p], year(year) welfare(welfppp) yrange(0(5)20)