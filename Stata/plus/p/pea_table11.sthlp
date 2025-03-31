{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table11}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea table11} — Generates Growth Incidence Curve Tables.

{p 4 15}
{opt pea table11}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[{opt ,}  
	{opt Welfare(varname numeric)} 
	{opt spells(string)} 
	{opt Year(varname numeric)} 
	{opt excel(string)} 
	{opt save(string)} 
	{opt missing} 
	{opt by(varname numeric)} 
	{opt GRAPH}
	{opt NOOUTPUT}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea table11} calculates and generates Growth Incidence Curve (GIC) over past periods, disaggregated by total, urban and rural populations

{title:Options}

{p 4 4 2} 
{opt Welfare(varname numeric)}:
specifies the welfare indicator to use for the GIC calculation (e.g., per capita consumption or income).

{p 4 4 2} 
{opt spells(string)}:
 specifies the periods (years) to be used for the GIC analysis, such as "2000 2004" or "2010 2014". This option requires at least two years.

{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file.
 
{p 4 4 2} 
{opt save(string)}:
 specifies the file path for saving intermediate data.

{p 4 4 2} 
{opt missing}:
 includes missing observations in the analysis.

{p 4 4 2} 
{opt by(varname numeric)}:
 specifies a grouping variable (e.g., region or another categorical variable) for the GIC calculation.

{p 4 4 2} 
{opt GRAPH}:
 generates graphical output for the Growth Incidence Curve by percentile.

{p 4 4 2} 
{opt NOOUTPUT}:
 suppresses the output of results to the screen or to files.

{title:Examples}

{p 4 4 2} 
{bf:pea table11} [aw=weight_p], welfare(welfppp) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) by(urban) graph

{p 4 4 2} 
{bf:pea table11} [aw=weight_p], welfare(welfppp) spells(2015 2016; 2016 2017;2018 2025;2017 2025) year(year) nooutput

{p 4 4 2} 
{bf:pea table11} [aw=weight_p], natw(welfare) natp(natline ) year(year) core spell()
