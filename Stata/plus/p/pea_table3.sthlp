{smcl}
{hline}
{title:pea_table3} — Generate detailed poverty and welfare analysis tables with specified parameters.

{hline}
{title:Syntax}
    {bf:pea_table3} [{it:if}] [{it:in}] [{it:weight}], {cmdab:Country(string)} 
    {cmdab:NATWelfare(varname)} {cmdab:NATPovlines(varlist)} 
    {cmdab:PPPWelfare(varname)} {cmdab:PPPPovlines(varlist)} 
    {cmdab:FGTVARS} [{cmd:using} {it:string}] 
    {cmdab:Year(varname)} {cmdab:CORE} {cmdab:setting(string)} 
    {cmdab:LINESORTED} {cmdab:excel(string)} {cmdab:save(string)} 
    {cmdab:ONELine(varname)} {cmdab:ONEWelfare(varname)} 
    {cmdab:MISSING} {cmdab:age(varname)} {cmdab:male(varname)} 
    {cmdab:hhhead(varname)} {cmdab:edu(varname)}

{title:Description}
    {pstd} {cmd:pea_table3} generates a detailed table that provides poverty and welfare statistics based on both 
    national and international poverty lines, as well as specified welfare measures. It also enables subgroup analysis 
    by age, gender, household head status, and education level. Additionally, it supports exporting results to Excel 
    and saving them in Stata format.

{title:Options}
    {phang} {cmd:Country(string)} specifies the country code or name for the analysis.
    
    {phang} {cmd:NATWelfare(varname)} is the variable containing national welfare values for analysis, such as income or consumption.

    {phang} {cmd:NATPovlines(varlist)} lists the national poverty lines to be used for poverty analysis.
    
    {phang} {cmd:PPPWelfare(varname)} is the welfare variable adjusted for purchasing power parity (PPP), typically for international comparisons.
    
    {phang} {cmd:PPPPovlines(varlist)} lists the PPP-adjusted poverty lines.
    
    {phang} {cmd:FGTVARS} generates Foster-Greer-Thorbecke (FGT) poverty indices, including headcount, poverty gap, and squared poverty gap.

    {phang} {cmd:using(string)} specifies the dataset to use for the analysis.
    
    {phang} {cmd:Year(varname)} is the variable indicating the year for each observation.
    
    {phang} {cmd:CORE} enables the calculation of World Bank's Multidimensional Poverty Measure (MPM) for the specified {cmd:Country} and {cmd:Year}.
    
    {phang} {cmd:setting(string)} specifies the core setting to be used for the MPM calculation.
    
    {phang} {cmd:LINESORTED} indicates that the poverty lines are already sorted and skips internal sorting for efficiency.
    
    {phang} {cmd:excel(string)} specifies an Excel file for saving the results. If this option is not specified, a temporary file is used by default.

    {phang} {cmd:save(string)} specifies a file path to save the generated table in Stata dataset format.

    {phang} {cmd:ONELine(varname)} is the poverty line variable for calculating additional poverty statistics.

    {phang} {cmd:ONEWelfare(varname)} is the welfare variable associated with the {cmd:ONELine} poverty line.

    {phang} {cmd:MISSING} handles missing data in key demographic variables like age, gender, and education.

    {phang} {cmd:age(varname)} specifies the variable representing age groups for subgroup analysis.

    {phang} {cmd:male(varname)} specifies the variable representing gender (typically 1 for male, 0 for female).

    {phang} {cmd:hhhead(varname)} specifies the variable indicating household head status (typically 1 for head, 0 for non-head).

    {phang} {cmd:edu(varname)} specifies the variable indicating education level for subgroup analysis.

{title:Remarks}
    {pstd} The {cmd:pea_table3} command performs poverty and welfare analysis based on a range of national and 
    international measures. It includes subgroup analysis by variables such as age, gender, education, and household head status. 
    The output table includes poverty headcount, poverty gap, poverty severity, welfare means, and inequality indices such as 
    the Gini index. It can be used to generate summary statistics and break down welfare measures by specific subgroups. 
    If the MPM option is used, it calculates the multidimensional poverty measure based on the World Bank’s framework.

    {pstd} Missing data in the core demographic variables can be handled and cleaned using the `MISSING` option to ensure accurate results.

{title:Examples}
    {pstd} Basic usage with national welfare and poverty lines, and subgroups by age and gender:
    
	{phang2}{cmd:. pea_table3, Country("GHA") NATWelfare(income) NATPovlines(200 400) PPPWelfare(ppp_income) PPPPovlines(150 250) FGTVARS using("data.dta") Year(year) MISSING age(age_group) male(gender)}

    {pstd} Run the command with results saved to both Excel and Stata formats:
    
	{phang2}{cmd:. pea_table3, Country("GHA") NATWelfare(income) NATPovlines(200 300) PPPWelfare(ppp_income) PPPPovlines(150 250) FGTVARS using("data.dta") Year(year) excel("poverty_results.xlsx") save("poverty_output.dta")}

    {pstd} Run the command with subgroup analysis by education and household head status:
    
	{phang2}{cmd:. pea_table3, Country("GHA") NATWelfare(income) NATPovlines(250 350) PPPWelfare(ppp_income) PPPPovlines(180 220) FGTVARS using("data.dta") Year(year) edu(education) hhhead(head_status)}

{title:Author}
  Developed by [Your Name/Organization].
