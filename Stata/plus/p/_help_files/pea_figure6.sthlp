{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure6}{right:November 2024}
{hline}



//Figure 6. GDP per capita GDP - Poverty elasticity

// pea_figure6: Generate Figure 6 - GDP per capita and poverty elasticity visualization
//
// This program calculates GDP per capita poverty elasticity across specified years
// and generates a visualization comparing changes in poverty rate and GDP growth.
//
// ----------------------------------------------------------------------------
// PROGRAM DESCRIPTION
//
// pea_figure6 generates Figure 6, illustrating the GDP per capita poverty elasticity
// by examining changes in GDP and poverty rates over specified periods.
//
// Inputs include survey data and GDP per capita data and may optionally integrate 
// comparability options, defined spells (time ranges), and visualization customizations.
//
// ----------------------------------------------------------------------------
// SYNTAX
//
// pea_figure6 [if] [in] [aw pw fw], 
//     [Country(string) Year(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) 
//      FGTVARS NONOTES spells(string) comparability(string) scheme(string) palette(string) 
//      excel(string) save(string)]
//
// Options:
//
//   - if/in/aw/pw/fw: Specifies subsets of data for processing using standard Stata syntax.
//   - Country(string): Name of the country being analyzed.
//   - Year(varname numeric): The variable indicating the survey or panel years to be analyzed.
//   - ONELine(varname numeric): Defines the specific poverty line for the analysis.
//   - ONEWelfare(varname numeric): Designates a specific welfare measure for analysis.
//   - FGTVARS: Flag to specify welfare aggregation and analysis options.
//   - NONOTES: Excludes notes from the final visualization output.
//   - spells(string): Defines time spells (e.g., "2000;2004") for analysis over specified periods.
//   - comparability(string): Specifies variables for comparability filtering by years.
//   - scheme(string): Defines visualization schemes (e.g., colors or graph themes).
//   - palette(string): Specifies a palette for figure visualization.
//   - excel(string): Path to an Excel file for saving the visualization results.
//   - save(string): Save path for visualization outputs.
//
// ----------------------------------------------------------------------------
// EXAMPLES
//
// Example 1: Basic usage
// pea_figure6, Country("Nepal") Year(survey_year) ONELine(welfare_rate) ONEWelfare(fg_rate) spells("2000;2004") scheme("viridis") excel("figure6_results.xlsx")
//
// Example 2: Including comparability
// pea_figure6, Country("India") Year(survey_year) ONELine(welfare_rate) comparability(comparison_year) spells("2000;2004") scheme("viridis") excel("figure6_comparability.xlsx")
//
// Example 3: Save results to a custom path
// pea_figure6, save("output_path") FGTVARS
//
// ----------------------------------------------------------------------------
// DESCRIPTION OF OPTIONS
//
// **Country(string):**
// Specifies the name of the country to analyze and visualize.
//
// **Year(varname numeric):**
// A variable containing the year of survey data for comparison.
//
// **ONELine(varname numeric):**
// Defines the poverty line used as a reference to analyze changes in poverty rates.
//
// **ONEWelfare(varname numeric):**
// Defines the welfare variable related to survey data analysis.
//
// **spells(string):**
// Defines two or more time periods separated by semicolons (e.g., "2000;2004") for comparison.
//
// **comparability(string):**
// Filters comparability across years. Useful when only certain survey years align with GDP data.
//
// **scheme(string):**
// Allows customization of visualization schemes, e.g., "viridis" or "bw" for color palettes.
//
// **palette(string):**
// Allows you to select a custom color palette (e.g., viridis or another predefined color scheme).
//
// **excel(string):**
// Defines the path to save visualization outputs (e.g., in Excel format).
//
// **save(string):**
// Specifies a save path for visualization outputs directly.
//
// **FGTVARS:**
// If specified, will include functionality for aggregation across defined welfare changes.
//
// **NONOTES:**
// Excludes figure annotations from the visualization.
//
// ----------------------------------------------------------------------------
// OUTPUT
//
// This program generates a two-dimensional visualization comparing GDP changes and 
// changes in poverty rates over the defined spells using elasticity metrics.
//
// The output will save visualization graphs (using Stata's `twoway`) to an Excel
// file or directly depending on the `excel()` or `save()` options.
//
// ----------------------------------------------------------------------------
// ERROR HANDLING
//
// The program performs checks to ensure:
// - Required parameters are defined (e.g., at least two years for the spells).
// - Comparability lists are correctly specified.
// - Input files are accessible and contain required data.
//
// ----------------------------------------------------------------------------
// AUTHOR
//
// Written by: [Your Name / Institution Name]
// Date: [Insert Date]
// Contact: [Insert contact information if relevant]
