{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_table13}
{hline 80}
{title:Title}
  {bf pea_table13} — Generates Poverty Changes Decomposition by Income and Non-Income Factors

{title:Syntax}
  {cmd:pea_table13} [{it:if}] [{it:in}], {cmdab:NATWelfare(varname numeric)} {cmdab:NATPovlines(varlist numeric)} {cmdab:PPPWelfare(varname numeric)} {cmdab:PPPPovlines(varlist numeric)} {cmdab:spells(string)} {cmdab:Year(varname numeric)} {cmdab:CORE} {cmdab:LINESORTED} {cmdab:setting(string)} {cmdab:NOOUTPUT} {cmdab:excel(string)} {cmdab:save(string)} {cmdab:MISSING} {cmdab:GRAPH}

{title:Description}
  {cmd:pea_table13} calculates and generates tables for the decomposition of poverty changes based on income and non-income factors. This decomposition helps in understanding how different factors, such as income growth, education, and social transfers, contribute to changes in poverty. The analysis uses methods similar to the Datt-Ravallion and Shorrocks-Kolenikov approaches but with a focus on distinguishing the role of income and non-income factors. The results can be exported to Excel or saved in a specified file format.

{title:Options}
  {phang} {opt NATWelfare(varname numeric)} specifies the variable representing the welfare indicator (e.g., income or consumption).
  
  {phang} {opt NATPovlines(varlist numeric)} specifies the list of national poverty lines to be used in the analysis.
  
  {phang} {opt PPPWelfare(varname numeric)} specifies the variable for welfare under PPP adjustments.

  {phang} {opt PPPPovlines(varlist numeric)} specifies the list of PPP-adjusted poverty lines.

  {phang} {opt spells(string)} specifies the periods (spells) over which the decomposition should be performed, e.g., "2000;2004".

  {phang} {opt Year(varname numeric)} specifies the variable representing the year for the analysis.

  {phang} {opt CORE} runs the core decomposition method (Shorrocks-Kolenikov) in addition to Datt-Ravallion.

  {phang} {opt LINESORTED} orders the poverty lines before decomposition.

  {phang} {opt setting(string)} allows for the specification of a settings string to modify the analysis further.
 
  {phang} {opt NOOUTPUT} suppresses output to the screen.

  {phang} {opt excel(string)} specifies the file path for exporting results to an Excel file.

  {phang} {opt save(string)} specifies the file path for saving intermediate data.

  {phang} {opt MISSING} includes missing data in the analysis.

  {phang} {opt GRAPH} generates a graphical representation of the results.

{title:Details}
  {cmd:pea_table13} performs a detailed decomposition of poverty changes between two specified periods (spells) by differentiating the contributions of income and non-income factors (such as education, healthcare, and social transfers). The analysis follows these steps:
  - Decomposes poverty changes into components driven by income and non-income factors.
  - Uses national and PPP-adjusted poverty lines for poverty measurement.
  - Handles missing data according to user preferences and outputs the results either to an Excel file or a specified location.
  - Provides tables and graphs (if requested) that summarize:
    - Poverty change due to income factors (growth and redistribution).
    - Poverty change driven by non-income factors (e.g., social programs, education).
    - Contributions of each factor to overall poverty changes.
  - Users can choose to save the results in a specified file format or process them further.

{title:Example}
  To generate a decomposition table of poverty changes by income and non-income factors for a specific period and export the results to an Excel file:

{cmd:. pea_table13, NATWelfare("income") NATPovlines("1000 2000") PPPWelfare("PPP_income") PPPPovlines("1000 2000") spells("2000;2004") Year(year) excel("output_table13.xlsx")}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  
  {help pea_table12}: For generating Decomposition of Poverty Changes by Growth and Redistribution.
  
  {help pea_table14}: For generating Decomposition of Poverty Changes with Additional Covariates.

{hline 80}
