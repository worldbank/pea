{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table5}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf: pea table5} — Key labor market indicators.

{title:Syntax}

{p 4 15}
{opt pea table5} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
	{opt Welfare(varname numeric)} 
	{opt PPPyear(integer)}
	{opt Povlines(varlist numeric)}
	{opt Year(varname numeric)} 
	{opt excel(string)} 
	{opt save(string)}
	{opt age(varname numeric)} 
	{opt male(varname numeric)} 
	{opt edu(varname numeric)} 
	{opt urban(varname numeric)} 
	{opt industrycat4(varname numeric)} 
	{opt lstatus(varname numeric)} 
	{opt empstat(varname numeric)}
	{opt MISSING}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table5} calculates key labor market indicators by population subgroups (total, urban/rural, age, sex, welfare quintile).

{title:Options}

{p 4 4 2} 
{opt Welfare(varname numeric)}:
 specifies the welfare variable to be used to calculate welfare quintiles.
 
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.
 
{p 4 4 2}  
{opt Povlines(varlist numeric)}:
 provides a list of poverty lines adjusted for PPP. Only one should be entered for this table.
 
{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for the Excel output. If omitted, a temporary file is created.
  
{p 4 4 2} 
{opt save(string)}:
 provides a file path to save intermediate data.

{p 4 4 2}
{opt MISSING}: Optional. Includes missing data in the analysis. 
Note: If not specified, missing observations for each labor market indicator are not shown.

{p 4 4 2}
{opt age(varname numeric)}: specifies the age variable for the analysis.
Default under setting(GMD): age

{p 4 4 2}
{opt male(varname numeric)}: specifies the gender variable (e.g., male/female).
Default under setting(GMD): male

{p 4 4 2}
{opt urban(varname numeric)}: specifies the urban/rural classification variable.
Default under setting(GMD): urban

{p 4 4 2}
{opt edu(varname numeric)}: specifies the education level variable.
Default under setting(GMD): educat4    

{p 4 4 2}
{opt industrycat4(varname numeric)}: specifies the industry category variable.
Default under setting(GMD): industrycat4

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed). Please not that the input variable should have 'not working' (i.e. unemployed or out of labor force) as the value = 1, and employed as a different value. 
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{title:Example}

{p 4 4 2}
{bf:pea table5} [aw=weight_p], welfare(welfppp) year(year) povlines(pline685) age(age) male(male) urban(urban) edu(educat4) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) missing	
