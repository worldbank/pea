{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea_figure14}{right:November 2024}
{hline}

{title:Title}

{bf:pea_figure14} — 



//Fig 14. Multidimensional poverty: Multidimensional Poverty Measure (World Bank)


//pea_figure14_help.scml
// Help file for the Multidimensional Poverty Measure (World Bank) visualization program
// Designed to generate Figure 14 on Multidimensional Poverty using the PEA framework.

help for pea_figure14

title: Multidimensional Poverty: Multidimensional Poverty Measure (World Bank) 

{title:Syntax}

{p 4 15}
{opt pea_figure14}
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[aw pw fw], 
[Country(string) 
Welfare(varname numeric) 
Year(varname numeric) 
setting(string) 
excel(string) 
save(string) 
NONOTES 
BENCHmark(string) 
within(integer 3) 
scheme(string) 
palette(string)]{p_end} 



{title:Description}

{p 4 4 2} 
This program generates visualizations associated with the Multidimensional Poverty Measure (MPM) developed by the World Bank.  
It provides graphs showing various poverty indicators, comparisons across countries and regions, and poverty rate estimates  
across welfare, education, infrastructure, and other relevant dimensions.



{title:Options}
{p 4 4 2} {opt Country(string)}    
        Specifies the country code to analyze. Example: "USA", "IND", "BRA".  
        This is a required argument.

{p 4 4 2} {opt Welfare(varname numeric)}  
        The name of the numeric variable representing welfare or income measures used for Multidimensional Poverty analysis. Required. Example: `welfare_var`.

{p 4 4 2} {opt Year(varname numeric)}  
        The numeric variable representing survey years. Required. Example: `survey_year`.

{p 4 4 2} {opt setting(string)}  
        Specifies the type of setting or context for analysis (e.g., urban, rural, national). Default is left unspecified unless otherwise provided.

{p 4 4 2} {opt excel(string)}  
        Path to an Excel file location for saving results. If omitted, defaults are used.

{p 4 4 2} {opt save(string)}  
        Path or name for saving temporary datasets. If omitted, defaults are applied.

{p 4 4 2} {opt NONOTES}  
        Omits the inclusion of notes on figures and outputs.

{p 4 4 2} {opt BENCHmark(string)}  
        A list of benchmark countries to use for comparative visualization and analysis. Example: `"USA IND BRA"`.

{p 4 4 2} {opt within(integer 3)}  
        Specifies the maximum number of years to look back for analysis. Defaults to 3 years. Must not exceed 10.

{p 4 4 2} {opt scheme(string)}  
        The color scheme to be used in visualizations. Defaults to a contrast palette with pre-defined colors.

{p 4 4 2} {opt palette(string)}
        Defines the color palette for visualizations. Options include viridis, grayscale, or custom color settings.

{title:Examples}
    

description continued:
This program generates:
    - Comparative bar graphs by region and welfare trends.
    - Scatter plots comparing multidimensional poverty rates across countries or regions.
    - Aggregated statistics for the MPM framework.
Notes:
The data used is extracted from available survey datasets and depends on weights and temporal alignment with multidimensional poverty frameworks. Ensure that the survey years (`within`) and welfare data are harmonized before running.

error handling:
The program checks for missing data observations, too-wide ranges of time periods, and mismatched settings.
