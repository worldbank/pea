{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure5}{right:November 2024}
{hline}

{title:pea_figure4 — Poverty Decomposition with Datt-Ravallion and Shorrocks-Kolenikov Methods}

{title:Syntax}

{p 4 15}
{opt pea_figure4} 
[{it:if}]
[{it:in}] 
[{it:aw pw fw}], 
    {opt onewelfare(varname numeric)} 
    {opt oneline(varname numeric)} 
    {opt spells(string)} 
    {opt year(varname numeric)} 
    [{opt NONOTES}]  
    [{opt save(string)}] 
    [{opt excel(string)}]  
    [{opt by(varname numeric)}]{p_end} 

{title:Description}

{p 4 4 2}
{opt pea_figure4} performs poverty decomposition over time using the Datt-Ravallion and Shorrocks-Kolenikov methods. 
The program generates visualizations and numerical results showing the contribution of changes in income or welfare across different 
time periods or population groups. The results can help analysts and policymakers identify the drivers behind changes in poverty.

{title:Options}

{p 4 4 2} 
{opt onewelfare(varname numeric)}{p_end}  
Specifies the numeric variable representing welfare (e.g., income or consumption) for poverty analysis.{p_end}  

{p 4 4 2} 
{opt oneline(varname numeric)}{p_end}  
Specifies the numeric variable representing the poverty line used for comparison in the analysis.{p_end}  

{p 4 4 2} 
{opt spells(string)}{p_end}  
Defines time periods (spells) to perform the decomposition. Use pairs of years separated by a space, with multiple spells separated by semicolons (e.g., `"2000 2005; 2005 2010"`).{p_end}  

{p 4 4 2} 
{opt year(varname numeric)}{p_end}  
Specifies the numeric variable representing the year for time association in the analysis.{p_end}  

{p 4 4 2} 
{opt NONOTES}{p_end}  
Suppresses the default notes added to the resulting graphs or figures.{p_end}  

{p 4 4 2} 
{opt save(string)}{p_end}  
Specifies the file path for saving the processed data or results from the decomposition analysis.{p_end}  

{p 4 4 2} 
{opt excel(string)}{p_end}  
Specifies the file path for exporting results to an Excel file for further analysis or visualization purposes.{p_end}  

{p 4 4 2} 
{opt by(varname numeric)}{p_end}  
Specifies a grouping variable to stratify the poverty decomposition results by subpopulations (e.g., regions, demographic groups).{p_end}  

{title:Remarks}
{pstd}This program supports weighted data ({opt aw}, {opt pw}, or {opt fw}) and accounts for missing observations during analysis. The Datt-Ravallion 
and Shorrocks-Kolenikov methods offer distinct perspectives on understanding poverty dynamics, and the program outputs figures and statistics for visual 
analysis and policy insights.

{title:Examples}
