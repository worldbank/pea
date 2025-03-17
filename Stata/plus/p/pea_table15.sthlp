{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table15}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf: pea table15} — Population by welfare decile

{title:Syntax}

{p 4 15}
{opt pea table15} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
	{opt Year(varname numeric)} 
	{opt Welfare(varname numeric)} 
	{opt PPPyear(integer)}
	{opt excel(string)} 
	{opt save(string)}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table15} calculates population shares in each welfare decile.

{title:Options}
 
{p 4 4 2} 
{opt Year(varname numeric)}:
 specifies the year variable for the analysis.
 
{p 4 4 2} 
{opt Welfare(varname numeric)}:
 specifies the welfare variable to be used for poverty calculations.
 
 {p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for the Excel output. If omitted, a temporary file is created.
  
{p 4 4 2} 
{opt save(string)}:
 provides a file path to save intermediate data.

{title:Example}

{p 4 4 2}
{bf:pea table15} [aw=weight_p], welfare(welfppp) year(year)


