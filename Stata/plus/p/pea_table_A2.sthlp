{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table_A2}{right:November 2024}
{hline}

{title:Title}

{bf:pea table_A2} — Generate detailed poverty and welfare analysis tables with specified parameters.

{title:Syntax}

{p 4 15}
{cmd:pea table_A2}
[{it:weight}] 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:exp}] 
[{cmd:,} 
{opt Country(string)} 
{opt NATWelfare(varname)}
{opt NATPovlines(varlist)} 
{opt PPPWelfare(varname)} 
{opt PPPPovlines(varlist)} 
{opt FGTVARS} [{using} {it:string}] 
{opt Year(varname)} 
{opt CORE} 
{opt setting(string)} 
{opt LINESORTED} 
{opt excel(string)} 
{opt save(string)} 
{opt ONELine(varname)} 
{opt ONEWelfare(varname)} 
{opt MISSING}
{opt age(varname)} 
{opt male(varname)} 
{opt hhhead(varname)}
{opt edu(varname)}]{p_end}

{p 4 4 2}The command supports {cmd:aweight}s, {cmd:fweight}s, and {cmd:pweight}s. See {help weights} for further details.{p_end}


{title:Description}

{p 4 4 2}
{cmd:pea table_A2} generates a detailed table that provides poverty and welfare statistics based on both 
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
    
    {phang} {cmd:CORE} enables the calculation of World Banks Multidimensional Poverty Measure (MPM) for the specified {cmd:Country} and {cmd:Year}.
    
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

{p 4 4 2}
The {cmd:table_A2} command performs poverty and welfare analysis based on a range of national and 
    international measures. It includes subgroup analysis by variables such as age, gender, education, and household head status. 
    The output table includes poverty headcount, poverty gap, poverty severity, welfare means, and inequality indices such as 
    the Gini index. It can be used to generate summary statistics and break down welfare measures by specific subgroups. 
    If the MPM option is used, it calculates the multidimensional poverty measure based on the World Bank’s framework.

{p 4 4 2}
Missing data in the core demographic variables can be handled and cleaned using the `MISSING` option to ensure accurate results.

{title:Examples}

{p 4 4 2}
Basic usage with national welfare and poverty lines, and subgroups by age and gender:
    
	{phang2}{cmd:. table_A2, Country("GHA") NATWelfare(income) NATPovlines(200 400) PPPWelfare(ppp_income) PPPPovlines(150 250) FGTVARS using("data.dta") Year(year) MISSING age(age_group) male(gender)}

    {pstd} Run the command with results saved to both Excel and Stata formats:
    
	{phang2}{cmd:. table_A2, Country("GHA") NATWelfare(income) NATPovlines(200 300) PPPWelfare(ppp_income) PPPPovlines(150 250) FGTVARS using("data.dta") Year(year) excel("poverty_results.xlsx") save("poverty_output.dta")}

    {pstd} Run the command with subgroup analysis by education and household head status:
    
	{phang2}{cmd:. table_A2, Country("GHA") NATWelfare(income) NATPovlines(250 350) PPPWelfare(ppp_income) PPPPovlines(180 220) FGTVARS using("data.dta") Year(year) edu(education) hhhead(head_status)}

