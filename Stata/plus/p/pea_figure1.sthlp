{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure1}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea_figure1} — Poverty rates by years lines.

{title:Syntax}

{p 4 15}
{opt pea_figure1}
	[{it:weight}] 
	[{opt if} {it:exp}] 
	[{opt in} {it:exp}] 
	[{opt ,}  
{opt NATWelfare(varname numeric)}
{opt NATPovlines(varlist numeric)}
{opt PPPWelfare(varname numeric)}
{opt PPPPovlines(varlist numeric)}
{opt FGTVARS}
{opt Year(varname numeric)}
{opt urban(varname numeric)}
{opt LINESORTED(string)}
{opt COMParability(varname numeric)}
{opt COMBINE}
{opt NOOUTPUT}
{opt NONOTES}
{opt EQUALSPACING}
{opt YRange0} 
{opt excel(string)}
{opt save(string)}
{opt MISSING}
{opt scheme(string)}
{opt palette(string)}{p_end} 

{title:Description}

{p 4 4 2}
{opt pea_figure1} shows trends in poverty rates over time. The visualization incorporates national and PPP-based poverty statistics across urban and rural areas, with optional comparability checks and other adjustments.

{title:Options}

{p 4 4 2} 
{opt  NATWelfare(varname numeric)}:
Specifies the numeric variable containing national welfare data. Required for national poverty rate comparisons.

{p 4 4 2} 
{opt  NATPovlines(varlist numeric)}:
List of numeric variables corresponding to national poverty line levels for visualization purposes.

{p 4 4 2} 
{opt PPPWelfare(varname numeric)}:
Specifies the numeric variable for PPP-based welfare comparisons.

{p 4 4 2} 
{opt PPPPovlines(varlist numeric)}:
List of PPP-based poverty line values to compare against PPP welfare levels.

{p 4 4 2} 
{opt FGTVARS}:
Includes relevant FGT index variables needed for visualization.

{p 4 4 2} 
{opt Year(varname numeric)}:
The variable specifying the years for temporal analysis.

{p 4 4 2} 
{opt urban(varname numeric)}:
The grouping variable distinguishing urban from rural observations for comparisons.

{p 4 4 2} 
{opt LINESORTED(string)}:
Allows users to sort lines based on a specific setting for better visualization clarity.

{p 4 4 2} 
{opt COMParability(varname numeric)}: 
Adjusts poverty trends based on comparability criteria from survey differences or other stratifications.

{p 4 4 2} 
{opt COMBINE}:
If specified, combines multiple poverty trend graphs into a single composite visualization.

{p 4 4 2} 
{opt NOOUTPUT}:
Prevents non-essential outputs from being generated during execution.

{p 4 4 2} 
{opt  NONOTES}:
Omits survey notes from the graph outputs.

{p 4 4 2} 
{opt  EQUALSPACING}:
Adjusts time gaps to ensure even visual spacing between years.
    
{p 4 4 2}
{opt yrange0}: Optional. When specified, the y-axis starts at 0.

{p 4 4 2} 
{opt  excel(string)}:
Saves the visualization graphs into an Excel file at the specified path.

{p 4 4 2} 
{opt  save(string)}:
Saves graphs or visualization outputs to the given directory path.

{p 4 4 2} 
{opt  MISSING}:
Handles missing observations and excludes them during visualization.

{p 4 4 2} 
{opt  scheme(string)}:
Allows users to define a specific visualization color scheme.

{p 4 4 2} 
{opt  palette(string)}:
Specifies a custom color palette for use in visualizations.

{title:Examples}

{p 4 4 2} 
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) setting(GMD) urban(urban)

{p 4 4 2} 
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) setting(GMD) urban(urban) combine

{p 4 4 2} 
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) setting(GMD) urban(urban) combine comparability(comparability)

{p 4 4 2} 
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) setting(GMD) urban(urban) combine 

{p 4 4 2} 
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) setting(GMD) urban(urban)  comparability(comparability)

{p 4 4 2} 
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) setting(GMD) urban(urban)  

