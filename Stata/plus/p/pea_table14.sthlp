{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table14b}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf: pea table14b} — Household typologies.

{title:Syntax}

{p 4 15}
{opt pea table14b} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
	{opt Welfare(varname numeric)} 
	{opt Povlines(varlist numeric)}
	{opt PPPyear(integer)}
	{opt Year(varname numeric)} 
	{opt excel(string)} 
	{opt save(string)}
	{opt age(varname numeric)} 
	{opt male(varname numeric)} 
	{opt hhhead(varname numeric)} 
	{opt hhsize(varname numeric)} 
	{opt hhid(string)} 
	{opt pid(string)} 
	{opt lstatus(varname numeric)} 
	{opt empstat(varname numeric)}
	{opt earnage(integer)}
	{opt MISSING}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table14b} calculates the share of poor and nonpoor by demographic and economic typologies:

{title:Options}

{p 4 4 2} 
{opt Welfare(varname numeric)}:
 specifies the welfare variable to be used for poverty calculations.
 
{p 4 4 2}  
{opt Povlines(varlist numeric)}:
 provides a list of poverty lines adjusted for PPP.
 
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.

 {p 4 4 2}
{opt earnage(integer)}: specifies the age cut-off for working status for the economic composition. Working status depends both on labor force status (lstatus) and employment status (empstat). Individuals will only be considered working if as old or older than the cut-off.
Default: 16

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for the Excel output. If omitted, a temporary file is created.
  
{p 4 4 2} 
{opt save(string)}:
 provides a file path to save intermediate data.

{p 4 4 2}
{opt MISSING}: Optional. Includes missing data in the analysis.

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
{opt hhsize(varname numeric)}: specifies the household size variable.
Default under setting(GMD): hsize

{p 4 4 2}
{opt hhid(string)}: specifies the household ID variable.
Default under setting(GMD): hhid

{p 4 4 2}
{opt pid(string)}: specifies the individual ID variable.
Default under setting(GMD): pid

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed). Please not that the input variable should have 'not working' (i.e. unemployed or out of labor force) as the value = 1, and employed as a different value. 
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{title:Example}

{p 4 4 2}
{bf:pea table14} [aw=weight_p], welfare(welfppp) povlines(pline685) year(year) missing age(age) male(male) hhhead(head) hhsize(hsize) hhid(hhid) pid(pid) lstatus(nowork) empstat(empstat) earnage(18)