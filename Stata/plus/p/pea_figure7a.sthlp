{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure7a}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure7a} — Welfare Figure with poverty line breakdowns.

{title:Syntax}

{p 4 15}
{opt pea figure7a}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
        [,{opt NATWelfare(varname numeric)}
        {opt NATPovlines(varlist numeric)}  
        {opt PPPWelfare(varname numeric)}  
        {opt PPPPovlines(varlist numeric)}  
		{opt PPPyear(integer)}
        {opt Year(varname numeric)}  
        {opt LINESORTED}  
        {opt age(varname numeric)}  
        {opt male(varname numeric)}  
        {opt hhhead(varname numeric)} 
        {opt edu(varname numeric)} 
        {opt urban(varname numeric)}  
        {opt setting(string)}  
        {opt scheme(string)}  
        {opt palette(string)}  
        {opt excel(string)}  
        {opt save(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea figure7a} generates welfare visualizations with breakdowns for specified poverty thresholds, such as `pline365`, `pline215`. This program performs necessary data preparation,
computes poverty statistics, and exports figures/poverty analysis results.
	
{title:Options}

{p 4 4 2}
{opt NATWelfare(varname numeric)}: Specifies the variable name corresponding to national welfare.

{p 4 4 2}
{opt NATPovlines(varlist numeric)}: List of numeric poverty thresholds used for national poverty calculation.

{p 4 4 2}
{opt PPPWelfare(varname numeric)}: Specifies the variable name for purchasing power parity welfare measures.

{p 4 4 2}
{opt PPPPovlines(varlist numeric)}: List of numeric PPP poverty thresholds for PPP calculations.

{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2}
{opt Year(varname numeric)}: Name of the variable indicating the year in your dataset.

{p 4 4 2}
{opt age(varname numeric)}: Variable that defines age groups for subgroup analysis.

{p 4 4 2}
{opt male(varname numeric)}: Variable defining gender for subgroup analysis.

{p 4 4 2}
{opt hhhead(varname numeric)}: Indicates whether an individual is a household head.

{p 4 4 2}
{opt edu(varname numeric)}: Specifies the education variable for subgroup breakdowns.

{p 4 4 2}
{opt urban(varname numeric)}: Urban/Rural classification variable for subgroup analysis.

{p 4 4 2}
{opt SETting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options 
(hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified.

{p 4 4 2}
{opt scheme(string)}: Graph/plotting scheme (not implemented in full).

{p 4 4 2}
{opt palette(string)}: Color palette for visualization customization.

{p 4 4 2}
{opt excel(string)}: Path for exporting results in Excel format.

{p 4 4 2}
{opt save(string)}: File path for saving computed data.

{title:Examples}

{p 4 4 2}
{bf: pea figure7a} [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline685) year(year) age(age) male(male) edu(educat4) urban(urban)
