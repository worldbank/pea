{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure4}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea_figure4} — Poverty Decomposition with Datt-Ravallion and Shorrocks-Kolenikov Methods

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
{opt pea_figure4} performs poverty decomposition over time using the Datt-Ravallion and Shorrocks-Kolenikov methods. The program generates visualizations and numerical results showing the contribution of changes in income or welfare across different 
time periods or population groups. The results can help analysts and policymakers identify the drivers behind changes in poverty.

{title:Options}

{p 4 4 2} 
{opt onewelfare(varname numeric)} Specifies the numeric variable representing welfare (e.g., income or consumption) for poverty analysis. 

{p 4 4 2} 
{opt oneline(varname numeric)} Specifies the numeric variable representing the poverty line used for comparison in the analysis.

{p 4 4 2} 
{opt spells(string)} Defines time periods (spells) to perform the decomposition. Use pairs of years separated by a space, with multiple spells separated by semicolons (e.g., "2000 2005; 2005 2010").  

{p 4 4 2} 
{opt year(varname numeric)} Specifies the numeric variable representing the year for time association in the analysis.

{p 4 4 2} 
{opt NONOTES} Suppresses the default notes added to the resulting graphs or figures. 

{p 4 4 2} 
{opt save(string)} Specifies the file path for saving the processed data or results from the decomposition analysis. 

{p 4 4 2} 
{opt excel(string)} Specifies the file path for exporting results to an Excel file for further analysis or visualization purposes.  

{p 4 4 2} 
{opt by(varname numeric)} Specifies a grouping variable to stratify the poverty decomposition results by subpopulations (e.g., regions, demographic groups).

{title:Examples}

{p 4 4 2} 
pea figure4 [aw=weight_p], year(year) onew(welfare) onel(natline) palette(viridis) spells(2018 2021)

