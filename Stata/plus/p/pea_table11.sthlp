{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table11}{right:November 2024}
{hline}

{title:Title}

{bf:pea table11} — Generates Growth Incidence Curve Tables

{title}
{cmd} [{it
}] [{it
}], 
{cmdab(varname numeric)} 
{cmdab
(string)} {cmdab
(varname numeric)} {cmdab
setting(string)} {cmdab
(string)} {cmdab
(string)} {cmdab} {cmdab
(varname numeric)} {cmdab} {cmdab}

{title}

{cmd} calculates and generates Growth Incidence Curve (GIC) tables for specified welfare indicators, such as per capita consumption or income, by percentile across different time periods. It calculates the growth rates between two time points (specified in the spells option) for each welfare percentile and displays this information in a table. The results can be exported to an Excel file, and graphical representations can also be generated.

{title}

{phang} {opt Welfare(varname numeric)} specifies the welfare indicator to use for the GIC calculation (e.g., per capita consumption or income). {phang} {opt spells(string)} specifies the periods (years) to be used for the GIC analysis, such as "2000 2004" or "2010 2014". This option requires at least two years. {phang} {opt Year(varname numeric)} specifies the year variable for the analysis. {phang} {opt CORE setting(string)} allows for custom settings such as region or data type. {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file. {phang} {opt save(string)} specifies the file path for saving intermediate data. {phang} {opt missing} includes missing observations in the analysis. {phang} {opt by(varname numeric)} specifies a grouping variable (e.g., region or another categorical variable) for the GIC calculation. {phang} {opt GRAPH} generates graphical output for the Growth Incidence Curve by percentile. {phang} {opt NOOUTPUT} suppresses the output of results to the screen or to files.

{title}

{cmd} calculates the Growth Incidence Curve (GIC) for a given welfare variable over a specified time period (spells option), typically between two years. It computes the annualized growth rates for each percentile of the welfare distribution between the two periods. The growth rates are then summarized in a table and optionally visualized through a graph.

The program supports grouping by a specified variable (e.g., region, income group) through the by option. It also allows for including missing observations or excluding them based on the missing option.

The results can be exported to an Excel file or saved in a temporary file by default. If the GRAPH option is specified, the program generates a graph showing the GIC by percentile and can export the graph as a PNG image.

{title}

To generate the Growth Incidence Curve table for a specific welfare indicator between 2000 and 2004 and export the results to an Excel file:
{cmd:. pea_table11, Welfare("income") spells("2000 2004") Year(year) excel("output_table11.xlsx") }

To generate the Growth Incidence Curve for different regions: 

{cmd:. pea_table11, Welfare("income") spells("2000 2004") Year(year) by(region) excel("output_table11_by_region.xlsx") }
