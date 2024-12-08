{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure13}{right:November 2024}
{hline}

//Figure 13. Distribution of welfare by deciles
//todo: add comparability, add the combine graph option

help pea_figure13
/********************************************************************
  Program Name: pea_figure13
  Purpose:     Distribution of welfare by deciles visualization
  Author:      [Your Name or Institution]
  Version:     1.0
  Date:        [Date]
********************************************************************/

title    Distribution of welfare by deciles
subtitle Welfare analysis visualization by survey comparisons over time

description ///
    `pea_figure13' generates a graphical visualization of welfare
    distribution by deciles over specified years or comparability groups. 
    This includes the visualization of survey-based welfare shares 
    for different welfare deciles through spike charts or area charts,
    depending on the temporal structure of the data.

syntax ///
    pea_figure13 [if] [in] [aw pw fw], ///
        [ONEWelfare(varname numeric) Year(varname numeric) NOOUTPUT NONOTES ///
         EQUALSPACING excel(string) save(string) scheme(string) palette(string) ///
         COMParability(varname numeric)]

options ///
    ONEWelfare(varname numeric) ///
        Specifies the numeric welfare variable to analyze and visualize. 
    Year(varname numeric) ///
        The year variable used for grouping comparisons over time. 
    NOOUTPUT ///
        Suppresses generating output during analysis, typically useful during batch processing.
    NONOTES ///
        Disables notes related to figure outputs.
    EQUALSPACING ///
        Adjusts year group spacing for temporal analysis visualization by removing gaps.
    excel(string) ///
        Path to an existing Excel file to export the visualization results.
    save(string) ///
        Path where the visualization output will be stored.
    scheme(string) ///
        Specifies the color scheme to be used for visual contrast.
    palette(string) ///
        Defines the palette of colors to use in graphs.
    COMParability(varname numeric) ///
        Specifies the comparability variable for conducting cross-survey comparisons.

examples ///
    Example 1: Visualize welfare data by deciles without comparability adjustment
        . pea_figure13 onewelfare(welfare) year(yr)

    Example 2: Export visualization to Excel
        . pea_figure13 onewelfare(welfare) year(yr) excel("path\\data.xlsx")

    Example 3: Use a specific scheme with custom color palettes
        . pea_figure13 onewelfare(welfare) year(yr) scheme("viridis") palette("viridis")

    Example 4: Adjust temporal gaps for visualization
        . pea_figure13 onewelfare(welfare) year(yr) equalspacing

    Example 5: Generate a comparison across years
        . pea_figure13 onewelfare(welfare) comparability(compvar)

notes ///
    This program assumes survey data is correctly prepared and that comparability checks are properly implemented.
    If you encounter errors during execution, ensure that variables passed through `ONEWelfare` or `Year` are well-formed.

seealso: ///
    Related programs: `apoverty', `twoway', `collapse', `gr' visualization.
    For further details, refer to the World Bank Data visualization resources.

author: ///
    Developed by [Your Name or Institution].
    
version: ///
    Version 1.0 [Release Date].

acknowledgment: ///
    This program depends on survey design methodologies and visualization techniques related to Small Area Estimation (SAE).
