{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure15}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure15} — Visualizing Climate Risk and Vulnerability. Climate hazard exposure visualization by survey comparison and country grouping

{title:Syntax}

{p 4 15}
{opt pea figure15}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[,{opt Country(string)} 
	{opt scheme(string)} 
	{opt palette(string)} 
	{opt save(string)} 
	{opt excel(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea figure15} generates a bar graph visualization that maps climate risk and vulnerability by population share across various dimensions, such as exposure to hazards, financial access, education levels, and other climate risk indicators. 
This visualization highlights the impact of climate risks on population groups.

{title:Options}

{p 4 4 2} 
{opt Country(string)}: 
Specifies the name or code of the country to visualize data for.

{p 4 4 2} 
{opt scheme(string)}: 
Specifies the color scheme to use in creating visualization graphics.

{p 4 4 2} 
{opt palette(string)}: 
Defines a color palette to differentiate bars in the graph visualization.

{p 4 4 2} 
{opt excel(string)}:
Path to an Excel file to save visualization results to.

{p 4 4 2} 
{opt save(string)}: 
Path used to save graph visualizations for reproducibility.

{title:Examples}

{p 4 4 2} 
{bf: pea figure15}, c(ARM) 
 
