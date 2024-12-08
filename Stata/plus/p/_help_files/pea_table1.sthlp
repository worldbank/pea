{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table1}{right:November 2024}
{hline}

{title:Title}

{bf:pea table1} — Generate poverty and welfare analysis tables with specified parameters.

{title:Syntax}

{p 4 15}
{opt pea table1}
	[{it:weight}] 
	[{opt if} {it:exp}] 
	[{opt in} {it:exp}] 
	[{opt ,}  
	{opt Country(string)} 
    {opt NATWelfare(varname)} 
	{opt NATPovlines(varlist)} 
    {opt PPPWelfare(varname)} 
	{opt PPPPovlines(varlist)} 
    {opt FGTVARS} 
	[{opt using} {it:string}] 
    {opt Year(varname)} 
	{opt CORE}
	{opt setting(string)} 
    {opt LINESORTED} 
	{opt excel(string)} 
	{opt save(string)} 
    {opt ONELine(varname)}
	{opt ONEWelfare(varname)}]{p_end} 


{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}


{title:Description}

{p 4 4 2}
{opt pea table1} generates a table that provides detailed poverty and welfare analysis
    based on specified national and international poverty lines and welfare indicators. This command
    is useful for analyzing distributional welfare measures like the Gini index, mean income, and
    income distribution across different population segments.

{title:Options}
{p 4 4 2} 
{opt Country(string)} specifies the country code or name for the analysis.
    
{p 4 4 2} 
{opt NATWelfare(varname)} is the variable containing welfare values for national analysis.

{p 4 4 2} 
{opt NATPovlines(varlist)} lists the national poverty lines used in the analysis.
    
{p 4 4 2} 
{opt PPPWelfare(varname)} is the welfare variable adjusted for purchasing power parity (PPP).
    
{p 4 4 2} 
{opt PPPPovlines(varlist)} lists the PPP-adjusted poverty lines.
    
{p 4 4 2} 
{opt FGTVARS} generates Foster-Greer-Thorbecke (FGT) poverty indices (headcount, gap, and severity).
    
{p 4 4 2} 
{opt using(string)} specifies the dataset to use; the dataset will be loaded if provided.
    
{p 4 4 2} 
{opt Year(varname)} is the variable indicating the year for each observation.
    
{p 4 4 2} 
{opt CORE} enables calculation of World Bank's Multidimensional Poverty Measure (MPM) for the specified {opt Country} and {opt Year}.
    
{p 4 4 2} 
{opt setting(string)} specifies the core setting for MPM calculation.
    
{p 4 4 2} 
{opt LINESORTED} indicates that the poverty lines are already sorted; skipping internal sorting.
    
{p 4 4 2} 
{opt excel(string)} specifies an Excel file for saving the results. If this option is not specified, a temporary file will be used.

{p 4 4 2} 
{opt save(string)} specifies a file path to save the generated table in Stata format.

{p 4 4 2} 
{opt ONELine(varname)} is the poverty line variable for calculating additional poverty statistics.

{p 4 4 2} 
{opt ONEWelfare(varname)} is the welfare variable associated with the {opt ONELine} poverty line.

{title:Remarks}

    {pstd} The {opt pea_table1} command performs a series of checks and transformations on the specified data. It calculates
    poverty and welfare statistics, including FGT indices, income distribution metrics, and population in high-risk areas
    for climate-related hazards (if available for the specified country).
    
    {pstd} The output table includes poverty headcount, poverty gap, poverty severity, welfare mean, income inequality indices,
    and breakdowns by population quintiles. This allows a comprehensive view of poverty distribution across different 
    welfare measures.

{title:Examples}
    
	{pstd} Basic usage with national welfare and poverty lines:
    
	{phang2} 
	pea_table1, Country("GHA") NATWelfare(income) NATPovlines(pline1 pline2) PPPWelfare(ppp_income) PPPPovlines(ppp_pl1 ppp_pl2) FGTVARS using("data.dta") Year(year)

    {pstd} Save output to Excel and Stata format:
   
    {phang2}
	pea_table1, Country("GHA") NATWelfare(income) NATPovlines(pline1 pline2) PPPWelfare(ppp_income) PPPPovlines(ppp_pl1 ppp_pl2) FGTVARS using("data.dta") Year(year) excel("results.xlsx") save("output.dta")

