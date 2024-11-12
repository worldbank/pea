{smcl}
{hline 80}
{bf PROGRAM:} {cmd:pea_core}
{hline 80}
{title:Title}
  {bf pea_core} — Generates Poverty and Welfare Indicators

{title:Syntax}
  {cmd:pea_core} [{it:if}] [{it:in}], {cmdab:Country(string)} {cmdab:Year(varname numeric)} {cmdab:Indicator(varname)} 
  {cmdab:povertyline(real)} {cmdab:population(varname)} {cmdab:welfare(varname)} {cmdab:excel(string)} 
  {cmdab:save(string)} {cmdab:graph}

{title:Description}
  {cmd:pea_core} calculates key poverty and welfare indicators from survey or census data for specified countries and years. It computes various poverty measures such as headcount ratio, poverty gap, and squared poverty gap, as well as welfare indicators like income distribution (Gini index), and growth incidence curves (GIC). Results are presented in tables and can be exported to Excel or saved in a specified file format. Additionally, the program offers graphical representations of the indicators for visualization.

{title:Options}
  {phang} {opt Country(string)} specifies the country code for which the poverty indicators are to be calculated.
  {phang} {opt Year(varname numeric)} specifies the year variable for the analysis.
  {phang} {opt Indicator(varname)} specifies the specific indicator(s) to include in the analysis, such as poverty headcount, income distribution, or growth incidence curve.
  {phang} {opt povertyline(real)} specifies the poverty line to use for poverty calculations. The default is the international poverty line.
  {phang} {opt population(varname)} specifies the variable that represents the population size for the analysis.
  {phang} {opt welfare(varname)} specifies the welfare variable (e.g., income or consumption) used for calculations.
  {phang} {opt excel(string)} specifies the file path for exporting results to Excel. If omitted, results are saved to a temporary file.
  {phang} {opt save(string)} specifies the file path for saving intermediate results.
  {phang} {opt graph} generates a graph of the poverty and welfare indicators for visualization.

{title:Details}
  {cmd:pea_core} calculates several important poverty and welfare statistics for the specified country and year, including:
  - Poverty headcount ratio (e.g., the proportion of individuals below the poverty line)
  - Poverty gap (the average shortfall from the poverty line)
  - Squared poverty gap (a measure of inequality among the poor)
  - Gini index (for measuring income or wealth inequality)
  - Growth Incidence Curves (GIC) to measure income or welfare growth across the distribution
  - Other welfare indicators
  
  The results are presented in tables, showing the poverty and inequality measures for the specified year and country. The program also allows exporting the results to Excel or saving the intermediate data in a file. The `graph` option generates visualizations of the indicators, helping with a better understanding of the distribution of poverty and inequality.

{title:Example}
  To calculate the poverty and welfare indicators for Ghana (GHA) in 2020, using a poverty line of $1.90 per day, and export the results to an Excel file:
{cmd:
    . pea_core, Country("GHA") Year(2020) Indicator("PovertyHeadcount") povertyline(1.90) welfare("income") excel("ghana_poverty_analysis.xlsx")
}

{title:Author}
  Developed by [Your Name/Organization].

{title:Also see}
  {help pea_table14}: For generating poverty and equity analysis tables.
{hline 80}
