{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure3}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea_figure3} —  Generate Growth Incidence Curves (GIC).

{title:Syntax}

{p 4 15}
{opt pea_figure3} 
[{it:if}]
 [{it:in}] 
 [{it:aw pw fw}],
    {opt Welfare(varname numeric)} 
    {opt spells(string)} 
    {opt Year(varname numeric)} 
    [{opt NONOTES}] 
    [{opt comparability(varname numeric)}] 
    [{opt setting(string)}] 
    [{opt excel(string)}] 
    [{opt save(string)}] 
    [{opt by(varname numeric)}] 
    [{opt scheme(string)}] 
    [{opt palette(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea_figure3} generates Growth Incidence Curves (GIC), which display the annualized growth in welfare 
(e.g., income or consumption) by percentiles over specified periods (spells). The program supports multiple 
spells, handles comparability of periods when specified, and offers customizable settings for exporting results 
and visualizations.

{title:Options}

{p 4 4 2}{opt Welfare(varname numeric)}
Specifies the numeric variable representing welfare (e.g., income or consumption).

{p 4 4 2}{opt spells(string)}
Defines the spells (time periods) for analysis. Enter pairs of years separated by a space, and separate 
multiple spells with semicolons (e.g., `"2000 2005; 2005 2010"`).

{p 4 4 2}{opt Year(varname numeric)}
Specifies the numeric variable indicating the year associated with each observation.

{p 4 4 2}{opt NONOTES}
Suppresses the default notes added to the generated figures.

{p 4 4 2}{opt comparability(varname numeric)}
Specifies a variable to check comparability between years within spells. Only spells with comparable 
years are included in the analysis.

{p 4 4 2}{opt setting(string)}
Defines additional settings for customizing the output. Currently, this option is not utilized 
explicitly but reserved for future extensions.

{p 4 4 2}{opt excel(string)}
Specifies the file path for exporting results to an Excel file. If not provided, a temporary Excel file 
is created.

{p 4 4 2}{opt save(string)}
Specifies the file path for saving the dataset created during the process.

{p 4 4 2}{opt by(varname numeric)}
Indicates a grouping variable for disaggregating results by subpopulations.

{p 4 4 2}{opt scheme(string)}
Defines the graph scheme to apply to the GIC plots.

{p 4 4 2}{opt palette(string)}
Specifies the color palette to use for the GIC plots.

{title:Remarks}

{p 4 4 2}
The program supports weighted data ({opt aw}, {opt pw}, or {opt fw}) and ensures accurate handling of missing observations and data 
availability across specified spells. Multiple spells can be analyzed, and the generated GIC plots are exported 
to the specified Excel file or displayed interactively.

{title:Examples

{p 4 4 2}
pea figure3 [aw=weight_p], year(year) welfare(welfppp)  spells(2015 2016; 2016 2017;2018 2022;2017 2022)

{p 4 4 2}
pea figure3 [aw=weight_p], year(year) welfare(welfppp)  spells(2015 2016; 2016 2017;2018 2022;2017 2022) comparability(comparability)

{p 4 4 2}
pea figure3 [aw=weight_p], year(year) welfare(welfppp)  spells(2018 2021)
palette(viridis)