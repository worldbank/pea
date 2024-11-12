{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_table10}
{hline 80}
{title:Title}
  {bf pea_table10} — Generates Poverty and Equity Analysis Tables

{title:Syntax}
  {cmd:pea_table10} [{it:if}] [{it:in}], {cmdab:Country(string)} {cmdab:Year(varname numeric)} {cmdab:Indicator(varname)} 
  {cmdab:excel(string)} {cmdab:save(string)}

{title:Description}
  {cmd:pea_table10} calculates and generates tables of poverty and equity-related indicators for poverty analysis. It extracts data for specified countries and years, and produces a detailed table summarizing poverty and inequality measures, including poverty headcount ratio, income distribution, and equity indices. Results can be exported to Excel or saved in a specified file format.

{title:Options}
  {phang} {opt Country(string)} specifies the country code for which the poverty indicators are to be generated.
  {phang} {opt Year(varname numeric)} specifies the year variable for the analysis.
  {phang} {opt Indicator(varname)} specifies the specific indicator(s) to include in the analysis, such as poverty headcount or Gini index.
  {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file.
  {phang} {opt save(string)} specifies the file path for saving intermediate data.

{title:Details}
  {cmd:pea_table10} imports relevant poverty and equity datasets, extracts the country-specific and region-specific data for the selected year, and generates a table with:
  - Poverty headcount ratios (e.g., at $1.90 and $3.20 poverty lines)
  - Gini coefficients
  - Theil indices
  - Distributional indices like the Palma ratio
  - Additional poverty and inequality measures with contextual information (e.g., inequality thresholds).
  
  The final output is a comprehensive summary table ordered by the specified indicator(s), with results available for immediate reporting. Results can be exported to Excel if the `excel` option is used, or saved in a specified file format.

{title:Example}
  To generate the poverty and equity analysis table for a specific country and year, and export the results to an Excel file:
{cmd:. pea_table10, Country("GHA") Year(year) Indicator("PovertyHeadcount") excel("output_table10.xlsx")}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  {help pea_table9}: For generating Scorecard Vision Indicator Tables.
{hline 80}
