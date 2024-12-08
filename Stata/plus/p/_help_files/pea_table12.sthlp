{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table12}{right:November 2024}
{hline}

{title:Title}

{bf: pea_table12} — Generates Decomposition of Poverty Changes: Growth and Redistribution Tables

{title:Syntax}

{p 4 15}
  {opt pea_table12} 
  [{opt if} {it:exp}] 
  [{opt in} {it:exp}] 
  [{opt ,} 
  {opt NATWelfare(varname numeric)} 
  {opt NATPovlines(varlist numeric)} 
  {opt PPPWelfare(varname numeric)} 
  {opt PPPPovlines(varlist numeric)} 
  {opt spells(string)} 
  {opt Year(varname numeric)}
  {opt CORE} 
  {opt LINESORTED} 
  {opt setting(string)} 
  {opt NOOUTPUT} 
  {opt excel(string)} 
  {opt save(string)} 
  {opt MISSING} 
  {opt GRAPH}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea_table12} calculates and generates tables for the decomposition of poverty changes over time, focusing on growth and redistribution. It uses the Datt-Ravallion and Shorrocks-Kolenikov methods to assess the contributions of different factors (e.g., growth and redistribution) to changes in poverty measures over specified periods. The results can be exported to Excel or saved in a specified file format.

{title:Options}

{p 4 4 2} {opt NATWelfare(varname numeric)} specifies the variable representing the welfare indicator (e.g., income or consumption).
  
{p 4 4 2} {opt NATPovlines(varlist numeric)} specifies the list of national poverty lines to be used in the analysis.
  
{p 4 4 2} {opt PPPWelfare(varname numeric)} specifies the variable for welfare under PPP adjustments.
 
{p 4 4 2} {opt PPPPovlines(varlist numeric)} specifies the list of PPP-adjusted poverty lines.
 
{p 4 4 2} {opt spells(string)} specifies the periods (spells) over which the decomposition should be performed, e.g., "2000;2004".
  
{p 4 4 2} {opt Year(varname numeric)} specifies the variable representing the year for the analysis.
  
{p 4 4 2} {opt CORE} runs the core decomposition method (Shorrocks-Kolenikov) in addition to Datt-Ravallion.
  
{p 4 4 2} {opt LINESORTED} orders the poverty lines before decomposition.
  
{p 4 4 2} {opt setting(string)} allows for the specification of a settings string to modify the analysis further.
  
{p 4 4 2} {opt NOOUTPUT} suppresses output to the screen.
  
{p 4 4 2} {opt excel(string)} specifies the file path for exporting results to an Excel file.
  
{p 4 4 2} {opt save(string)} specifies the file path for saving intermediate data.
  
{p 4 4 2} {opt MISSING} includes missing data in the analysis.
  
{p 4 4 2} {opt GRAPH} generates a graphical representation of the results.


{title:Details}

{p 4 4 2}
{opt pea_table12} performs the decomposition of poverty changes between two specified years (spells) using both the Datt-Ravallion and Shorrocks-Kolenikov methods. The following steps are performed:

	  - Decomposes poverty changes into growth and redistribution components.
	  - Uses the national and PPP-adjusted poverty lines for poverty analysis.
	  - Handles missing data based on user specifications and outputs results to a temporary file or to a specified Excel file.
	  - Generates both tables and graphs (if requested) summarizing the results of the decomposition, which includes:
			- Total poverty change due to growth.
			- Redistribution effects on poverty.
			- The specific contributions of each factor to changes in poverty.
	  - Results can be further processed or saved as requested by the user.

{title:Example}

{p 4 4 2}
To generate the decomposition table of poverty changes for a specific period and export the results to an Excel file:

{p 4 4 2}
pea_table12, NATWelfare("income") NATPovlines("1000 2000") PPPWelfare("PPP_income") PPPPovlines("1000 2000") spells("2000;2004") Year(year) excel("output_table12.xlsx")
