{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure16}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure16} — Demographic and economic composition of the poor.

{title:Syntax}

{p 4 15}
{opt pea figure16}
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
	[,{opt Country(string)} 
	{opt Welfare(varname numeric)} 
	{opt ONELine(varlist numeric)}
	{opt PPPyear(integer)}
	{opt Year(varname numeric)} 
	{opt excel(string)} 
	{opt save(string)}
	{opt age(varname numeric)} 
	{opt male(varname numeric)} 
	{opt hhhead(varname numeric)} 
	{opt hhid(varname numeric)} 
	{opt pid(varname numeric)} 
	{opt edu(varname numeric)} 
	{opt urban(varname numeric)} 
	{opt married(varname numeric)} 
	{opt hhsize(varname numeric)} 
	{opt industrycat4(varname numeric)} 
	{opt lstatus(varname numeric)} 
	{opt empstat(varname numeric)}
	{opt earnage(integer)}
	{opt MISSING}]{p_end}
	{opt scheme(string)} 
	{opt palette(string)} 
	{opt save(string)} 
	{opt excel(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea figure16} generates two bar graphs, one displaying the demographic and one the economic composition of the poor. Only groups which make up more than 5% of the poor population are displayed. Data is taken from the last survey year. In this figure, adults are defined as 15 or older, to ensure consistency with the age cut-off for earners.

{title:Options}

{p 4 4 2} 
{opt Country(string)}: 
Specifies the name or code of the country to visualize data for.

{p 4 4 2} 
{opt Welfare(varname numeric)}:
 specifies the welfare variable to be used for poverty calculations.
 
{p 4 4 2} 
{opt ONELine(varname numeric)}:
specifies the poverty line used to define the poor.
  
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt Year(varname numeric)}:
specifies the year variable for the analysis (only the last year is taken).

{p 4 4 2} 
{opt scheme(string)}: 
Specifies the color scheme to use in creating visualization graphics.

{p 4 4 2} 
{opt palette(string)}: 
Defines a color palette to differentiate bars in the graph visualization.

{p 4 4 2}
{opt earnage(integer)}: specifies the age cut-off for working status for the economic composition. Working status depends both on labor force status (lstatus) and employment status (empstat). Individuals will only be considered working if as old or older than the cut-off.
Default: 16

{p 4 4 2} 
{opt excel(string)}:
Path to an Excel file to save visualization results to.

{p 4 4 2}
{opt age(varname numeric)}: specifies the age variable for the analysis.
Default under setting(GMD): age

{p 4 4 2}
{opt male(varname numeric)}: specifies the gender variable (e.g., male/female).
Default under setting(GMD): male

{p 4 4 2}
{opt hhhead(varname numeric)}: specifies the household head status variable.
Default under setting(GMD): head

{p 4 4 2}
{opt edu(varname numeric)}: specifies the education level variable.
Default under setting(GMD): educat4    

{p 4 4 2}
{opt urban(varname numeric)}: specifies the urban/rural classification variable.
Default under setting(GMD): urban

{p 4 4 2}
{opt married(varname numeric)}: specifies the marital status variable.
Default under setting(GMD): married

{p 4 4 2}
{opt hhsize(varname numeric)}: specifies the household size variable.
Default under setting(GMD): hsize

{p 4 4 2}
{opt hhid(string)}: specifies the household ID variable.
Default under setting(GMD): hhid

{p 4 4 2}
{opt pid(string)}: specifies the individual ID variable.
Default under setting(GMD): pid

{p 4 4 2}
{opt industrycat4(varname numeric)}: specifies the industry category variable.
Default under setting(GMD): industrycat4

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed). Please not that the input variable should have 'not working' (i.e. unemployed or out of labor force) as the value = 1, and employed as a different value. 
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{title:Examples}

{p 4 4 2} 
{bf: pea figure16} [aw=weight_p], onewelfare(welfppp) oneline(pline215) year(year) age(age) male(male) hhhead(head) married(married) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(lstatus) empstat(empstat) relationharm(relationharm) earnage(15)

