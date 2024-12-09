{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure3}{right:November 2024}
{hline}

{title:Title}

{title:pea_figure3 — Generate Growth Incidence Curves (GIC)}

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
    [{opt palette(string)}]


{title:Description}


{opt pea_figure3} generates Growth Incidence Curves (GIC), which display the annualized growth in welfare 
(e.g., income or consumption) by percentiles over specified periods (spells). The program supports multiple 
spells, handles comparability of periods when specified, and offers customizable settings for exporting results 
and visualizations.

{title:Options}

{p 8 12}{opt Welfare(varname numeric)}{p_end}
{p 12 16}Specifies the numeric variable representing welfare (e.g., income or consumption).{p_end}

{p 8 12}{opt spells(string)}{p_end}
{p 12 16}Defines the spells (time periods) for analysis. Enter pairs of years separated by a space, and separate 
multiple spells with semicolons (e.g., `"2000 2005; 2005 2010"`).{p_end}

{p 8 12}{opt Year(varname numeric)}{p_end}
{p 12 16}Specifies the numeric variable indicating the year associated with each observation.{p_end}

{p 8 12}{opt NONOTES}{p_end}
{p 12 16}Suppresses the default notes added to the generated figures.{p_end}

{p 8 12}{opt comparability(varname numeric)}{p_end}
{p 12 16}Specifies a variable to check comparability between years within spells. Only spells with comparable 
years are included in the analysis.{p_end}

{p 8 12}{opt setting(string)}{p_end}
{p 12 16}Defines additional settings for customizing the output. Currently, this option is not utilized 
explicitly but reserved for future extensions.{p_end}

{p 8 12}{opt excel(string)}{p_end}
{p 12 16}Specifies the file path for exporting results to an Excel file. If not provided, a temporary Excel file 
is created.{p_end}

{p 8 12}{opt save(string)}{p_end}
{p 12 16}Specifies the file path for saving the dataset created during the process.{p_end}

{p 8 12}{opt by(varname numeric)}{p_end}
{p 12 16}Indicates a grouping variable for disaggregating results by subpopulations.{p_end}

{p 8 12}{opt scheme(string)}{p_end}
{p 12 16}Defines the graph scheme to apply to the GIC plots.{p_end}

{p 8 12}{opt palette(string)}{p_end}
{p 12 16}Specifies the color palette to use for the GIC plots.{p_end}

{title:Remarks}

{pstd}The program supports weighted data ({opt aw}, {opt pw}, or {opt fw}) and ensures accurate handling of missing observations and data 
availability across specified spells. Multiple spells can be analyzed, and the generated GIC plots are exported 
to the specified Excel file or displayed interactively.

{title:Examples}
