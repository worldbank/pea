{smcl}
{hline}
{title:Title}
    {bf:pea_table1} — Generate poverty and welfare analysis tables with specified parameters.

{hline}
{title:Syntax}
    {bf:pea_table1} [{it:if}] [{it:in}] [{it:weight}], {cmdab:Country(string)} 
    {cmdab:NATWelfare(varname)} {cmdab:NATPovlines(varlist)} 
    {cmdab:PPPWelfare(varname)} {cmdab:PPPPovlines(varlist)} 
    {cmdab:FGTVARS} [{cmd:using} {it:string}] 
    {cmdab:Year(varname)} {cmdab:CORE} {cmdab:setting(string)} 
    {cmdab:LINESORTED} {cmdab:excel(string)} {cmdab:save(string)} 
    {cmdab:ONELine(varname)} {cmdab:ONEWelfare(varname)} 

{title:Description}
    {pstd} {cmd:pea_table1} generates a table that provides detailed poverty and welfare analysis
    based on specified national and international poverty lines and welfare indicators. This command
    is useful for analyzing distributional welfare measures like the Gini index, mean income, and
    income distribution across different population segments.

{title:Options}
    {phang} {cmd:Country(string)} specifies the country code or name for the analysis.
    
    {phang} {cmd:NATWelfare(varname)} is the variable containing welfare values for national analysis.

    {phang} {cmd:NATPovlines(varlist)} lists the national poverty lines used in the analysis.
    
    {phang} {cmd:PPPWelfare(varname)} is the welfare variable adjusted for purchasing power parity (PPP).
    
    {phang} {cmd:PPPPovlines(varlist)} lists the PPP-adjusted poverty lines.
    
    {phang} {cmd:FGTVARS} generates Foster-Greer-Thorbecke (FGT) poverty indices (headcount, gap, and severity).
    
    {phang} {cmd:using(string)} specifies the dataset to use; the dataset will be loaded if provided.
    
    {phang} {cmd:Year(varname)} is the variable indicating the year for each observation.
    
    {phang} {cmd:CORE} enables calculation of World Bank's Multidimensional Poverty Measure (MPM) for the specified {cmd:Country} and {cmd:Year}.
    
    {phang} {cmd:setting(string)} specifies the core setting for MPM calculation.
    
    {phang} {cmd:LINESORTED} indicates that the poverty lines are already sorted; skipping internal sorting.
    
    {phang} {cmd:excel(string)} specifies an Excel file for saving the results. If this option is not specified,
           a temporary file will be used.

    {phang} {cmd:save(string)} specifies a file path to save the generated table in Stata format.

    {phang} {cmd:ONELine(varname)} is the poverty line variable for calculating additional poverty statistics.

    {phang} {cmd:ONEWelfare(varname)} is the welfare variable associated with the {cmd:ONELine} poverty line.

{title:Remarks}
    {pstd} The {cmd:pea_table1} command performs a series of checks and transformations on the specified data. It calculates
    poverty and welfare statistics, including FGT indices, income distribution metrics, and population in high-risk areas
    for climate-related hazards (if available for the specified country).
    
    {pstd} The output table includes poverty headcount, poverty gap, poverty severity, welfare mean, income inequality indices,
    and breakdowns by population quintiles. This allows a comprehensive view of poverty distribution across different 
    welfare measures.

{title:Examples}
    
	{pstd} Basic usage with national welfare and poverty lines:
    
	{phang2}{cmd:. pea_table1, Country("GHA") NATWelfare(income) NATPovlines(pline1 pline2) PPPWelfare(ppp_income) PPPPovlines(ppp_pl1 ppp_pl2) FGTVARS using("data.dta") Year(year)}

    {pstd} Save output to Excel and Stata format:
   
    {phang2}{cmd:. pea_table1, Country("GHA") NATWelfare(income) NATPovlines(pline1 pline2) PPPWelfare(ppp_income) PPPPovlines(ppp_pl1 ppp_pl2) FGTVARS using("data.dta") Year(year) excel("results.xlsx") save("output.dta")}


{title:Stored Results}
   
    {pstd} {cmd:pea_table1} stores the following results in {cmd:r()}:
    
    {phang} {cmd:r(gini)}          Gini index for the selected welfare distribution
    
	{phang} {cmd:r(mean)}          Mean welfare value
    
	{phang} {cmd:r(fgt0)}          Poverty headcount
    
	{phang} {cmd:r(fgt1)}          Poverty gap
   
    {phang} {cmd:r(fgt2)}          Poverty severity
    
	{phang} {cmd:r(mpmpoor)}       World Bank's MPM for the country-year combination


{title:Author}
  Developed by [Your Name/Organization].
