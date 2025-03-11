{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure7b}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure7b} — Share of poor and non-poor by demographic groups.

{title:Syntax}

{p 4 15}
{opt pea figure7b}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
        [,{opt ONELine(varlist numeric)}  
        {opt ONEWelfare(varname numeric)}  
        {opt Year(varname numeric)}  
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
{opt pea figure7b} shows the share of demographic subgroups which are poor and non-poor for sa pecified poverty threshold, such as `pline365`. This program performs necessary data preparation,
computes poverty statistics, and exports figures/poverty analysis results.
	
{title:Options}

{p 4 4 2} 
{opt ONEWelfare(varname numeric)}: Specifies the numeric variable representing welfare (e.g., income or consumption) for poverty analysis. 

{p 4 4 2} 
{opt ONELine(varname numeric)}: Specifies the numeric variable representing the poverty line used for comparison in the analysis.

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
{bf: pea figure7b} [aw=weight_p], onewelfare(welfare) oneline(natline) year(year) setting(GMD)
