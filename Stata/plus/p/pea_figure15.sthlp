{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure15}{right:November 2024}
{hline}


{title:Title}
{bf:pea_figure15} — Visualizing Climate Risk and Vulnerability. Climate hazard exposure visualization by survey comparison and country grouping


{title:Syntax}

{p 4 15}
{opt pea_figure2}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[,{opt Country(string)} 
	{opt NONOTES} 
	{opt scheme(string)} 
	{opt palette(string)} 
	{opt save(string)} 
	{opt excel(string)}]{p_end}


{title:Description}

{p 4 4 2}
{opt pea_figure15} generates a bar graph visualization that maps climate risk and vulnerability by population share across various dimensions, such as exposure to hazards, financial access, education levels, and other climate risk indicators. This visualization highlights the impact of climate risks on population groups.
This program generates bar graphs visualizing climate risk exposure, vulnerability, and other survey-based risk indices.
Population groups are categorized across dimensions such as financial access, social protection, education, and climate risk exposure.


{title:Options}
{p 4 4 2} 
{opt Country(string)} Specifies the name or code of the country to visualize data for.

{p 4 4 2} 
{opt NONOTES} If specified, suppresses additional notes in the visualization output.

{p 4 4 2} 
{opt scheme(string)} Specifies the color scheme to use in creating visualization graphics.

{p 4 4 2} 
{opt palette(string)} Defines a color palette to differentiate bars in the graph visualization.

{p 4 4 2} 
{opt excel(string)} Path to an Excel file to save visualization results to.

{p 4 4 2} 
{opt save(string)} Path used to save graph visualizations for reproducibility.

{title:Examples}

