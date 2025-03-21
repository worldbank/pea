{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea table14a}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf: pea table14a} — Profiles of the poor.

{title:Syntax}

{p 4 15}
{opt pea table14a} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
	{opt Welfare(varname numeric)} 
	{opt Povlines(varlist numeric)}
	{opt PPPyear(integer)}
	{opt Year(varname numeric)} 
	{opt setting(string)}
	{opt excel(string)} 
	{opt save(string)}
	{opt age(varname numeric)} 
	{opt male(varname numeric)} 
	{opt hhhead(varname numeric)} 
	{opt edu(varname numeric)} 
	{opt urban(varname numeric)} 
	{opt married(varname numeric)} 
	{opt school(varname numeric)} 
	{opt services(varlist numeric)} 
	{opt assets(varlist numeric)} 
	{opt hhsize(varname numeric)} 
	{opt hhid(string)} 
	{opt pid(string)} 
	{opt industrycat4(varname numeric)} 
	{opt lstatus(varname numeric)} 
	{opt empstat(varname numeric)}
	{opt MISSING}]{p_end}

{title:Description}

{p 4 4 2}
{opt pea table14} calculates profiles of the poor:

{p 4 4 2}
- Demographics of poor and nonpoor (urban share; age, gender, marital status, education of household head; share of children attending school; household size; share of children and elderly in household; household dependency ratio)

{p 4 4 2}
- Access to piped water, improved sanitation, electricity

{p 4 4 2}
- Asset ownership (vehicle, TV, mobile phone, internet, computer, refrigerator)

{p 4 4 2}
- Employment status of household head

{p 4 4 2}
- Economic sector of household head

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
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options 
(hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified. 

{p 4 4 2} 
{opt excel(string)}:
 specifies the file path for the Excel output. If omitted, a temporary file is created.
  
{p 4 4 2} 
{opt save(string)}:
 provides a file path to save intermediate data.

{p 4 4 2}
{opt MISSING}: Optional. Includes missing data in the analysis.

Additional options if setting(GMD) is not specified:

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
{opt school(varname numeric)}: specifies the schooling variable.
Default under setting(GMD): school

{p 4 4 2}
{opt services(varlist numeric)}: specifies a list of household service variables (e.g., water access, sanitation).
Default under setting(GMD): imp_wat_rec imp_san_rec electricity

{p 4 4 2}
{opt assets(varlist numeric)}: specifies a list of household asset variables (e.g., TV, car, cellphone).
Default under setting(GMD): tv car cellphone computer fridge

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
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed).
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{title:Example}

{p 4 4 2}
{bf:pea table14a} [aw=weight_p], welfare(welfppp) povlines(pline685) year(year) missing age(age) male(male) edu(educat4) hhhead(head)  urban(urban) married(married)
school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat)

