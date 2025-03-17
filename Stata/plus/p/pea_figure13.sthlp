{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure13}{right:January 2025}
{hline}


{title:Title}

{p 4 15}
{bf:pea figure13} —  Distribution of welfare by deciles. Welfare analysis visualization by survey comparisons over time.

{title:Syntax}

{p 4 15}
{opt pea figure13} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[{opt ,}  
	{opt ONEWelfare(varname numeric)} 
	{opt PPPyear(integer)}
	{opt Year(varname numeric)} 
	{opt NOOUTPUT} 
    {opt NOEQUALSPACING}
	{opt excel(string)} 
	{opt save(string)}
	{opt scheme(string)}
	{opt palette(string)} 
	{opt COMParability(varname numeric)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea figure13} generates a graphical visualization of welfare distribution by deciles over specified years or comparability groups. This includes the visualization of survey-based welfare shares for different welfare deciles through spike charts or area charts, depending on the temporal structure of the data.

{title:Options}

{p 4 4 2} 
{opt ONEWelfare(varname numeric)}:
Specifies the numeric welfare variable to analyze and visualize. 

{p 4 4 2} 
{opt Year(varname numeric)}:
The year variable used for grouping comparisons over time. 
  
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt NOOUTPUT}:
Suppresses generating output during analysis, typically useful during batch processing.

{p 4 4 2} 
{opt NOEQUALSPACING}: Adjusts year spacing on x-axis to be proportional to the distance between years. Default is that years are evenly spaced in the visualization.

{p 4 4 2} 
{opt excel(string)}:
Path to an existing Excel file to export the visualization results.

{p 4 4 2} 
{opt save(string)}:
Path where the visualization output will be stored.

{p 4 4 2} 
{opt scheme(string)}:
Specifies the color scheme to be used for visual contrast.

{p 4 4 2} 
{opt palette(string)}:
Defines the palette of colors to use in graphs.

{p 4 4 2}
{opt comparability(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{title:Examples}

{p 4 4 2} 
{bf: pea figure13} [aw=weight_p], c(GNB) year(year) onew(welfppp) palette(viridis)

