{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_table9}
{hline 80}
{title:Title}
  {bf pea_table9} — Generates Scorecard Vision Indicator Tables

{title:Syntax}
  {cmd:pea_table9} [{it:if}] [{it:in}], {cmdab:Country(string)} {cmdab:Year(varname numeric)} {cmdab:CORE setting(string)} 
  {cmdab:excel(string)} {cmdab:save(string)}

{title:Description}
  {cmd:pea_table9} calculates and generates tables of vision-related indicators from the World Bank Scorecard. It extracts country-specific and region-specific indicators, including key economic and social measures, and produces an ordered table for use in reporting. The results can be exported to an Excel file.

{title:Options}
  
  {phang} {opt Country(string)} specifies the country code for which the indicators are to be generated.
  
  {phang} {opt Year(varname numeric)} specifies the year variable for the analysis.
  
  {phang} {opt CORE setting(string)} specifies custom settings, such as region or data type.
  
  {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file.
 
  {phang} {opt save(string)} specifies the file path for saving intermediate data.

{title:Details}
  {cmd:pea_table9} imports multiple Scorecard Vision Indicator files, extracts the relevant country and region data, and generates a table that includes:
  - Indicator names and codes
  - Country and region data for the latest year available
  - Additional context such as year of the data for country and region, and whether indicators meet certain thresholds (e.g., high inequality based on Gini coefficient).
  The final output is a table summarizing the indicators, ordered by predefined categories.

  The program supports exporting the results to an Excel file if the `excel` option is specified, or saves the results in a temporary file by default.

{title:Example}
  To generate the Scorecard Vision Indicators table for a specific country and year, and export the results to an Excel file:

{cmd:. pea_table9, Country("GHA") Year(year) excel("output_table9.xlsx")}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  {help pea_table8}: To generate poverty dynamics tables.
{hline 80}
